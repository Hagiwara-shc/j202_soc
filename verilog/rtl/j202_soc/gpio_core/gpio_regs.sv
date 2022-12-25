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

//////////////////////////////////////////////////////////////////////////////////
//
// SH Consulting
//
// Filename        : gpio_regs.v
// Description     : Configuration and status registers.
//                   
//					
//
// Author          : Duong Nguyen
// Created On      : 9/9/2015
// History (Date, Changed By)
//
//////////////////////////////////////////////////////////////////////////////////
module gpio_regs
    (
    clk,
    rst,
    //--------------------------------------
    //Internal inf
    addr_i,
    wdata_i, 
    wen_i,
    ren_i, 
    rdata_o, 
    //--------------------------------------
    //Output config
    gpio_o,
    gpio_i,
    gpio_en_o,
    //--------------------------------------
    //Interrupt
    gpio_int_o
    );
//-----------------------------------------------------------------------------
//Parameter
parameter ADDR_W = 6'd32;
parameter DATA_W = 6'd32;

parameter IDR_W  = 6'd32;
parameter ODR_W  = 6'd32;
parameter IER_W  = 6'd32;
parameter ISR_W  = 6'd32;
parameter DR_W   = 6'd32;

//-----------------------------------------------------------------------------
//Port
input                       clk;
input                       rst;
//--------------------------------------
//Internal interface
input  logic [ADDR_W-1:0]   addr_i;
input  logic [DATA_W-1:0]   wdata_i; 
input  logic                wen_i; 
input  logic                ren_i; 
output logic  [DATA_W-1:0]  rdata_o; 
//--------------------------------------
//Output config
output logic [DATA_W-1:0]   gpio_o;
input  logic [DATA_W-1:0]   gpio_i;
output logic [DATA_W-1:0]   gpio_en_o;
//--------------------------------------
//Interrupt
output logic                gpio_int_o;

//-----------------------------------------------------------------------------
//Internal variable
logic                       idr_addr_vld;
logic                       idr_ren;
logic [IDR_W-1:0]           gpio_in_1;
logic [IDR_W-1:0]           gpio_in_2;
logic [IDR_W-1:0]           idr_cpudo;

logic                       odr_addr_vld;
logic                       odr_wen;
logic                       odr_ren;
logic                       odr_clr;
logic [ODR_W-1:0]           odr_di;
logic [ODR_W-1:0]           odr;
logic [ODR_W-1:0]           odr_cpudo;

logic                       dr_addr_vld;
logic                       dr_wen;
logic                       dr_ren;
logic                       dr_clr;
logic [DR_W-1:0]            dr_di;
logic [DR_W-1:0]            dr;
logic [DR_W-1:0]            dr_cpudo;

logic                       ier_addr_vld;
logic                       ier_wen;
logic                       ier_ren;
logic                       ier_clr;
logic [IER_W-1:0]           ier_di;
logic [IER_W-1:0]           ier;
logic [IER_W-1:0]           ier_cpudo;

logic                       isr_addr_vld;
logic                       isr_wen;
logic                       isr_ren;
logic                       isr_clr;
logic [ISR_W-1:0]           isr_di;
logic [ISR_W-1:0]           isr;
logic [ISR_W-1:0]           isr_cpudo;
logic [ISR_W-1:0]           isr_status;

logic                       dtr_addr_vld;
logic                       dtr_wen;
logic                       dtr_ren;
logic                       dtr_clr;
logic [IER_W-1:0]           dtr_di;
logic [IER_W-1:0]           dtr;
logic [IER_W-1:0]           dtr_cpudo;

logic [IDR_W-1:0]           gpio_in_3; 
logic [IDR_W-1:0]           rise_edge;
logic [IDR_W-1:0]           fall_edge;

//-----------------------------------------------------------------------------
// Input data register (idr) 
// Address : 0x00 
// Fields   Name            Access 
// [31:0]   DATA_IN         R


//Synchronization, reduce metastability
dff_rst  #(IDR_W)  dff_gpio_in_1 (clk,rst,gpio_i   ,gpio_in_1);
dff_rst  #(IDR_W)  dff_gpio_in_2 (clk,rst,gpio_in_1,gpio_in_2);

assign idr_addr_vld = (addr_i[7:0] == 8'b0000_0000);
assign idr_ren      = idr_addr_vld & ren_i;

assign idr_cpudo = gpio_in_2;

//-----------------------------------------------------------------------------
// Output data register (odr) 
// Address : 0x04
// Fields   Name            Access 
// [31:0]   DATA_OUT        RW

assign odr_addr_vld = (addr_i[7:0] == 8'b0000_0100);
assign odr_wen      = odr_addr_vld & wen_i;
assign odr_ren      = odr_addr_vld & ren_i;

gpio_cfg_reg  #(.DW(ODR_W))  odr_reg
    (
    .clk   (clk),
    .rst   (rst),
    //--------------------------------------
    //cpu access
    .ren_i (odr_ren),  //read enable
    .wen_i (odr_wen),  //write enable
    .di_i  (odr_di),  // Input data from CPU
    //--------------------------------------
    //Output of configuration register
    .reg_o (odr),
    //--------------------------------------
    //Clear
    .clr_i (odr_clr)
     );

assign odr_di    = wdata_i[ODR_W-1:0];
assign odr_clr   = 1'b0;
assign odr_cpudo = odr;

assign gpio_o = odr; 
//-----------------------------------------------------------------------------
// Direction register (dr) 
// Address : 0x08
// Fields   Name            Access 
// [31:0]   DIR             RW

assign dr_addr_vld = (addr_i[7:0] == 8'b0000_1000);
assign dr_wen      = dr_addr_vld & wen_i;
assign dr_ren      = dr_addr_vld & ren_i;

gpio_cfg_reg  #(.DW(DR_W))  dr_reg
    (
    .clk   (clk),
    .rst   (rst),
    //--------------------------------------
    //cpu access
    .ren_i (dr_ren),  //read enable
    .wen_i (dr_wen),  //write enable
    .di_i  (dr_di),  // Input data from CPU
    //--------------------------------------
    //Output of configuration register
    .reg_o (dr),
    //--------------------------------------
    //Clear
    .clr_i (dr_clr)
     );

assign dr_di    = wdata_i[DR_W-1:0];
assign dr_clr   = 1'b0;
assign dr_cpudo = dr;

assign gpio_en_o = dr;
//-----------------------------------------------------------------------------
// Interrupt enable register (ier) 
// Address : 0x0C
// Fields   Name            Access 
// [31:0]   DIR             RW

assign ier_addr_vld = (addr_i[7:0] == 8'b0000_1100);
assign ier_wen      = ier_addr_vld & wen_i;
assign ier_ren      = ier_addr_vld & ren_i;

gpio_cfg_reg  #(.DW(IER_W))  ier_reg
    (
    .clk   (clk),
    .rst   (rst),
    //--------------------------------------
    //cpu access
    .ren_i (ier_ren),  //read enable
    .wen_i (ier_wen),  //write enable
    .di_i  (ier_di),  // Input data from CPU
    //--------------------------------------
    //Output of configuration register
    .reg_o (ier),
    //--------------------------------------
    //Clear
    .clr_i (ier_clr)
     );

assign ier_di    = wdata_i[IER_W-1:0];
assign ier_clr   = 1'b0;
assign ier_cpudo = ier;

//-----------------------------------------------------------------------------
// Interrupt Status Register (isr) 
// Address : 0x10
// Fields    Name            Access 
// [31:00]   INT_STATUS      R/TOW

assign isr_addr_vld = (addr_i[7:0] == 8'b0001_0000);
assign isr_wen      = isr_addr_vld & wen_i;
assign isr_ren      = isr_addr_vld & ren_i;


gpio_status_reg   #(.DW(ISR_W))   isr_reg
    (
     .clk      (clk),
     .rst      (rst),
     //--------------------------------------
     //cpu access
     .ren_i    (isr_ren), //read enable
     .wen_i    (isr_wen), //write enable
     .di_i     (isr_di),  // Input data from CPU
     .reg_o    (isr),     // Output data for CPU
     //--------------------------------------
     //Status signal from IP
     .status_i (isr_status),
     //--------------------------------------
     //Clear
     .clr_i    (isr_clr)
     );

assign isr_clr = 1'b0;
assign isr_di  = (~wdata_i[ISR_W - 1:0]) & isr;
assign isr_status = ((fall_edge & dtr) | (rise_edge & (~dtr))) & ier;
assign isr_cpudo  = isr;

assign gpio_int_o = | isr;//level interrupt
//-----------------------------------------------------------------------------
// Detecttion type register (dtr) 
// Address : 0x14
// Fields   Name            Access 
// [31:0]   DET_TYPE        RW

assign dtr_addr_vld = (addr_i[7:0] == 8'b0001_0100);
assign dtr_wen      = dtr_addr_vld & wen_i;
assign dtr_ren      = dtr_addr_vld & ren_i;

gpio_cfg_reg  #(.DW(IER_W))  dtr_reg
    (
    .clk   (clk),
    .rst   (rst),
    //--------------------------------------
    //cpu access
    .ren_i (dtr_ren),  //read enable
    .wen_i (dtr_wen),  //write enable
    .di_i  (dtr_di),  // Input data from CPU
    //--------------------------------------
    //Output of configuration register
    .reg_o (dtr),
    //--------------------------------------
    //Clear
    .clr_i (dtr_clr)
     );

assign dtr_di    = wdata_i[IER_W-1:0];
assign dtr_clr   = 1'b0;
assign dtr_cpudo = dtr;

//-----------------------------------------------------------------------------
// Edge detection

dff_rst  #(IDR_W)  dff_gpio_in_3 (clk,rst,gpio_in_2,gpio_in_3);

//Rising edge of input pins
assign rise_edge = (~gpio_in_3) & gpio_in_2 & (~dr);

//Falling edge of input pins
assign fall_edge = gpio_in_3 & (~gpio_in_2) & (~dr);


//-----------------------------------------------------------------------------
//Read data output 
mux6  #(.DW(32))  mux6_rdata
    (
    .in0 (idr_cpudo), .sel0 (idr_ren),
    .in1 (odr_cpudo), .sel1 (odr_ren),
    .in2 (dr_cpudo ), .sel2 (dr_ren ),
    .in3 (ier_cpudo), .sel3 (ier_ren),
    .in4 (isr_cpudo), .sel4 (isr_ren),
    .in5 (dtr_cpudo), .sel5 (dtr_ren),
    //out
    .out (rdata_o)
    );


endmodule
