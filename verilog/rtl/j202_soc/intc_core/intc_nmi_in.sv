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
// Filename    : intc_nmi_in.sv
// Description : NMI Interrupt capture module.
//
// Author      : Duong Nguyen
// Created On  : August 9, 2017
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module intc_nmi_in
    (
    clk,
    rst,//synchronous reset, active-high
    //---------------------------------
    //NMI
    intreq_nmi_i,//NMI input request
    in_intreq_nmi_o,//NMI output request
    cp_intack_nmi_i// NMI ACK from CPU
    );

//------------------------------------------------------------------------------
//parameter
//------------------------------------------------------------------------------
parameter     CPU_NUM = 4;

//------------------------------------------------------------------------------
// Port declarations
//------------------------------------------------------------------------------
input logic                clk;
input logic                rst;
//---------------------------------
//NMI
input logic [CPU_NUM-1:0]  intreq_nmi_i;
output logic [CPU_NUM-1:0] in_intreq_nmi_o;
input logic                cp_intack_nmi_i;

//------------------------------------------------------------------------------
//internal signal
//------------------------------------------------------------------------------
logic [CPU_NUM-1:0]        nxt_intreq_nmi_1;
logic [CPU_NUM-1:0]        intreq_nmi_1;
logic [CPU_NUM-1:0]        nxt_intreq_nmi_2;
logic [CPU_NUM-1:0]        intreq_nmi_2;
logic [CPU_NUM-1:0]        nmi_pulse;

//------------------------------------------------------------------------------
//NMI interrupt capturing
//------------------------------------------------------------------------------
assign nxt_intreq_nmi_1 = intreq_nmi_i;
//FF
dff_rst  #(CPU_NUM)  dff_nmi_1  (clk,rst,nxt_intreq_nmi_1,intreq_nmi_1);
assign nmi_pulse = (~intreq_nmi_1) & nxt_intreq_nmi_1;
assign nxt_intreq_nmi_2 = ((~cp_intack_nmi_i) & intreq_nmi_2) | nmi_pulse; 
//FF
dff_rst  #(CPU_NUM)  dff_nmi_2  (clk,rst,nxt_intreq_nmi_2,intreq_nmi_2);
assign in_intreq_nmi_o = intreq_nmi_2;


endmodule 

