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
// Filename    : intc_in.v
// Description : Interrupt capture module.
//
// Author      : Duong Nguyen
// Created On  : August 9, 2017
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module intc_in
    (
    clk,
    rst,//synchronous reset, active-high
    //---------------------------------
    //NMI
    intreq_nmi_i,//NMI input request
    in_intreq_nmi_o,//NMI output request
    cp_intack_nmi_i,// NMI ACK from CPU
    //---------------------------------
    //ERR
    intreq_err_i,//error interrupt request
    rg_eimk_i,//Error interrupt mask
    rg_eirqc_i,//Error interrupt clear
    in_intreq_err_o,//Error interrupt request to CPU
    cp_intack_err_i,//Error AcK from CPU
    in_eirq_o,//Error interrupt output to regiser. 
    //---------------------------------
    //INT
    intreq_i,//Normal interrupt input.
    rg_sint_i,//SW interrupt input.
    rg_ie_i,//Normal interrupt enable
    rg_irqc_i,//Normal interrupt clear
    rg_idt_i,//Interrupt detection method
    in_intreq_o,//Normal interrupt request
    cp_intack_i,
    in_irq_o//output to register module 
    );

//------------------------------------------------------------------------------
//parameter
//------------------------------------------------------------------------------
parameter CPU_NUM = 4;
parameter REG_NUM = 2; //REG_NUM*32 is number of normal interrupt.
parameter SW_INT_NUM = 16;// Number of sw interrupts
parameter PERI_INT_NUM = REG_NUM*32 - SW_INT_NUM;//Peripheral interrupts 

//------------------------------------------------------------------------------
// Port declarations
//------------------------------------------------------------------------------
input logic                       clk;
input logic                       rst;
//---------------------------------
//NMI
input logic [CPU_NUM-1:0]         intreq_nmi_i;
output logic [CPU_NUM-1:0]        in_intreq_nmi_o;
input logic [CPU_NUM-1:0]         cp_intack_nmi_i;
//---------------------------------
//ERR
input logic [CPU_NUM-1:0][7:0]    intreq_err_i;
input logic [CPU_NUM-1:0][7:0]    rg_eimk_i;
input logic [CPU_NUM-1:0][7:0]    rg_eirqc_i;
output logic [CPU_NUM-1:0]        in_intreq_err_o;
input logic [CPU_NUM-1:0]         cp_intack_err_i;
output logic [CPU_NUM-1:0][7:0]   in_eirq_o;
//---------------------------------
//INT
input logic [PERI_INT_NUM-1:0]    intreq_i;//[255:80]
input logic [SW_INT_NUM-1:0]      rg_sint_i;
input logic [REG_NUM*32-1:0]      rg_ie_i;//[255:64]
input logic [REG_NUM*32-1:0]      rg_irqc_i;
input logic [REG_NUM*32-1:0]      rg_idt_i;
output logic [REG_NUM*32-1:0]     in_intreq_o;
input logic [REG_NUM*32-1:0]      cp_intack_i;
output logic [REG_NUM*32-1:0]     in_irq_o;//up to 192
//------------------------------------------------------------------------------
//internal signal
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
//NMI interrupt capturing
//------------------------------------------------------------------------------

intc_nmi_in   #(.CPU_NUM(CPU_NUM))  intc_nmi_in_0
    (
    .clk             (clk),
    .rst             (rst),//synchronous reset, active-high
    //---------------------------------
    //NMI
    .intreq_nmi_i    (intreq_nmi_i),//NMI input request
    .in_intreq_nmi_o (in_intreq_nmi_o),//NMI output request
    .cp_intack_nmi_i (cp_intack_nmi_i)// NMI ACK from CPU
    );

//------------------------------------------------------------------------------
//Error interrupt capturing logic.
//------------------------------------------------------------------------------


genvar k;
generate
    for(k=0; k<CPU_NUM; k=k+1)
        begin : intc_err_inst
        //
        intc_err_in        intc_err_in_inst
            (
            .clk             (clk),
            .rst             (rst),//synchronous reset, active-high
            //---------------------------------
            //ERR
            .intreq_err_i    (intreq_err_i[k]),//error interrupt request
            .rg_eimk_i       (rg_eimk_i[k]),//Error interrupt mask
            .rg_eirqc_i      (rg_eirqc_i[k]),//Error interrupt clear
            .in_intreq_err_o (in_intreq_err_o[k]),//Error interrupt request to CPU
            .cp_intack_err_i (cp_intack_err_i[k]),//Error AcK from CPU
            .in_eirq_o       (in_eirq_o[k]) //Error interrupt output to regiser. 
            );
        end
endgenerate

//------------------------------------------------------------------------------
//Normal interrupt capturing
//------------------------------------------------------------------------------

intc_intr_in   #(.INT_DW(REG_NUM*32))  intc_intr_in_0
    (
    .clk         (clk),
    .rst         (rst),//synchronous reset, active-high
    //---------------------------------
    //INT
    .intreq_i    ({intreq_i,rg_sint_i}),//Normal interrupt input.
    .rg_ie_i     (rg_ie_i),//Normal interrupt enable
    .rg_irqc_i   (rg_irqc_i),//Normal interrupt clear
    .rg_idt_i    (rg_idt_i),//Interrupt detection method
    .in_intreq_o (in_intreq_o),//Normal interrupt request
    .cp_intack_i (cp_intack_i),
    .in_irq_o    (in_irq_o)
    );



endmodule 

