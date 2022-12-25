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
// Filename    : intc_err_in.v
// Description : Interrupt capture module.
//
// Author      : Duong Nguyen
// Created On  : August 9, 2017
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module intc_err_in
    (
    clk,
    rst,//synchronous reset, active-high
    //---------------------------------
    //ERR
    intreq_err_i,   //error interrupt request
    rg_eimk_i,      //Error interrupt mask
    rg_eirqc_i,     //Error interrupt clear
    in_intreq_err_o,//Error interrupt request to CPU
    cp_intack_err_i,//Error AcK from CPU
    in_eirq_o       //Error interrupt output to regiser. 
    );

//------------------------------------------------------------------------------
//parameter
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Port declarations
//------------------------------------------------------------------------------
input logic               clk;
input logic               rst;
//---------------------------------
//ERR
input logic      [7:0]    intreq_err_i;
input logic      [7:0]    rg_eimk_i;
input logic      [7:0]    rg_eirqc_i;
output logic              in_intreq_err_o;
input logic               cp_intack_err_i;
output logic     [7:0]    in_eirq_o;
//------------------------------------------------------------------------------
//internal signal
//------------------------------------------------------------------------------
logic [7:0]               nxt_intreq_err_1;
logic [7:0]               intreq_err_1;
logic [7:0]               nxt_intreq_err_2;
logic [7:0]               intreq_err_2;
logic [7:0]               err_pulse;
logic                     nxt_in_err_srv;
logic                     in_err_srv;

//------------------------------------------------------------------------------
//Error interrupt capturing for CPU0
//------------------------------------------------------------------------------
assign nxt_intreq_err_1 = intreq_err_i;
//FF
dff_rst  #(8)  dff_err_1  (clk,rst,nxt_intreq_err_1,intreq_err_1);

assign err_pulse = (~intreq_err_1) & nxt_intreq_err_1;
assign nxt_intreq_err_2 = ((~rg_eirqc_i & intreq_err_2) | err_pulse) & (~rg_eimk_i); 
//ff
dff_rst  #(8)  dff_err_2  (clk,rst,nxt_intreq_err_2,intreq_err_2);
//In error service logic
assign nxt_in_err_srv = ((~|rg_eirqc_i) & in_err_srv) | cp_intack_err_i;
//ff
dff_rst  #(1)  dff_in_err_srv  (clk,rst,nxt_in_err_srv,in_err_srv);

assign in_eirq_o = intreq_err_2;//Out error interrupt to register module
assign in_intreq_err_o = (|intreq_err_2) & (~in_err_srv); 

endmodule 

