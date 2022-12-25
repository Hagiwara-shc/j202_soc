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
// Filename    : intc_core.sv
// Description : Interrupt core module.
//
// Author      : Duong Nguyen
// Created On  : August 9, 2017
// History     : Initial 	
// History     : 05-19-2018 K.Hagiwara: Change pport_i[3:0] -> [2:0]
//
////////////////////////////////////////////////////////////////////////////////

module intc_core
    (
    clk_cpu,
    clk_bus,
    clk_int,
    rst,//synchronous reset, active-high
    sync_cpu_int_i,
    sync_bus_int_i,
    //---------------------------------
    //Interrupt inputs
    intreq_nmi_i,
    intreq_err_i,
    intreq_i,//[255:80]
    //---------------------------------
    //CPU interfaces
    intr_req_o,
    intr_level_o,
    intr_vec_o,
    inta_ack_i,
    //---------------------------------
    //APB interface
    psel_i,
    pwrite_i,
    penable_i,
    paddr_i,
    pwdata_i,
    pstrb_i,
    pprot_i,
    prdata_o,
    pslverr_o,
    pready_o
    );

//------------------------------------------------------------------------------
//parameter
//------------------------------------------------------------------------------
parameter CPU_NUM = 1;
parameter REG_NUM = 1; //REG_NUM*32 is number of normal interrupt.
parameter SW_INT_NUM = 16; //Number of sw interrupts
parameter PERI_INT_NUM = REG_NUM*32 - SW_INT_NUM;//Peripheral interrupts 

//------------------------------------------------------------------------------
// Port declarations
//------------------------------------------------------------------------------
input logic                                clk_cpu;
input logic                                clk_bus;
input logic                                clk_int;
input logic                                rst;
input logic                                sync_cpu_int_i;
input logic                                sync_bus_int_i;
//---------------------------------
//Interrupt inputs
input logic [CPU_NUM-1:0]                  intreq_nmi_i;
input logic [CPU_NUM-1:0][7:0]             intreq_err_i;
input logic [PERI_INT_NUM-1:0]             intreq_i;//[255:80]
//---------------------------------
//CPU interfaces
output logic [CPU_NUM-1:0]                 intr_req_o;
output logic [CPU_NUM-1:0][4:0]            intr_level_o;
output logic [CPU_NUM-1:0][7:0]            intr_vec_o;
input  logic [CPU_NUM-1:0]                 inta_ack_i;
//---------------------------------
//APB interfaces
input logic                                psel_i;
input logic                                pwrite_i;
input logic                                penable_i;
input logic [31:0]                         paddr_i;
input logic [31:0]                         pwdata_i;
input logic [2:0]                          pprot_i;
input logic [3:0]                          pstrb_i;
output logic [31:0]                        prdata_o;
output logic                               pslverr_o;
output logic                               pready_o;
//------------------------------------------------------------------------------
//internal signal
logic                                      bs_sel;
logic                                      bs_wr;
logic [31:0]                               bs_addr;
logic [31:0]                               bs_wdata;
logic [31:0]                               bs_rdata;

logic [SW_INT_NUM-1:0]                     rg_sint;
logic [CPU_NUM-1:0][7:0]                   rg_eimk;
logic [CPU_NUM-1:0][7:0]                   rg_eirqc;
logic [CPU_NUM-1:0][7:0]                   in_eirq;

logic [REG_NUM-1:0][31:0]                  rg_ie;
logic [REG_NUM-1:0][31:0]                  rg_irqc;
logic [REG_NUM-1:0][31:0]                  rg_idt;
logic [REG_NUM-1:0][31:0]                  rg_idt_const;//Const from top module
logic  [REG_NUM-1:0][31:0]                 rg_irq;

logic [REG_NUM*32-1:0][3:0]                rg_ipr;
logic [3:0][REG_NUM*32-1:0]                rg_itgt;

logic [CPU_NUM-1:0]                        cp_intack_nmi;
logic [CPU_NUM-1:0][7:0]                   intreq_err;
logic [CPU_NUM-1:0]                        cp_intack_err;

logic [REG_NUM*32-1:0]                     cp_intack;

logic  [CPU_NUM-1:0]                       cp_intack_all;
logic [CPU_NUM-1:0]                        sl_req;
logic [CPU_NUM-1:0][4:0]                   sl_level;
logic [CPU_NUM-1:0][7:0]                   sl_vec;
logic  [CPU_NUM-1:0]                       in_intreq_nmi;
logic [CPU_NUM-1:0]                        in_intreq_err;
logic [REG_NUM*32-1:0]                     in_intreq;

//------------------------------------------------------------------------------
//APB bus instance
intc_apb       intc_apb_00
    (
    .clk        (clk_bus),
    .rst        (rst),//synchronous reset, active-high
    //---------------------------------
    //APB bus interface
    .psel_i     (psel_i),
    .pwrite_i   (pwrite_i),
    .penable_i  (penable_i),
    .paddr_i    (paddr_i),
    .pwdata_i   (pwdata_i),
    .pstrb_i    (pstrb_i),
    .pprot_i    (pprot_i),
    .prdata_o   (prdata_o),
    .pslverr_o  (pslverr_o),
    .pready_o   (pready_o),
    //---------------------------------
    //Register interface
    .bs_sel_o   (bs_sel),
    .bs_wr_o    (bs_wr),
    .bs_addr_o  (bs_addr),
    .bs_wdata_o (bs_wdata),
    .rg_rdata_i (bs_rdata)
    );
//------------------------------------------------------------------------------
//INTC registers
intc_regs     #(.CPU_NUM   (CPU_NUM),
                .SW_INT_NUM(SW_INT_NUM),
                .REG_NUM   (REG_NUM))      intc_regs_00
    (
    .clk            (clk_bus),
    .rst            (rst),//synchronous reset, active-high
    .sync_cpu_int_i (sync_bus_int_i),
    //---------------------------------
    //Register interface
    .bs_sel_i       (bs_sel),
    .bs_wr_i        (bs_wr),
    .bs_addr_i      (bs_addr),
    .bs_wdata_i     (bs_wdata),
    .bs_rdata_o     (bs_rdata),
    //---------------------------------
    //configuration and status inf
    .rg_sint_o      (rg_sint),
    .rg_eimk_o      (rg_eimk),
    .rg_eirqc_o     (rg_eirqc),
    .in_eirq_i      (in_eirq),
    //
    .rg_ie_o        (rg_ie),
    .rg_irqc_o      (rg_irqc),
    .rg_idt_o       (rg_idt),
    .rg_idt_i       (rg_idt_const), //Const from top module
    .rg_irq_i       (rg_irq),
    //
    .rg_itgt_o      (rg_itgt),
    .rg_ipr_o       (rg_ipr)
    );

assign rg_idt_const = 32'hFFFF_FFFF;
//------------------------------------------------------------------------------
//INTC Inputs

intc_in      #(.CPU_NUM   (CPU_NUM),
               .REG_NUM   (REG_NUM),
               .SW_INT_NUM(SW_INT_NUM))  intc_in_00
    (
    .clk             (clk_int),
    .rst             (rst),//synchronous reset, active-high
    //---------------------------------
    //NMI
    .intreq_nmi_i    (intreq_nmi_i),//NMI input request
    .in_intreq_nmi_o (in_intreq_nmi),//NMI output request
    .cp_intack_nmi_i (cp_intack_nmi),// NMI ACK from CPU
    //---------------------------------
    //ERR
    .intreq_err_i    (intreq_err_i),//error interrupt request
    .rg_eimk_i       (rg_eimk),//Error interrupt mask
    .rg_eirqc_i      (rg_eirqc),//Error interrupt clear
    .in_intreq_err_o (in_intreq_err),//Error interrupt request to CPU
    .cp_intack_err_i (cp_intack_err),//Error AcK from CPU
    .in_eirq_o       (in_eirq),//Error interrupt output to regiser. 
    //---------------------------------
    //INT
    .intreq_i        (intreq_i),//Normal interrupt input.
    .rg_sint_i       (rg_sint),//SW interrupt input.
    .rg_ie_i         (rg_ie),//Normal interrupt enable
    .rg_irqc_i       (rg_irqc),//Normal interrupt clear
    .rg_idt_i        (rg_idt),//Interrupt detection method
    .in_intreq_o     (in_intreq),//Normal interrupt request
    .cp_intack_i     (cp_intack),
    .in_irq_o        (rg_irq)  
    );
//------------------------------------------------------------------------------
//INTC selection

intc_sel    #(.CPU_NUM(CPU_NUM),
              .REG_NUM(REG_NUM))    intc_sel_00
    (
    .clk             (clk_int),
    .rst             (rst),//synchronous reset, active-high
    .sync_cpu_int_i  (sync_cpu_int_i),
    //---------------------------------
    //CPU IF
    .cp_intack_all_i (cp_intack_all),
    .sl_req_o        (sl_req),
    .sl_level_o      (sl_level),
    .sl_vec_o        (sl_vec),
    //---------------------------------
    //Register interface
    .in_intreq_nmi_i (in_intreq_nmi),
    .in_intreq_err_i (in_intreq_err),
    .in_intreq_i     (in_intreq),
    .rg_itgt_i       (rg_itgt),
    .rg_ipr_i        (rg_ipr)
    );
//------------------------------------------------------------------------------
//INTC CPUIF
intc_cpuif     #(.CPU_NUM(),
                 .REG_NUM())      intc_cpuif_00
    (
    .clk            (clk_cpu),
    .rst            (rst),//synchronous reset, active-high
    .sync_cpu_int_i (sync_cpu_int_i),
    //---------------------------------
    //CPU interfaces
    .intr_req_o     (intr_req_o),
    .intr_level_o   (intr_level_o),
    .intr_vec_o     (intr_vec_o),
    .inta_ack_i     (inta_ack_i),
    
    //---------------------------------
    //INTCSEL interfaces
    .sl_req_i       (sl_req),
    .sl_level_i     (sl_level),
    .sl_vec_i       (sl_vec),
    .cp_intack_nmi_o(cp_intack_nmi),
    .cp_intack_err_o(cp_intack_err),
    .cp_intack_o    (cp_intack),
    .cp_intack_all_o(cp_intack_all)
    );


endmodule 

