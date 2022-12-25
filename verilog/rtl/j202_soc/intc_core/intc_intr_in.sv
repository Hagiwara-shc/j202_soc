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
// Filename    : intc_intr_in.v
// Description : Normal Interrupt capture module.
//
// Author      : Duong Nguyen
// Created On  : August 9, 2017
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module intc_intr_in
    (
    clk,
    rst,//synchronous reset, active-high
    //---------------------------------
    //INT
    intreq_i,//Normal interrupt input.
    //rg_sint_i,//SW interrupt input.
    rg_ie_i,//Normal interrupt enable
    rg_irqc_i,//Normal interrupt clear
    rg_idt_i,//Interrupt detection method
    in_intreq_o,//Normal interrupt request
    cp_intack_i,
    in_irq_o 
    );

//------------------------------------------------------------------------------
//parameter
//------------------------------------------------------------------------------
parameter     INT_DW = 192;

//------------------------------------------------------------------------------
// Port declarations
//------------------------------------------------------------------------------
input logic                  clk;
input logic                  rst;
//---------------------------------
//INT
input logic [INT_DW-1:0]     intreq_i;//[255:64]
input logic [INT_DW-1:0]     rg_ie_i;//[255:64]
input logic [INT_DW-1:0]     rg_irqc_i;
input logic [INT_DW-1:0]     rg_idt_i;
output logic [INT_DW-1:0]    in_intreq_o;
input logic [INT_DW-1:0]     cp_intack_i;
output logic [INT_DW-1:0]    in_irq_o;
//------------------------------------------------------------------------------
//internal signal
//------------------------------------------------------------------------------

logic [INT_DW-1:0]           nxt_normal_int;
logic [INT_DW-1:0]           normal_int;
logic [INT_DW-1:0]           normal_pulse;
logic [INT_DW-1:0]           edge_intreq;
logic [INT_DW-1:0]           nxt_in_intreq;


//------------------------------------------------------------------------------
//Normal interrupt capturing
//------------------------------------------------------------------------------
assign nxt_normal_int = intreq_i;//upto 192 int sources
//ff
dff_rst  #(INT_DW)  dff_normal_int  (clk,rst,nxt_normal_int,normal_int);
assign normal_pulse = (~normal_int) & nxt_normal_int;

assign edge_intreq = ((~cp_intack_i) & (~rg_irqc_i) & in_intreq_o) | normal_pulse;
//Select edge or level detection
assign nxt_in_intreq = ((rg_idt_i & edge_intreq) | ((~rg_idt_i) & nxt_normal_int))
                       & rg_ie_i;
//ff
dff_rst  #(INT_DW)  dff_normal_intreq  (clk,rst,nxt_in_intreq,in_intreq_o);
assign in_irq_o = in_intreq_o;

endmodule 

