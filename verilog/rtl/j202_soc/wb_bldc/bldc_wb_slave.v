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
// Company     : SH Consulting
//
// Filename    : bldc_wb_slave.v
// Description : Wishbone slave
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module bldc_wb_slave
    (
    clk,
    rst_n,
    //---------------------------------
    //Wishbone interface
    sel_i,
    dat_i,
    addr_i,
    cyc_i,
    we_i,
    stb_i,
    ack_o,
    dat_o,
    //---------------------------------
    //BLDC register interface
    reg_wdata_o,
    reg_wen_o,
    reg_ren_o,
    reg_addr_o,
    reg_rdata_i
    );

////////////////////////////////////////////////////////////////////////////////
//parameter
parameter WB_AW   = 6'd32;
parameter WB_DW   = 6'd32;
parameter REG_AW  = 6'd32;
parameter REG_DW  = 6'd32;

parameter IDLE    = 2'd0;
parameter READ    = 2'd1;
parameter WRITE   = 2'd2;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                 clk;
input                 rst_n;
//---------------------------------
//Wishbone interface
input [3:0]           sel_i;
input [WB_DW-1:0]     dat_i;
input [WB_AW-1:0]     addr_i;
input                 cyc_i;
input                 we_i;
input                 stb_i;
output                ack_o;
output [WB_DW-1:0]    dat_o;
//---------------------------------
//BLDC register interface
output [REG_DW-1:0]   reg_wdata_o;
output                reg_wen_o;
output                reg_ren_o;
output [REG_AW-1:0]   reg_addr_o;
input [REG_DW-1:0]    reg_rdata_i;
////////////////////////////////////////////////////////////////////////////////
//internal signal
reg [WB_DW-1:0]       reg_wdata_o;

wire                  idle_to_write;
wire                  idle_to_read;
reg [REG_AW-1:0]      addr_1;
wire                  st_idle;
wire                  st_write;
wire                  st_read;

reg  [1:0]            nxt_state;
reg  [1:0]            state;   

//------------------------------------------------------------------------------
// AHB next state logic

assign idle_to_write = we_i & stb_i & cyc_i & st_idle;
assign idle_to_read = (~we_i) & stb_i & cyc_i & st_idle;

always @ (*)
    begin
    case (state)
    	IDLE :
            begin
    	    nxt_state = idle_to_write ? WRITE : 
                        idle_to_read ? READ : IDLE;
    	    end	
    	WRITE :
    	    begin
    	    nxt_state = IDLE;
    	    end	
    	READ :
    	    begin
    	    nxt_state = IDLE; 
    	    end	
    	default :
    	    begin
    	    nxt_state = IDLE;
    	    end	
    endcase
    end
//------------------------------------------------------------------------------
// FF
always @ (posedge clk or negedge rst_n)
    begin
    if(!rst_n)
        state <= IDLE;
    else
        state <= nxt_state;
    end

assign st_idle = (state == IDLE);
assign st_write = (state == WRITE);
assign st_read = (state == READ);
//------------------------------------------------------------------------------
//wdata
always @ (posedge clk or negedge rst_n)
    begin
    if(!rst_n)
        reg_wdata_o <= {WB_DW{1'b0}};
    else
        reg_wdata_o <= dat_i;
    end
//------------------------------------------------------------------------------
//address
always @ (posedge clk or negedge rst_n)
    begin
    if(!rst_n)
        addr_1 <= {REG_AW{1'b0}};
    else
        addr_1 <= addr_i[REG_AW-1:0];
    end

assign reg_addr_o = idle_to_read ? addr_i[REG_AW-1:0] : addr_1;

//------------------------------------------------------------------------------
//Write control
assign reg_wen_o = st_write;
//------------------------------------------------------------------------------
//read control
assign reg_ren_o = idle_to_read;
//------------------------------------------------------------------------------
//ACK control
assign ack_o = (st_write | st_read) & stb_i;
//------------------------------------------------------------------------------
//Data out
assign dat_o = reg_rdata_i;

endmodule 

