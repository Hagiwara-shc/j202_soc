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

////////////////////////////////////////////////////////////////////////////////
// Filename    : ahblite_m_port.v
// Description : AHB Lite master port which connects to AHB lite master
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//             : 2022.12.25 K.Hagiwara Simplify
////////////////////////////////////////////////////////////////////////////////

module ahblite_m_port
#(
  parameter AHB_AW  = 32, // Width of address
  parameter AHB_DW  = 32, // Width of data
  parameter SLV_NUM = 8   // NUmber of slaves
) (
  //---------------------------------
  // Clock and Reset
  input logic                              clk,
  input logic                              rst,
  //---------------------------------
  // Address map of slaves
  input  logic [AHB_AW-1:0]                s_addr_mask_i [SLV_NUM],//Slave address masks
  input  logic [AHB_AW-1:0]                s_addr_base_i [SLV_NUM],//Slave base addresses
  //---------------------------------
  // AHB slave port (b/w a master)
  input  logic                             hready_i,
  input  logic [AHB_AW-1:0]                haddr_i,
  input  logic                             hwrite_i,
  input  logic [1:0]                       htrans_i,
  input  logic [2:0]                       hsize_i,
  input  logic [2:0]                       hburst_i,
  input  logic [3:0]                       hprot_i,
  input  logic [AHB_DW-1:0]                hwdata_i,
  input  logic                             hmastlock_i,
  output logic                             hreadyout_o,
  output logic                             hresp_o,
  output logic [AHB_DW-1:0]                hrdata_o,
  //---------------------------------
  // Internal master ports (b/w internal slave ports)
  output logic                             m_hready_o,
  output logic                             m_hsel_o      [SLV_NUM],
  output logic [AHB_AW-1:0]                m_haddr_o,
  output logic                             m_hwrite_o,
  output logic [1:0]                       m_htrans_o,
  output logic [2:0]                       m_hsize_o,
  output logic [2:0]                       m_hburst_o,
  output logic [AHB_DW-1:0]                m_hwdata_o,
  output logic                             m_hmastlock_o,
  output logic [3:0]                       m_hprot_o,
  input  logic                             m_hreadyout_i [SLV_NUM],
  input  logic                             m_hresp_i     [SLV_NUM],
  input  logic [AHB_DW-1:0]                m_hrdata_i    [SLV_NUM]
);

//------------------------------------------------------------------------------
// Internal master port outputs (to internal slave ports)
genvar i;
for (i = 0; i < SLV_NUM; i = i + 1) begin : g_hsel
  assign m_hsel_o[i] = htrans_i[1] & ((haddr_i & s_addr_mask_i[i]) == (s_addr_base_i[i] & s_addr_mask_i[i])); 
end

assign m_hready_o    = hready_i;
assign m_haddr_o     = haddr_i;
assign m_hwrite_o    = hwrite_i;
assign m_htrans_o    = htrans_i;
assign m_hsize_o     = hsize_i;
assign m_hburst_o    = hburst_i;
assign m_hwdata_o    = hwdata_i;
assign m_hmastlock_o = hmastlock_i;
assign m_hprot_o     = hprot_i;

//------------------------------------------------------------------------------
// Internal slave ports' response select
genvar k;
logic resp_sel [SLV_NUM];
for (k = 0; k < SLV_NUM; k = k + 1) begin
  always @(posedge clk) begin
    if (rst) begin
      resp_sel[k] <= 1'b0;
    end
    else if (m_hready_o) begin
      resp_sel[k] <= m_hsel_o[k];
    end
  end
end

//------------------------------------------------------------------------------
// AHB slave port outputs (to a master)
logic              hreadyout_tmp [SLV_NUM+1];
logic              hresp_tmp [SLV_NUM+1];
logic [AHB_DW-1:0] hrdata_tmp [SLV_NUM+1];

assign hreadyout_tmp[0] = 1'b1;
assign hresp_tmp[0]     = 1'b0;
assign hrdata_tmp[0]    = {AHB_DW{1'b0}};

genvar j;
for (j = 0; j < SLV_NUM; j = j + 1) begin : g_resp
  assign hreadyout_tmp[j+1] = resp_sel[j] ? m_hreadyout_i[j] : hreadyout_tmp[j];
  assign hresp_tmp[j+1]     = resp_sel[j] ? m_hresp_i[j]     : hresp_tmp[j];
  assign hrdata_tmp[j+1]    = resp_sel[j] ? m_hrdata_i[j]    : hrdata_tmp[j];
end

assign hreadyout_o = hreadyout_tmp[SLV_NUM];
assign hresp_o     = hresp_tmp[SLV_NUM];
assign hrdata_o    = hrdata_tmp[SLV_NUM];

endmodule
