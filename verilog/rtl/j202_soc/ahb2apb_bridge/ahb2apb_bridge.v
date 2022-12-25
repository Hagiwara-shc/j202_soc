// SPDX-FileCopyrightText: 2022 SH CONSULTING K.K.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

//////////////////////////////////////////////////////////////////////////////////
// Filename        : ahb2apb_bridge.v
// Description     : AHB to APB bridge (synchronous, 1:1 clock freq. ratio, big-endian)
// Created On      : 2022.12.04
//
//////////////////////////////////////////////////////////////////////////////////
module ahb2apb_bridge
#(
  parameter AHB_AW = 32,  // AHB address width
  parameter AHB_DW = 32,  // AHB data width (only 32 is supported)
  parameter APB_AW = 32,  // APB address width
  parameter APB_DW = 32   // APB data width (only 32 is supported)
) (
  input logic                clk,
  input logic                rst_n,
  //---------------------------------
  //AHB Lite slave interface
  input logic                hready_i,
  input logic                hsel_i,
  input logic [AHB_AW-1:0]   haddr_i,
  input logic                hwrite_i,
  input logic [1:0]          htrans_i,
  input logic [2:0]          hsize_i,
  input logic [2:0]          hburst_i,
  input logic [3:0]          hprot_i,
  input logic [AHB_DW-1:0]   hwdata_i,
  input logic                hmastlock_i,
  output logic               hreadyout_o,
  output logic               hresp_o,
  output logic [AHB_DW-1:0]  hrdata_o,
  //---------------------------------
  //APB master interface
  output logic               psel_o,
  output logic               pwrite_o,
  output logic               penable_o,
  output logic [2:0]         pprot_o,
  output logic [APB_DW/8-1:0]pstrb_o,
  output logic [APB_AW-1:0]  paddr_o,
  output logic [APB_DW-1:0]  pwdata_o,
  input logic  [APB_DW-1:0]  prdata_i,
  input logic                pslverr_i,
  input logic                pready_i
);

//-----------------------------------------------------------------------------
// FSM states
localparam ST_IDLE = 0;
localparam ST_1    = 1;
localparam ST_2    = 2;
localparam ST_ERR1 = 3;
localparam ST_ERR2 = 4;

// HSIZE
localparam HSZ_8  = 3'b000;
localparam HSZ_16 = 3'b001;
localparam HSZ_32 = 3'b010;

//-----------------------------------------------------------------------------
// Internal signals
logic [2:0]         state;
logic [AHB_AW-1:0]  haddr_buf;
logic               hwrite_buf;
logic [1:0]         htrans_buf;
logic [2:0]         hsize_buf;
logic [2:0]         hburst_buf;
logic [3:0]         hprot_buf;
logic               hmastlock_buf;
logic [APB_DW-1:0]  prdata_buf;
logic               pslverr_buf;

//-----------------------------------------------------------------------------
// AHB input signal buffers
always @(posedge clk) begin
  if (~rst_n) begin
    haddr_buf     <= {AHB_AW{1'b0}};
    hwrite_buf    <= 1'b0;
    htrans_buf    <= 2'b00;
    hsize_buf     <= 3'b000;
    hburst_buf    <= 3'b000;
    hprot_buf     <= 4'b0000;
    hmastlock_buf <= 1'b0;
  end
  else if (hready_i & hsel_i) begin
    haddr_buf     <= haddr_i;
    hwrite_buf    <= hwrite_i;
    htrans_buf    <= htrans_i;
    hsize_buf     <= hsize_i;
    hburst_buf    <= hburst_i;
    hprot_buf     <= hprot_i;
    hmastlock_buf <= hmastlock_i;
  end
end

//-----------------------------------------------------------------------------
// FSM
always @(posedge clk) begin
  if (~rst_n) begin
    state <= ST_IDLE;
  end
  else begin
    case (state)
      ST_IDLE:
        if (hready_i & hsel_i & htrans_i[1]) begin
          state <= ST_1;
        end
        else begin
          state <= ST_IDLE;
        end
      ST_1:
        state <= ST_2;
      ST_2:
        if (~pready_i) begin
          state <= ST_2;
        end
        else if (pslverr_i) begin
          state <= ST_ERR1;
        end
        else begin
          state <= ST_IDLE;
        end
      ST_ERR1:
        state <= ST_ERR2;
      ST_ERR2:
        state <= ST_IDLE;
      default:
        state <= ST_IDLE;
    endcase
  end
end

//-----------------------------------------------------------------------------
// APB output signals
assign psel_o    = (state == ST_1) | (state == ST_2);
assign pwrite_o  = hwrite_buf;
assign penable_o = (state == ST_2);
assign pprot_o   = {~hprot_buf[0], 1'b1, hprot_buf[1]};
assign paddr_o   = haddr_buf[APB_AW-1:0];
assign pwdata_o  = hwdata_i;

always @(*) begin
  if (~hwrite_buf) begin
    pstrb_o = 4'b0000;
  end
  else begin
    case (hsize_buf)
      HSZ_32:
        pstrb_o = 4'b1111;
      HSZ_16:
        pstrb_o = haddr_buf[1] ? 4'b1100 : 4'b0011;
      HSZ_8:
        case (haddr_buf[1:0])
          2'b00: pstrb_o = 4'b1000;
          2'b01: pstrb_o = 4'b0100;
          2'b10: pstrb_o = 4'b0010;
          2'b11: pstrb_o = 4'b0001;
        endcase
    endcase
  end
end

//-----------------------------------------------------------------------------
// APB input signal buffer
always @(posedge clk) begin
  if (~rst_n) begin
    prdata_buf <= {APB_DW{1'b0}};
  end
  else if ((state == ST_2) & pready_i) begin
    prdata_buf <= prdata_i;
  end
end

//-----------------------------------------------------------------------------
// AHB output signals
assign hreadyout_o = (state == ST_IDLE) | (state == ST_ERR2);
assign hrdata_o    = prdata_buf;
assign hresp_o     = (state == ST_ERR1) | (state == ST_ERR2);

endmodule
