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
// Filename    : intc_regs.v
// Description : INTC registers
//
// Author      : Duong Nguyen
// Created On  : August 8, 2017
// History     : Initial 	
//             : 05-21-2018 K.Hagiwara, Correct initial value of ITGTRn
//
////////////////////////////////////////////////////////////////////////////////

module intc_regs
    (
    clk,
    rst,//synchronous reset, active-high
    sync_cpu_int_i,
    //---------------------------------
    //Register interface
    bs_sel_i,
    bs_wr_i,
    bs_addr_i,
    bs_wdata_i,
    bs_rdata_o,
    //---------------------------------
    //configuration and status inf
    rg_sint_o,
    rg_eimk_o,
    rg_eirqc_o,
    in_eirq_i,
    //
    rg_ie_o,
    rg_irqc_o,
    rg_idt_o,
    rg_idt_i, //Const from top module
    rg_irq_i,
    //
    rg_itgt_o,
    rg_ipr_o
    );

////////////////////////////////////////////////////////////////////////////////
//parameter
parameter CPU_NUM = 4;
parameter SW_INT_NUM = 16;//Up to 16 SW interrupt requests.
parameter REG_NUM = 1;


//------------------------------------------------------------------------------
// Port declarations
//------------------------------------------------------------------------------
input                               clk;
input                               rst;
input                               sync_cpu_int_i;
//---------------------------------
//Register interface
input logic                         bs_sel_i;
input logic                         bs_wr_i;
input logic [31:0]                  bs_addr_i;
input logic [31:0]                  bs_wdata_i;
output logic [31:0]                 bs_rdata_o;
//---------------------------------
//configuration and status inf
output logic [SW_INT_NUM-1:0]       rg_sint_o;
output logic [CPU_NUM-1:0][7:0]     rg_eimk_o;
output logic [CPU_NUM-1:0][7:0]     rg_eirqc_o;
input logic [CPU_NUM-1:0][7:0]      in_eirq_i;
//
output logic [REG_NUM-1:0][31:0]    rg_ie_o;
output logic [REG_NUM-1:0][31:0]    rg_irqc_o;
output logic [REG_NUM-1:0][31:0]    rg_idt_o;
input logic [REG_NUM-1:0][31:0]     rg_idt_i;//Const from top module
input logic  [REG_NUM-1:0][31:0]    rg_irq_i;
//
output logic [REG_NUM*32-1:0][3:0]  rg_ipr_o;
output logic [3:0][REG_NUM*32-1:0]  rg_itgt_o;
//------------------------------------------------------------------------------
//internal signal
//------------------------------------------------------------------------------
logic [CPU_NUM-1:0][7:0]            eirq;
logic [7:0]                         mux_eirq;
logic [CPU_NUM-1:0]                 sel_eirq;
logic                               en_eirq;

logic                               en_eirqc;
logic [CPU_NUM-1:0]                 sel_eirqc;
logic [CPU_NUM-1:0]                 we_eirqc;

logic                               en_eirqmk;
logic [CPU_NUM-1:0]                 sel_eirqmk;
logic [CPU_NUM-1:0]                 we_eirqmk;
logic [7:0]                         mux_eirqmk;

logic                               en_0x04_sint;
logic                               en_0x05_sint;
logic                               en_0x06_sint;
logic                               en_0x07_sint;
logic [SW_INT_NUM-1:0]              sel_sint;
logic [SW_INT_NUM-1:0]              we_sint;

logic                               en_0x10_irqen;
logic                               en_0x11_irqen;
logic [REG_NUM-1:0]                 sel_irqen;
logic [REG_NUM-1:0]                 we_irqen;
logic [31:0]                        mux_irqen;

logic                               en_0x14_irq;
logic                               en_0x15_irq;
logic [REG_NUM-1:0]                 sel_irq;
logic [REG_NUM-1:0][31:0]           irq;
logic [31:0]                        mux_irq;

logic                               en_0x18_irqc;
logic                               en_0x19_irqc;
logic [REG_NUM-1:0]                 sel_irqc;
logic [REG_NUM-1:0]                 we_irqc;

logic                               en_0x1c_irqdt;
logic                               en_0x1d_irqdt;
logic [REG_NUM-1:0]                 sel_irqdt;
logic [31:0]                        mux_idt;

logic                               en_0x20_ipr;
logic                               en_0x21_ipr;
logic                               en_0x22_ipr;
logic                               en_0x23_ipr;
logic                               en_0x24_ipr;
logic                               en_0x25_ipr;
logic [REG_NUM*4-1:0]               sel_ipr;
logic [REG_NUM*4-1:0]               we_ipr;
logic [REG_NUM*4-1:0][31:0]         ipr;
logic [31:0]                        mux_ipr;

logic                               en_0x30_itgt;
logic                               en_0x31_itgt;
logic                               en_0x32_itgt;
logic                               en_0x33_itgt;
logic                               en_0x34_itgt;
logic                               en_0x35_itgt;
logic [REG_NUM*4-1:0]               sel_itgt;
logic [REG_NUM*4-1:0]               we_itgt;
logic [REG_NUM*4-1:0][31:0]         itgt;
logic [31:0]                        mux_itgt;


//------------------------------------------------------------------------------
//1. Error interrupt request register (EIRQRn)
//------------------------------------------------------------------------------
// addr : 0x000 - 0x00C
// access : R
// fields : [31:8] : reserved 
//          [7:0]   : error interrupt request.
assign en_eirq = (bs_addr_i[11:4] == 8'h00) & bs_sel_i;

genvar k;
generate
    for(k=0; k<CPU_NUM; k=k+1)
        begin : eirq_label
        assign eirq[k] = in_eirq_i[k];
        case (k)
            0 :
                assign sel_eirq[k] = (bs_addr_i[3:0] == 4'h0) & en_eirq;
            1 :
                assign sel_eirq[k] = (bs_addr_i[3:0] == 4'h4) & en_eirq;
            2 :
                assign sel_eirq[k] = (bs_addr_i[3:0] == 4'h8) & en_eirq;
            3 :
                assign sel_eirq[k] = (bs_addr_i[3:0] == 4'hC) & en_eirq;
            default :
                assign sel_eirq[k] = (bs_addr_i[3:0] == 4'h0) & en_eirq;
        endcase
        end
endgenerate

//EIRQ 
genvar k11;
generate
  for (k11 = CPU_NUM; k11 <= CPU_NUM; k11 = k11 + 1)
    begin : mux_eirq_label
    if (k11 == 1)
        assign mux_eirq = {8{sel_eirq[0]}} & eirq[0];
    else if (k11 == 2)
        assign mux_eirq = ({8{sel_eirq[0]}} & eirq[0]) | 
                          ({8{sel_eirq[1]}} & eirq[1]);
    else if (k11 == 3)
        mux3  #(.DW(8))  mux3_eirq
            (
            .in0(eirq[0]), .sel0(sel_eirq[0]),
            .in1(eirq[1]), .sel1(sel_eirq[1]),
            .in2(eirq[2]), .sel2(sel_eirq[2]),
            .out (mux_eirq)
            );
    else if (k11 == 4)
        mux4  #(.DW(8))  mux4_eirq
            (
            .in0(eirq[0]), .sel0(sel_eirq[0]),
            .in1(eirq[1]), .sel1(sel_eirq[1]),
            .in2(eirq[2]), .sel2(sel_eirq[2]),
            .in3(eirq[3]), .sel3(sel_eirq[3]),
            .out (mux_eirq)
            );
    end
endgenerate


//------------------------------------------------------------------------------
//2. Error interrupt request clear register n (EIRQCRn)
//------------------------------------------------------------------------------
// addr : 0x010 - 0x01C
// access : R/W
// fields : [31:8] : reserved 
//          [7:0]   : error interrupt request clear.
assign en_eirqc     = (bs_addr_i[11:4] == 8'h01) & bs_sel_i;

genvar k2;
generate
    for(k2=0; k2<CPU_NUM; k2=k2+1)
        begin : eirqc_label
        case (k2)
            0 :
                assign sel_eirqc[k2] = (bs_addr_i[3:0] == 4'h0) & en_eirqc;
            1 :
                assign sel_eirqc[k2] = (bs_addr_i[3:0] == 4'h4) & en_eirqc;
            2 :
                assign sel_eirqc[k2] = (bs_addr_i[3:0] == 4'h8) & en_eirqc;
            3 :
                assign sel_eirqc[k2] = (bs_addr_i[3:0] == 4'hC) & en_eirqc;
            default :
                assign sel_eirqc[k2] = (bs_addr_i[3:0] == 4'h0) & en_eirqc;
        endcase
              
        assign we_eirqc[k2] = sel_eirqc[k2] & bs_wr_i; 
        //
        intc_rg_clr #(.DW(8),
                      .RST_VL(8'd0)) rg_eirqc_inst 
            (
            .clk            (clk),
            .rst            (rst),
            .we_i           (we_eirqc[k2]),
            .bs_wdata_i     (bs_wdata_i[7:0]),
            .sync_cpu_int_i (sync_cpu_int_i),
            .rg_o           (rg_eirqc_o[k2])
            );
                            
        end
endgenerate


//------------------------------------------------------------------------------
//3. Error interrupt request mask register (EIRQMKRn)
//------------------------------------------------------------------------------
// addr : 0x020 - 0x02C
// access : R/W
// fields : [31:8] : reserved 
//          [7:0]   : error interrupt request mask.
assign en_eirqmk  = (bs_addr_i[11:4] == 8'h02) & bs_sel_i;

genvar k3;
generate
    for(k3=0; k3<CPU_NUM; k3=k3+1)
        begin : eirqmk_label
        case (k3)
            0 :
                assign sel_eirqmk[k3] = (bs_addr_i[3:0] == 4'h0) & en_eirqmk;
            1 :
                assign sel_eirqmk[k3] = (bs_addr_i[3:0] == 4'h4) & en_eirqmk;
            2 :
                assign sel_eirqmk[k3] = (bs_addr_i[3:0] == 4'h8) & en_eirqmk;
            3 :
                assign sel_eirqmk[k3] = (bs_addr_i[3:0] == 4'hC) & en_eirqmk;
            default :
                assign sel_eirqmk[k3] = (bs_addr_i[3:0] == 4'h0) & en_eirqmk;
        endcase
              
        assign we_eirqmk[k3] = sel_eirqmk[k3] & bs_wr_i; 
        //
        intc_rg_cfg  #(.DW(8),
                       .RST_VL(8'd0)) rg_eirqmk_inst 
            (
            .clk            (clk),
            .rst            (rst),
            .we_i           (we_eirqmk[k3]),
            .bs_wdata_i     (bs_wdata_i[7:0]),
            .rg_o           (rg_eimk_o[k3])
            );
                            
        end
endgenerate

//EIRQMK Mux generation
genvar k12;
generate
  for (k12 = CPU_NUM; k12 <= CPU_NUM; k12 = k12 + 1)
    begin : mux_eirqmk_label
    if (k12 == 1)
        assign mux_eirqmk = {8{sel_eirqmk[0]}} & rg_eimk_o[0];
    else if (k12 == 2)
        assign mux_eirqmk = ({8{sel_eirqmk[0]}} & rg_eimk_o[0]) | 
                            ({8{sel_eirqmk[1]}} & rg_eimk_o[1]);
    else if (k12 == 3)
        mux3  #(.DW(8))  mux3_eirqmk
            (
            .in0(rg_eimk_o[0]), .sel0(sel_eirqmk[0]),
            .in1(rg_eimk_o[1]), .sel1(sel_eirqmk[1]),
            .in2(rg_eimk_o[2]), .sel2(sel_eirqmk[2]),
            .out (mux_eirqmk)
            );
    else if (k12 == 4)
        mux4  #(.DW(8))  mux4_eirqmk
            (
            .in0(rg_eimk_o[0]), .sel0(sel_eirqmk[0]),
            .in1(rg_eimk_o[1]), .sel1(sel_eirqmk[1]),
            .in2(rg_eimk_o[2]), .sel2(sel_eirqmk[2]),
            .in3(rg_eimk_o[3]), .sel3(sel_eirqmk[3]),
            .out (mux_eirqmk)
            );
    end
endgenerate


//------------------------------------------------------------------------------
//4. Software interrupt register (SINTRn)
//------------------------------------------------------------------------------
// addr : 0x040 - 0x7C
// access : R/W
// fields : [31:1] : reserved 
//          [0:0]  : Software interrupt request.
assign en_0x04_sint = (bs_addr_i[11:4] == 8'h04) & bs_sel_i;
assign en_0x05_sint = (bs_addr_i[11:4] == 8'h05) & bs_sel_i;
assign en_0x06_sint = (bs_addr_i[11:4] == 8'h06) & bs_sel_i;
assign en_0x07_sint = (bs_addr_i[11:4] == 8'h07) & bs_sel_i;

genvar k4;
generate
    for(k4=0; k4<SW_INT_NUM; k4=k4+1)
        begin : sint_label
        case (k4)
            0 :
                assign sel_sint[k4] = (bs_addr_i[3:0] == 4'h0) & en_0x04_sint;
            1 :
                assign sel_sint[k4] = (bs_addr_i[3:0] == 4'h4) & en_0x04_sint;
            2 :
                assign sel_sint[k4] = (bs_addr_i[3:0] == 4'h8) & en_0x04_sint;
            3 :
                assign sel_sint[k4] = (bs_addr_i[3:0] == 4'hC) & en_0x04_sint;
            4 :
                assign sel_sint[k4] = (bs_addr_i[3:0] == 4'h0) & en_0x05_sint;
            5 :
                assign sel_sint[k4] = (bs_addr_i[3:0] == 4'h4) & en_0x05_sint;
            6 :
                assign sel_sint[k4] = (bs_addr_i[3:0] == 4'h8) & en_0x05_sint;
            7 :
                assign sel_sint[k4] = (bs_addr_i[3:0] == 4'hC) & en_0x05_sint;
            8 :
                assign sel_sint[k4] = (bs_addr_i[3:0] == 4'h0) & en_0x06_sint;
            9 :
                assign sel_sint[k4] = (bs_addr_i[3:0] == 4'h4) & en_0x06_sint;
            10 :
                assign sel_sint[k4] = (bs_addr_i[3:0] == 4'h8) & en_0x06_sint;
            11 :
                assign sel_sint[k4] = (bs_addr_i[3:0] == 4'hC) & en_0x06_sint;
            12 :
                assign sel_sint[k4] = (bs_addr_i[3:0] == 4'h0) & en_0x07_sint;
            13 :
                assign sel_sint[k4] = (bs_addr_i[3:0] == 4'h4) & en_0x07_sint;
            14 :
                assign sel_sint[k4] = (bs_addr_i[3:0] == 4'h8) & en_0x07_sint;
            15 :
                assign sel_sint[k4] = (bs_addr_i[3:0] == 4'hC) & en_0x07_sint;
            default :
                assign sel_sint[k4] = (bs_addr_i[3:0] == 4'h0) & en_0x04_sint;
        endcase
              
        assign we_sint[k4] = sel_sint[k4] & bs_wr_i; 
        //
        intc_rg_clr  #(.DW(1),
                       .RST_VL(1'b0)) rg_sint_inst 
            (
            .clk            (clk),
            .rst            (rst),
            .we_i           (we_sint[k4]),
            .bs_wdata_i     (bs_wdata_i[0]),
            .sync_cpu_int_i (sync_cpu_int_i),
            .rg_o           (rg_sint_o[k4])
            );
                            
        end
endgenerate


//------------------------------------------------------------------------------
//5. Interrupt enable register (IRQENRn)
//------------------------------------------------------------------------------
// addr : 0x100 - 0x114
// access : R/W
// fields : [31:0] : Normal interrupt enable (1 is enable).

assign en_0x10_irqen = (bs_addr_i[11:4] == 8'h10) & bs_sel_i;
assign en_0x11_irqen = (bs_addr_i[11:4] == 8'h11) & bs_sel_i;

genvar k5;
generate
    for(k5=0; k5<REG_NUM; k5=k5+1)
        begin : irqen_label
        case (k5)
            0 :
                assign sel_irqen[k5] = (bs_addr_i[3:0] == 4'h0) & en_0x10_irqen;
            1 :
                assign sel_irqen[k5] = (bs_addr_i[3:0] == 4'h4) & en_0x10_irqen;
            2 :
                assign sel_irqen[k5] = (bs_addr_i[3:0] == 4'h8) & en_0x10_irqen;
            3 :
                assign sel_irqen[k5] = (bs_addr_i[3:0] == 4'hC) & en_0x10_irqen;
            4 :
                assign sel_irqen[k5] = (bs_addr_i[3:0] == 4'h0) & en_0x11_irqen;
            5 :
                assign sel_irqen[k5] = (bs_addr_i[3:0] == 4'h4) & en_0x11_irqen;
            default :
                assign sel_irqen[k5] = (bs_addr_i[3:0] == 4'h0) & en_0x10_irqen;
        endcase
              
        assign we_irqen[k5] = sel_irqen[k5] & bs_wr_i; 
        //
        intc_rg_cfg  #(.DW(32),
                       .RST_VL(32'd0)) rg_irqen_inst 
            (
            .clk            (clk),
            .rst            (rst),
            .we_i           (we_irqen[k5]),
            .bs_wdata_i     (bs_wdata_i),
            .rg_o           (rg_ie_o[k5])
            );
                            
        end
endgenerate

//IRQEN Mux generation
genvar k13;
generate
  for (k13 = REG_NUM; k13 <= REG_NUM; k13 = k13 + 1)
    begin : mux_irqen_label
    if (k13 == 1)
        assign mux_irqen = {32{sel_irqen[0]}} & rg_ie_o[0];
    else if (k13 == 2)
        assign mux_irqen = ({32{sel_irqen[0]}} & rg_ie_o[0]) | 
                           ({32{sel_irqen[1]}} & rg_ie_o[1]);
    else if (k13 == 3)
        mux3  #(.DW(32))  mux3_irqen
            (
            .in0(rg_ie_o[0]), .sel0(sel_irqen[0]),
            .in1(rg_ie_o[1]), .sel1(sel_irqen[1]),
            .in2(rg_ie_o[3]), .sel2(sel_irqen[2]),
            .out (mux_irqen)
            );
    else if (k13 == 4)
        mux4  #(.DW(32))  mux4_irqen
            (
            .in0(rg_ie_o[0]), .sel0(sel_irqen[0]),
            .in1(rg_ie_o[1]), .sel1(sel_irqen[1]),
            .in2(rg_ie_o[2]), .sel2(sel_irqen[2]),
            .in3(rg_ie_o[3]), .sel3(sel_irqen[3]),
            .out(mux_irqen)
            );
    else if (k13 == 5)
        mux5  #(.DW(32))  mux5_irqen
            (
            .in0(rg_ie_o[0]), .sel0(sel_irqen[0]),
            .in1(rg_ie_o[1]), .sel1(sel_irqen[1]),
            .in2(rg_ie_o[2]), .sel2(sel_irqen[2]),
            .in3(rg_ie_o[3]), .sel3(sel_irqen[3]),
            .in4(rg_ie_o[4]), .sel4(sel_irqen[4]),
            .out (mux_irqen)
            );
    else if (k13 == 6)
        mux6  #(.DW(32))  mux6_irqen
            (
            .in0(rg_ie_o[0]), .sel0(sel_irqen[0]),
            .in1(rg_ie_o[1]), .sel1(sel_irqen[1]),
            .in2(rg_ie_o[2]), .sel2(sel_irqen[2]),
            .in3(rg_ie_o[3]), .sel3(sel_irqen[3]),
            .in4(rg_ie_o[4]), .sel4(sel_irqen[4]),
            .in5(rg_ie_o[5]), .sel5(sel_irqen[5]),
            .out (mux_irqen)
            );
    end
endgenerate



//------------------------------------------------------------------------------
//6. Interrupt request register (IRQRn)
//------------------------------------------------------------------------------
// addr : 0x140 - 0x154
// access : R
// fields : [31:0] : Normal interrupt request.

assign en_0x14_irq = (bs_addr_i[11:4] == 8'h14) & bs_sel_i;
assign en_0x15_irq = (bs_addr_i[11:4] == 8'h15) & bs_sel_i;

genvar k6;
generate
    for(k6=0; k6<REG_NUM; k6=k6+1)
        begin : irq_label
        case (k6)
            0 :
                assign sel_irq[k6] = (bs_addr_i[3:0] == 4'h0) & en_0x14_irq;
            1 :
                assign sel_irq[k6] = (bs_addr_i[3:0] == 4'h4) & en_0x14_irq;
            2 :
                assign sel_irq[k6] = (bs_addr_i[3:0] == 4'h8) & en_0x14_irq;
            3 :
                assign sel_irq[k6] = (bs_addr_i[3:0] == 4'hC) & en_0x14_irq;
            4 :
                assign sel_irq[k6] = (bs_addr_i[3:0] == 4'h0) & en_0x15_irq;
            5 :
                assign sel_irq[k6] = (bs_addr_i[3:0] == 4'h4) & en_0x15_irq;
            default :
                assign sel_irq[k6] = (bs_addr_i[3:0] == 4'h0) & en_0x14_irq;
        endcase
        //
        assign irq[k6] = rg_irq_i[k6];
        end
        
endgenerate



//IRQ Mux generation
genvar k14;
generate
  for (k14 = REG_NUM; k14 <= REG_NUM; k14 = k14 + 1)
    begin : mux_irq_label
    if (k14 == 1)
        assign mux_irq = {32{sel_irq[0]}} & irq[0];
    else if (k14 == 2)
        assign mux_irq = ({32{sel_irqen[0]}} & irq[0]) | 
                         ({32{sel_irqen[1]}} & irq[1]);
    else if (k14 == 3)
        mux3  #(.DW(32))  mux3_irq
            (
            .in0(irq[0]), .sel0(sel_irq[0]),
            .in1(irq[1]), .sel1(sel_irq[1]),
            .in2(irq[3]), .sel2(sel_irq[2]),
            .out (mux_irq)
            );
    else if (k14 == 4)
        mux4  #(.DW(32))  mux4_irq
            (
            .in0(irq[0]), .sel0(sel_irq[0]),
            .in1(irq[1]), .sel1(sel_irq[1]),
            .in2(irq[2]), .sel2(sel_irq[2]),
            .in3(irq[3]), .sel3(sel_irq[3]),
            .out(mux_irq)
            );
    else if (k14 == 5)
        mux5  #(.DW(32))  mux5_irq
            (
            .in0(irq[0]), .sel0(sel_irq[0]),
            .in1(irq[1]), .sel1(sel_irq[1]),
            .in2(irq[2]), .sel2(sel_irq[2]),
            .in3(irq[3]), .sel3(sel_irq[3]),
            .in4(irq[4]), .sel4(sel_irq[4]),
            .out (mux_irq)
            );
    else if (k14 == 6)
        mux6  #(.DW(32))  mux6_irq
            (
            .in0(irq[0]), .sel0(sel_irq[0]),
            .in1(irq[1]), .sel1(sel_irq[1]),
            .in2(irq[2]), .sel2(sel_irq[2]),
            .in3(irq[3]), .sel3(sel_irq[3]),
            .in4(irq[4]), .sel4(sel_irq[4]),
            .in5(irq[5]), .sel5(sel_irq[5]),
            .out (mux_irq)
            );
    end
endgenerate


//------------------------------------------------------------------------------
//7. Interrupt request clear register (IRQCRn)
//------------------------------------------------------------------------------
// addr : 0x180 - 0x194
// access : R/W
// fields : [31:0] : Normal interrupt request clear. 

assign en_0x18_irqc = (bs_addr_i[11:4] == 8'h18) & bs_sel_i;
assign en_0x19_irqc = (bs_addr_i[11:4] == 8'h19) & bs_sel_i;

genvar k7;
generate
    for(k7=0; k7<REG_NUM; k7=k7+1)
        begin : irqc_label
        case (k7)
            0 :
                assign sel_irqc[k7] = (bs_addr_i[3:0] == 4'h0) & en_0x18_irqc;
            1 :
                assign sel_irqc[k7] = (bs_addr_i[3:0] == 4'h4) & en_0x18_irqc;
            2 :
                assign sel_irqc[k7] = (bs_addr_i[3:0] == 4'h8) & en_0x18_irqc;
            3 :
                assign sel_irqc[k7] = (bs_addr_i[3:0] == 4'hC) & en_0x18_irqc;
            4 :
                assign sel_irqc[k7] = (bs_addr_i[3:0] == 4'h0) & en_0x19_irqc;
            5 :
                assign sel_irqc[k7] = (bs_addr_i[3:0] == 4'h4) & en_0x19_irqc;
            default :
                assign sel_irqc[k7] = (bs_addr_i[3:0] == 4'h0) & en_0x18_irqc;
        endcase
              
        assign we_irqc[k7] = sel_irqc[k7] & bs_wr_i; 
        //
        intc_rg_clr  #(.DW(32),
                       .RST_VL(32'd0)) rg_irqc_inst 
            (
            .clk            (clk),
            .rst            (rst),
            .we_i           (we_irqc[k7]),
            .bs_wdata_i     (bs_wdata_i),
            .sync_cpu_int_i (sync_cpu_int_i), 
            .rg_o           (rg_irqc_o[k7])
            );
                            
        end
endgenerate

//------------------------------------------------------------------------------
//8. Interrupt request detection method register (IRQDTRn)
//------------------------------------------------------------------------------
// addr : 0x1C0 - 0x1D4
// access : R
// fields : [31:0] : Normal interrupt request detection method.

assign en_0x1c_irqdt = (bs_addr_i[11:4] == 8'h1C) & bs_sel_i;
assign en_0x1d_irqdt = (bs_addr_i[11:4] == 8'h1D) & bs_sel_i;

genvar k8;
generate
    for(k8=0; k8<REG_NUM; k8=k8+1)
        begin : irqdt_label
        case (k8)
            0 :
                assign sel_irqdt[k8] = (bs_addr_i[3:0] == 4'h0) & en_0x1c_irqdt;
            1 :
                assign sel_irqdt[k8] = (bs_addr_i[3:0] == 4'h4) & en_0x1c_irqdt;
            2 :
                assign sel_irqdt[k8] = (bs_addr_i[3:0] == 4'h8) & en_0x1c_irqdt;
            3 :
                assign sel_irqdt[k8] = (bs_addr_i[3:0] == 4'hC) & en_0x1c_irqdt;
            4 :
                assign sel_irqdt[k8] = (bs_addr_i[3:0] == 4'h0) & en_0x1d_irqdt;
            5 :
                assign sel_irqdt[k8] = (bs_addr_i[3:0] == 4'h4) & en_0x1d_irqdt;
            default :
                assign sel_irqdt[k8] = (bs_addr_i[3:0] == 4'h0) & en_0x1c_irqdt;
        endcase
        //
        assign rg_idt_o[k8] = rg_idt_i[k8];
        end
endgenerate
//IRQDT Mux generation
genvar k15;
generate
  for (k15 = REG_NUM; k15 <= REG_NUM; k15 = k15 + 1)
    begin : mux_irqdt_label
    if (k15 == 1)
        assign mux_idt = {32{sel_irqdt[0]}} & rg_idt_o[0];
    else if (k15 == 2)
        assign mux_idt = ({32{sel_irqdt[0]}} & rg_idt_o[0]) | 
                         ({32{sel_irqdt[1]}} & rg_idt_o[1]);
    else if (k15 == 3)
        mux3  #(.DW(32))  mux3_idt
            (
            .in0(rg_idt_o[0]), .sel0(sel_irqdt[0]),
            .in1(rg_idt_o[1]), .sel1(sel_irqdt[1]),
            .in2(rg_idt_o[3]), .sel2(sel_irqdt[2]),
            .out (mux_idt)
            );
    else if (k15 == 4)
        mux4  #(.DW(32))  mux4_idt
            (
            .in0(rg_idt_o[0]), .sel0(sel_irqdt[0]),
            .in1(rg_idt_o[1]), .sel1(sel_irqdt[1]),
            .in2(rg_idt_o[2]), .sel2(sel_irqdt[2]),
            .in3(rg_idt_o[3]), .sel3(sel_irqdt[3]),
            .out(mux_idt)
            );
    else if (k15 == 5)
        mux5  #(.DW(32))  mux5_idt
            (
            .in0(rg_idt_o[0]), .sel0(sel_irqdt[0]),
            .in1(rg_idt_o[1]), .sel1(sel_irqdt[1]),
            .in2(rg_idt_o[2]), .sel2(sel_irqdt[2]),
            .in3(rg_idt_o[3]), .sel3(sel_irqdt[3]),
            .in4(rg_idt_o[4]), .sel4(sel_irqdt[4]),
            .out (mux_idt)
            );
    else if (k15 == 6)
        mux6  #(.DW(32))  mux6_idt
            (
            .in0(rg_idt_o[0]), .sel0(sel_irqdt[0]),
            .in1(rg_idt_o[1]), .sel1(sel_irqdt[1]),
            .in2(rg_idt_o[2]), .sel2(sel_irqdt[2]),
            .in3(rg_idt_o[3]), .sel3(sel_irqdt[3]),
            .in4(rg_idt_o[4]), .sel4(sel_irqdt[4]),
            .in5(rg_idt_o[5]), .sel5(sel_irqdt[5]),
            .out (mux_idt)
            );
    end
endgenerate

//------------------------------------------------------------------------------
//9. Interrupt priority register (IPRRn)
//------------------------------------------------------------------------------
// addr : 0x200 - 0x25C
// access : R/W
// fields : [31:0] : Priority of normal interrupt.
assign en_0x20_ipr = (bs_addr_i[11:4] == 8'h20) & bs_sel_i;
assign en_0x21_ipr = (bs_addr_i[11:4] == 8'h21) & bs_sel_i;
assign en_0x22_ipr = (bs_addr_i[11:4] == 8'h22) & bs_sel_i;
assign en_0x23_ipr = (bs_addr_i[11:4] == 8'h23) & bs_sel_i;
assign en_0x24_ipr = (bs_addr_i[11:4] == 8'h24) & bs_sel_i;
assign en_0x25_ipr = (bs_addr_i[11:4] == 8'h25) & bs_sel_i;

genvar k9;
generate
    for(k9=0; k9<(REG_NUM*4); k9=k9+1)
        begin : ipr_label
        case (k9)
            0 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h0) & en_0x20_ipr;
            1 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h4) & en_0x20_ipr;
            2 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h8) & en_0x20_ipr;
            3 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'hC) & en_0x20_ipr;
            4 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h0) & en_0x21_ipr;
            5 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h4) & en_0x21_ipr;
            6 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h8) & en_0x21_ipr;
            7 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'hC) & en_0x21_ipr;
            8 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h0) & en_0x22_ipr;
            9 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h4) & en_0x22_ipr;
            10 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h8) & en_0x22_ipr;
            11 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'hC) & en_0x22_ipr;
            12 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h0) & en_0x23_ipr;
            13 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h4) & en_0x23_ipr;
            14 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h8) & en_0x23_ipr;
            15 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'hC) & en_0x23_ipr;
            16 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h0) & en_0x24_ipr;
            17 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h4) & en_0x24_ipr;
            18 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h8) & en_0x24_ipr;
            19 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'hC) & en_0x24_ipr;
            20 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h0) & en_0x25_ipr;
            21 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h4) & en_0x25_ipr;
            22 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h8) & en_0x25_ipr;
            23 :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'hC) & en_0x25_ipr;
            default :
                assign sel_ipr[k9] = (bs_addr_i[3:0] == 4'h0) & en_0x20_ipr;
        endcase
              
        assign we_ipr[k9] = sel_ipr[k9] & bs_wr_i; 
        //
        intc_rg_cfg  #(.DW(32),
                       .RST_VL(32'd0)) rg_ipr_inst 
            (
            .clk            (clk),
            .rst            (rst),
            .we_i           (we_ipr[k9]),
            .bs_wdata_i     (bs_wdata_i),
            .rg_o           (ipr[k9])
            );

        assign rg_ipr_o[k9*8+7:k9*8] = ipr[k9];
                            
        end
endgenerate
//IRQDT Mux generation
genvar k16;
generate
  for (k16 = REG_NUM; k16 <= REG_NUM; k16 = k16 + 1)
    begin : mux_ipr_label
    if (k16 == 1)
        mux4  #(.DW(32))  mux4_ipr
            (
            .in0(ipr[0]), .sel0(sel_ipr[0]),
            .in1(ipr[1]), .sel1(sel_ipr[1]),
            .in2(ipr[2]), .sel2(sel_ipr[2]),
            .in3(ipr[3]), .sel3(sel_ipr[3]),
            .out(mux_ipr)
            );
    else if (k16 == 2)
        mux8  #(.DW(32))  mux8_ipr
            (
            .in0(ipr[0]), .sel0(sel_ipr[0]),
            .in1(ipr[1]), .sel1(sel_ipr[1]),
            .in2(ipr[2]), .sel2(sel_ipr[2]),
            .in3(ipr[3]), .sel3(sel_ipr[3]),
            .in4(ipr[4]), .sel4(sel_ipr[4]),
            .in5(ipr[5]), .sel5(sel_ipr[5]),
            .in6(ipr[6]), .sel6(sel_ipr[6]),
            .in7(ipr[7]), .sel7(sel_ipr[7]),
            .out(mux_ipr)
            );
    else if (k16 == 3)
        mux12  #(.DW(32))  mux12_ipr
            (
            .in0(ipr[0]),   .sel0(sel_ipr[0]),
            .in1(ipr[1]),   .sel1(sel_ipr[1]),
            .in2(ipr[2]),   .sel2(sel_ipr[2]),
            .in3(ipr[3]),   .sel3(sel_ipr[3]),
            .in4(ipr[4]),   .sel4(sel_ipr[4]),
            .in5(ipr[5]),   .sel5(sel_ipr[5]),
            .in6(ipr[6]),   .sel6(sel_ipr[6]),
            .in7(ipr[7]),   .sel7(sel_ipr[7]),
            .in8(ipr[8]),   .sel8(sel_ipr[8]),
            .in9(ipr[9]),   .sel9(sel_ipr[9]),
            .in10(ipr[10]), .sel10(sel_ipr[10]),
            .in11(ipr[11]), .sel11(sel_ipr[11]),
            .out(mux_ipr)
            );
    else if (k16 == 4)
        mux16  #(.DW(32))  mux16_ipr
            (
            .in0(ipr[0]),   .sel0(sel_ipr[0]),
            .in1(ipr[1]),   .sel1(sel_ipr[1]),
            .in2(ipr[2]),   .sel2(sel_ipr[2]),
            .in3(ipr[3]),   .sel3(sel_ipr[3]),
            .in4(ipr[4]),   .sel4(sel_ipr[4]),
            .in5(ipr[5]),   .sel5(sel_ipr[5]),
            .in6(ipr[6]),   .sel6(sel_ipr[6]),
            .in7(ipr[7]),   .sel7(sel_ipr[7]),
            .in8(ipr[8]),   .sel8(sel_ipr[8]),
            .in9(ipr[9]),   .sel9(sel_ipr[9]),
            .in10(ipr[10]), .sel10(sel_ipr[10]),
            .in11(ipr[11]), .sel11(sel_ipr[11]),
            .in12(ipr[12]), .sel12(sel_ipr[12]),
            .in13(ipr[13]), .sel13(sel_ipr[13]),
            .in14(ipr[14]), .sel14(sel_ipr[14]),
            .in15(ipr[15]), .sel15(sel_ipr[15]),
            .out(mux_ipr)
            );
    else if (k16 == 5)
        mux20  #(.DW(32))  mux20_ipr
            (
            .in0(ipr[0]),   .sel0(sel_ipr[0]),
            .in1(ipr[1]),   .sel1(sel_ipr[1]),
            .in2(ipr[2]),   .sel2(sel_ipr[2]),
            .in3(ipr[3]),   .sel3(sel_ipr[3]),
            .in4(ipr[4]),   .sel4(sel_ipr[4]),
            .in5(ipr[5]),   .sel5(sel_ipr[5]),
            .in6(ipr[6]),   .sel6(sel_ipr[6]),
            .in7(ipr[7]),   .sel7(sel_ipr[7]),
            .in8(ipr[8]),   .sel8(sel_ipr[8]),
            .in9(ipr[9]),   .sel9(sel_ipr[9]),
            .in10(ipr[10]), .sel10(sel_ipr[10]),
            .in11(ipr[11]), .sel11(sel_ipr[11]),
            .in12(ipr[12]), .sel12(sel_ipr[12]),
            .in13(ipr[13]), .sel13(sel_ipr[13]),
            .in14(ipr[14]), .sel14(sel_ipr[14]),
            .in15(ipr[15]), .sel15(sel_ipr[15]),
            .in16(ipr[16]), .sel16(sel_ipr[16]),
            .in17(ipr[17]), .sel17(sel_ipr[17]),
            .in18(ipr[18]), .sel18(sel_ipr[18]),
            .in19(ipr[19]), .sel19(sel_ipr[19]),
            .out(mux_ipr)
            );
    else if (k16 == 6)
        mux24  #(.DW(32))  mux24_ipr
            (
            .in0(ipr[0]),   .sel0(sel_ipr[0]),
            .in1(ipr[1]),   .sel1(sel_ipr[1]),
            .in2(ipr[2]),   .sel2(sel_ipr[2]),
            .in3(ipr[3]),   .sel3(sel_ipr[3]),
            .in4(ipr[4]),   .sel4(sel_ipr[4]),
            .in5(ipr[5]),   .sel5(sel_ipr[5]),
            .in6(ipr[6]),   .sel6(sel_ipr[6]),
            .in7(ipr[7]),   .sel7(sel_ipr[7]),
            .in8(ipr[8]),   .sel8(sel_ipr[8]),
            .in9(ipr[9]),   .sel9(sel_ipr[9]),
            .in10(ipr[10]), .sel10(sel_ipr[10]),
            .in11(ipr[11]), .sel11(sel_ipr[11]),
            .in12(ipr[12]), .sel12(sel_ipr[12]),
            .in13(ipr[13]), .sel13(sel_ipr[13]),
            .in14(ipr[14]), .sel14(sel_ipr[14]),
            .in15(ipr[15]), .sel15(sel_ipr[15]),
            .in16(ipr[16]), .sel16(sel_ipr[16]),
            .in17(ipr[17]), .sel17(sel_ipr[17]),
            .in18(ipr[18]), .sel18(sel_ipr[18]),
            .in19(ipr[19]), .sel19(sel_ipr[19]),
            .in20(ipr[20]), .sel20(sel_ipr[20]),
            .in21(ipr[21]), .sel21(sel_ipr[21]),
            .in22(ipr[22]), .sel22(sel_ipr[22]),
            .in23(ipr[23]), .sel23(sel_ipr[23]),
            .out(mux_ipr)
            );
    end
endgenerate







//------------------------------------------------------------------------------
//10. Interrupt target register (ITGTRn)
//------------------------------------------------------------------------------
// addr : 0x300 - 0x35C
// access : R/W
// fields : [31:0] : Interrupt target cpu.



assign en_0x30_itgt = (bs_addr_i[11:4] == 8'h30) & bs_sel_i;
assign en_0x31_itgt = (bs_addr_i[11:4] == 8'h31) & bs_sel_i;
assign en_0x32_itgt = (bs_addr_i[11:4] == 8'h32) & bs_sel_i;
assign en_0x33_itgt = (bs_addr_i[11:4] == 8'h33) & bs_sel_i;
assign en_0x34_itgt = (bs_addr_i[11:4] == 8'h34) & bs_sel_i;
assign en_0x35_itgt = (bs_addr_i[11:4] == 8'h35) & bs_sel_i;

genvar k10;
generate
    for(k10=0; k10<(REG_NUM*4); k10=k10+1)
        begin : itgt_label
        case (k10)
            0 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h0) & en_0x30_itgt;
            1 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h4) & en_0x30_itgt;
            2 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h8) & en_0x30_itgt;
            3 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'hC) & en_0x30_itgt;
            4 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h0) & en_0x31_itgt;
            5 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h4) & en_0x31_itgt;
            6 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h8) & en_0x31_itgt;
            7 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'hC) & en_0x31_itgt;
            8 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h0) & en_0x32_itgt;
            9 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h4) & en_0x32_itgt;
            10 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h8) & en_0x32_itgt;
            11 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'hC) & en_0x32_itgt;
            12 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h0) & en_0x33_itgt;
            13 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h4) & en_0x33_itgt;
            14 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h8) & en_0x33_itgt;
            15 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'hC) & en_0x33_itgt;
            16 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h0) & en_0x34_itgt;
            17 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h4) & en_0x34_itgt;
            18 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h8) & en_0x34_itgt;
            19 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'hC) & en_0x34_itgt;
            20 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h0) & en_0x35_itgt;
            21 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h4) & en_0x35_itgt;
            22 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h8) & en_0x35_itgt;
            23 :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'hC) & en_0x35_itgt;
            default :
                assign sel_itgt[k10] = (bs_addr_i[3:0] == 4'h0) & en_0x30_itgt;
        endcase
              
        assign we_itgt[k10] = sel_itgt[k10] & bs_wr_i; 
        //
        intc_rg_cfg  #(.DW(32),
                       .RST_VL(32'h11111111)) rg_itgt_inst 
            (
            .clk            (clk),
            .rst            (rst),
            .we_i           (we_itgt[k10]),
            .bs_wdata_i     (bs_wdata_i),
            .rg_o           (itgt[k10])
            );

        assign rg_itgt_o[0][k10*8+7:k10*8] = {itgt[k10][28],itgt[k10][24],itgt[k10][20],itgt[k10][16],
                                              itgt[k10][12],itgt[k10][8], itgt[k10][4], itgt[k10][0]};
 
        assign rg_itgt_o[1][k10*8+7:k10*8] = {itgt[k10][29],itgt[k10][25],itgt[k10][21],itgt[k10][17],
                                              itgt[k10][13],itgt[k10][9], itgt[k10][5], itgt[k10][1]};
                            
        assign rg_itgt_o[2][k10*8+7:k10*8] = {itgt[k10][30],itgt[k10][26],itgt[k10][22],itgt[k10][18],
                                              itgt[k10][14],itgt[k10][10],itgt[k10][6], itgt[k10][2]};

        assign rg_itgt_o[3][k10*8+7:k10*8] = {itgt[k10][31],itgt[k10][27],itgt[k10][23],itgt[k10][19],
                                              itgt[k10][15],itgt[k10][11],itgt[k10][7], itgt[k10][3]};
        end
endgenerate

//ITGT Mux generation
genvar k17;
generate
  for (k17 = REG_NUM; k17 <= REG_NUM; k17 = k17 + 1)
    begin : mux_itgt_label
    if (k17 == 1)
        mux4  #(.DW(32))  mux4_itgt
            (
            .in0(itgt[0]), .sel0(sel_itgt[0]),
            .in1(itgt[1]), .sel1(sel_itgt[1]),
            .in2(itgt[2]), .sel2(sel_itgt[2]),
            .in3(itgt[3]), .sel3(sel_itgt[3]),
            .out(mux_itgt)
            );
    else if (k17 == 2)
        mux8  #(.DW(32))  mux8_itgt
            (
            .in0(itgt[0]), .sel0(sel_itgt[0]),
            .in1(itgt[1]), .sel1(sel_itgt[1]),
            .in2(itgt[2]), .sel2(sel_itgt[2]),
            .in3(itgt[3]), .sel3(sel_itgt[3]),
            .in4(itgt[4]), .sel4(sel_itgt[4]),
            .in5(itgt[5]), .sel5(sel_itgt[5]),
            .in6(itgt[6]), .sel6(sel_itgt[6]),
            .in7(itgt[7]), .sel7(sel_itgt[7]),
            .out(mux_itgt)
            );
    else if (k17 == 3)
        mux12  #(.DW(32))  mux12_itgt
            (
            .in0(itgt[0]),   .sel0(sel_itgt[0]),
            .in1(itgt[1]),   .sel1(sel_itgt[1]),
            .in2(itgt[2]),   .sel2(sel_itgt[2]),
            .in3(itgt[3]),   .sel3(sel_itgt[3]),
            .in4(itgt[4]),   .sel4(sel_itgt[4]),
            .in5(itgt[5]),   .sel5(sel_itgt[5]),
            .in6(itgt[6]),   .sel6(sel_itgt[6]),
            .in7(itgt[7]),   .sel7(sel_itgt[7]),
            .in8(itgt[8]),   .sel8(sel_itgt[8]),
            .in9(itgt[9]),   .sel9(sel_itgt[9]),
            .in10(itgt[10]), .sel10(sel_itgt[10]),
            .in11(itgt[11]), .sel11(sel_itgt[11]),
            .out(mux_itgt)
            );
    else if (k17 == 4)
        mux16  #(.DW(32))  mux16_itgt
            (
            .in0(itgt[0]),   .sel0(sel_itgt[0]),
            .in1(itgt[1]),   .sel1(sel_itgt[1]),
            .in2(itgt[2]),   .sel2(sel_itgt[2]),
            .in3(itgt[3]),   .sel3(sel_itgt[3]),
            .in4(itgt[4]),   .sel4(sel_itgt[4]),
            .in5(itgt[5]),   .sel5(sel_itgt[5]),
            .in6(itgt[6]),   .sel6(sel_itgt[6]),
            .in7(itgt[7]),   .sel7(sel_itgt[7]),
            .in8(itgt[8]),   .sel8(sel_itgt[8]),
            .in9(itgt[9]),   .sel9(sel_itgt[9]),
            .in10(itgt[10]), .sel10(sel_itgt[10]),
            .in11(itgt[11]), .sel11(sel_itgt[11]),
            .in12(itgt[12]), .sel12(sel_itgt[12]),
            .in13(itgt[13]), .sel13(sel_itgt[13]),
            .in14(itgt[14]), .sel14(sel_itgt[14]),
            .in15(itgt[15]), .sel15(sel_itgt[15]),
            .out(mux_itgt)
            );
    else if (k17 == 5)
        mux20  #(.DW(32))  mux20_itgt
            (
            .in0(itgt[0]),   .sel0(sel_itgt[0]),
            .in1(itgt[1]),   .sel1(sel_itgt[1]),
            .in2(itgt[2]),   .sel2(sel_itgt[2]),
            .in3(itgt[3]),   .sel3(sel_itgt[3]),
            .in4(itgt[4]),   .sel4(sel_itgt[4]),
            .in5(itgt[5]),   .sel5(sel_itgt[5]),
            .in6(itgt[6]),   .sel6(sel_itgt[6]),
            .in7(itgt[7]),   .sel7(sel_itgt[7]),
            .in8(itgt[8]),   .sel8(sel_itgt[8]),
            .in9(itgt[9]),   .sel9(sel_itgt[9]),
            .in10(itgt[10]), .sel10(sel_itgt[10]),
            .in11(itgt[11]), .sel11(sel_itgt[11]),
            .in12(itgt[12]), .sel12(sel_itgt[12]),
            .in13(itgt[13]), .sel13(sel_itgt[13]),
            .in14(itgt[14]), .sel14(sel_itgt[14]),
            .in15(itgt[15]), .sel15(sel_itgt[15]),
            .in16(itgt[16]), .sel16(sel_itgt[16]),
            .in17(itgt[17]), .sel17(sel_itgt[17]),
            .in18(itgt[18]), .sel18(sel_itgt[18]),
            .in19(itgt[19]), .sel19(sel_itgt[19]),
            .out(mux_itgt)
            );
    else if (k17 == 6)
        mux24  #(.DW(32))  mux24_itgt
            (
            .in0(itgt[0]),   .sel0(sel_itgt[0]),
            .in1(itgt[1]),   .sel1(sel_itgt[1]),
            .in2(itgt[2]),   .sel2(sel_itgt[2]),
            .in3(itgt[3]),   .sel3(sel_itgt[3]),
            .in4(itgt[4]),   .sel4(sel_itgt[4]),
            .in5(itgt[5]),   .sel5(sel_itgt[5]),
            .in6(itgt[6]),   .sel6(sel_itgt[6]),
            .in7(itgt[7]),   .sel7(sel_itgt[7]),
            .in8(itgt[8]),   .sel8(sel_itgt[8]),
            .in9(itgt[9]),   .sel9(sel_itgt[9]),
            .in10(itgt[10]), .sel10(sel_itgt[10]),
            .in11(itgt[11]), .sel11(sel_itgt[11]),
            .in12(itgt[12]), .sel12(sel_itgt[12]),
            .in13(itgt[13]), .sel13(sel_itgt[13]),
            .in14(itgt[14]), .sel14(sel_itgt[14]),
            .in15(itgt[15]), .sel15(sel_itgt[15]),
            .in16(itgt[16]), .sel16(sel_itgt[16]),
            .in17(itgt[17]), .sel17(sel_itgt[17]),
            .in18(itgt[18]), .sel18(sel_itgt[18]),
            .in19(itgt[19]), .sel19(sel_itgt[19]),
            .in20(itgt[20]), .sel20(sel_itgt[20]),
            .in21(itgt[21]), .sel21(sel_itgt[21]),
            .in22(itgt[22]), .sel22(sel_itgt[22]),
            .in23(itgt[23]), .sel23(sel_itgt[23]),
            .out(mux_itgt)
            );
    end
endgenerate
//------------------------------------------------------------------------------
//Read data output
//------------------------------------------------------------------------------
assign bs_rdata_o = {24'd0,mux_eirq} | {24'd0,mux_eirqmk} | mux_irqen | mux_irq |
                    mux_idt | mux_ipr | mux_itgt;


endmodule 

