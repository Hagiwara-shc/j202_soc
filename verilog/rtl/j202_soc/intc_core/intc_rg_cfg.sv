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
// Filename    : intc_rg_cfg.sv
// Description : interrupt enable register
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module intc_rg_cfg
    (
    clk,
    rst,//synchronous reset, active-high
    //---------------------------------
    //Input
    we_i,
    bs_wdata_i, 
    //---------------------------------
    //output
    rg_o
    );

////////////////////////////////////////////////////////////////////////////////
//parameter
parameter DW = 32;
parameter RST_VL = {DW{1'b0}};

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input logic               clk;
input logic               rst;
//---------------------------------
//Input
input logic               we_i;
input logic [DW-1:0]      bs_wdata_i;
//---------------------------------
//output
output logic [DW-1:0]     rg_o;
//------------------------------------------------------------------------------
//internal signal
logic [DW-1:0]            nxt_rg;
logic [DW-1:0]            rg;

//------------------------------------------------------------------------------
//Write logic
//------------------------------------------------------------------------------
assign nxt_rg = we_i ? bs_wdata_i : rg;
//FF
dff_rst  #(DW,RST_VL)   dff_irqen (clk,rst,nxt_rg,rg);

assign rg_o = rg;
endmodule 

