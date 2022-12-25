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
// Filename    : cmt_apb.v
// Description : APB slave
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module cmt_apb
    (
    clk,
    rst_n,
    //---------------------------------
    //APB bus interface
    psel_i,
    pwrite_i,
    penable_i,
    paddr_i,
    pwdata_i,
    prdata_o,
    pslverr_o,
    pready_o,
    //---------------------------------
    // Register file interface
    reg_wen_o,
    reg_wdata_o,
    reg_addr_o,
    reg_ren_o,
    reg_rdata_i
    );

////////////////////////////////////////////////////////////////////////////////
//parameter
parameter AW      = 4'd8;
parameter DW      = 6'd32;
parameter IDLE    = 2'b00;
parameter SETUP   = 2'b01;
parameter ENABLE  = 2'b10;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input               clk;
input               rst_n;
// APB bus interface
input               psel_i;
input               pwrite_i;
input               penable_i;
input  [AW-1:0]	    paddr_i;
input [DW-1:0]	    pwdata_i;
output [DW-1:0]	    prdata_o;
output              pslverr_o;
output              pready_o;

//---------------------------------
// Register file interface
output              reg_wen_o;
output [DW-1:0]     reg_wdata_o;
output [AW-1:0]     reg_addr_o;
output              reg_ren_o;
input [DW-1:0]      reg_rdata_i;
////////////////////////////////////////////////////////////////////////////////
//internal signal
reg [AW-1:0]        reg_addr_o;

wire                setup_det;
wire                enable_det;
reg [1:0]	    state;
reg [1:0]           nxt_state;
wire                st_enable;
wire                st_setup;
wire                reg_wen;
reg                 reg_wen_1;
reg                 reg_wen_2;
wire                reg_ren;
reg [DW-1:0]        pwdata_1;
////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation

//------------------------------------------------------------------------------
// APB next state logic

//Setup detect
assign setup_det = psel_i & (~penable_i);
//Enable detect
assign enable_det = psel_i & penable_i;
//Register file address decode 
assign reg_wen = setup_det & pwrite_i;
assign reg_ren = setup_det & (~pwrite_i);
//APB state machine
always @ (*)
    begin
    case (state)
    	IDLE :
            begin
    	    nxt_state = setup_det ? SETUP : IDLE;
    	    end	
    	SETUP :
    	    begin
    	    nxt_state = enable_det ? ENABLE : SETUP;
    	    end	
    	ENABLE :
    	    begin
    	    nxt_state = setup_det ? SETUP : IDLE;
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

assign st_enable = (state == ENABLE);
assign st_setup = (state == SETUP);

always @ (posedge clk or negedge rst_n)
    begin
    if(!rst_n)
        pwdata_1 <= {DW{1'b0}};
    else
        pwdata_1 <= pwdata_i;
    end
always @ (posedge clk or negedge rst_n)
    begin
    if(!rst_n)
        reg_wen_1 <= 1'b0;
    else
        reg_wen_1 <= reg_wen;
    end
always @ (posedge clk or negedge rst_n)
    begin
    if(!rst_n)
        reg_wen_2 <= 1'b0;
    else
        reg_wen_2 <= reg_wen_1;
    end
always @ (posedge clk or negedge rst_n)
    begin
    if(!rst_n)
        reg_addr_o <= {AW{1'b0}};
    else
        reg_addr_o <= paddr_i;
    end

//Write to registers
assign reg_wen_o = st_enable & reg_wen_2; 
assign reg_wdata_o = pwdata_1;
//Read from register
assign reg_ren_o = reg_ren;
//Mux reading data
assign prdata_o = reg_rdata_i;
assign pslverr_o = 1'b0;
assign pready_o = st_setup;

endmodule 

