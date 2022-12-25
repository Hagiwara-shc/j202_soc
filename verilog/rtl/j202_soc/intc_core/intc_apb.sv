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
// Filename    : intc_apb.v
// Description : APB slave state machine
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//             : 05-19-2018 K.Hagiwara: Change pprot_i[3:0] -> [2:0]
//
////////////////////////////////////////////////////////////////////////////////

module intc_apb
    (
    clk,
    rst,//synchronous reset, active-high
    //---------------------------------
    //APB bus interface
    psel_i,
    pwrite_i,
    penable_i,
    paddr_i,
    pwdata_i,
    pstrb_i,
    pprot_i,
    prdata_o,
    pslverr_o,
    pready_o,
    //---------------------------------
    //Register interface
    bs_sel_o,
    bs_wr_o,
    bs_addr_o,
    bs_wdata_o,
    rg_rdata_i
    );

////////////////////////////////////////////////////////////////////////////////
//parameter
parameter AW  = 6'd32;
parameter DW  = 6'd32;


////////////////////////////////////////////////////////////////////////////////
// Port declarations
input logic               clk;
input logic               rst;
//---------------------------------
//APB interfaces
input logic               psel_i;
input logic               pwrite_i;
input logic               penable_i;
input logic [AW-1:0]      paddr_i;
input logic [DW-1:0]      pwdata_i;
input logic [2:0]         pprot_i;
input logic [3:0]         pstrb_i;
output logic [DW-1:0]     prdata_o;
output logic              pslverr_o;
output logic              pready_o;


//---------------------------------
//Register interface
output logic              bs_sel_o;
output logic              bs_wr_o;
output logic [31:0]       bs_addr_o;
output logic [31:0]       bs_wdata_o;
input logic [31:0]        rg_rdata_i;
//------------------------------------------------------------------------------
//internal signal
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
//Command decoding
//------------------------------------------------------------------------------
assign bs_wr_o = pwrite_i & (pstrb_i == 4'b1111);
assign bs_sel_o = penable_i & psel_i & ((~pwrite_i) | bs_wr_o);
//------------------------------------------------------------------------------
assign pready_o = 1'b1;
assign pslverr_o = 1'b0;
assign prdata_o = rg_rdata_i;
assign bs_addr_o = paddr_i;
assign bs_wdata_o = pwdata_i;


endmodule 
