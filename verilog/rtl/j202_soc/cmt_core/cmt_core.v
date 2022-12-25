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
//  SH Consulting
//
// Filename        : cmt_core.v
// Description     : Compare match timer core (2 channel)
//					
//
// Author          : Duong Nguyen
// Created On      : 9/9/2015
// History (Date, Changed By)
//
//////////////////////////////////////////////////////////////////////////////////
module cmt_core
    (
    clk,//50mhz
    rst_n,
    //--------------------------------------
    //APB slave inf
    psel_i,
    pwrite_i,
    penable_i,
    paddr_i,
    pwdata_i,
    prdata_o,
    pslverr_o,
    pready_o,
    //--------------------------------------
    //Interrupt
    cmt0_int_o,
    cmt1_int_o
    );
//-----------------------------------------------------------------------------
//Parameter

//-----------------------------------------------------------------------------
//Port
input                clk;//50mhz
input                rst_n;
//--------------------------------------
//APB slave inf
input                psel_i;
input                pwrite_i;
input                penable_i;
input [7:0]          paddr_i;
input [31:0]         pwdata_i;
output [31:0]        prdata_o;
output               pslverr_o;
output               pready_o;
//--------------------------------------
//Interrupt
output               cmt0_int_o;
output               cmt1_int_o;

//-----------------------------------------------------------------------------
//Internal variable
wire                 reg_wen;
wire  [31:0]         reg_wdata;
wire  [31:0]         reg_rdata;
wire  [7:0]          reg_addr;
wire                 reg_ren;
wire [1:0]           cks0;
wire [1:0]           cks1;
wire                 set_cnt0;
wire                 set_cnt1;
wire  [15:0]         wdata_cnt0;
wire  [15:0]         wdata_cnt1;
wire  [15:0]         const0;
wire  [15:0]         const1;
wire                 str0;
wire                 str1;
wire                 cmf0;
wire                 cmf1;
wire  [15:0]         cnt0;
wire  [15:0]         cnt1;



//-----------------------------------------------------------------------------
//APB slave
cmt_apb    #(.AW(8),
             .DW(32))  cmt_apb_00
    (
    .clk         (clk),
    .rst_n       (rst_n),
    //---------------------------------
    //APB bus interface
    .psel_i      (psel_i),
    .pwrite_i    (pwrite_i),
    .penable_i   (penable_i),
    .paddr_i     (paddr_i),
    .pwdata_i    (pwdata_i),
    .prdata_o    (prdata_o),
    .pslverr_o   (pslverr_o),
    .pready_o    (pready_o),
    //---------------------------------
    // Register file interface
    .reg_wen_o   (reg_wen),
    .reg_wdata_o (reg_wdata),
    .reg_addr_o  (reg_addr),
    .reg_ren_o   (reg_ren),
    .reg_rdata_i (reg_rdata)
    );

//-----------------------------------------------------------------------------
//Configuration and status Register

cmt_regs   cmt_regs_00
    (
    .clk          (clk),
    .rst_n        (rst_n),
    //--------------------------------------
    // Write inf
    .wen_i        (reg_wen), 
    .wdata_i      (reg_wdata),
    .addr_i       (reg_addr),
    //--------------------------------------
    // Read inf
    .ren_i        (reg_ren), 
    .rdata_o      (reg_rdata),
    //--------------------------------------
    // outputs
    .cks0_o       (cks0),
    .cks1_o       (cks1),
    .set_cnt0_o   (set_cnt0),
    .wdata_cnt0_o (wdata_cnt0),
    .set_cnt1_o   (set_cnt1),
    .wdata_cnt1_o (wdata_cnt1),
    .const0_o     (const0),
    .const1_o     (const1),
    .cmt0_int_o   (cmt0_int_o),
    .cmt1_int_o   (cmt1_int_o),
    .str0_o       (str0),
    .str1_o       (str1),    
    //--------------------------------------
    // inputs	
    .cmf0_i       (cmf0),
    .cmf1_i       (cmf1),
    .cnt0_i       (cnt0),
    .cnt1_i       (cnt1)
    );
//-----------------------------------------------------------------------------
//Counters
cmt_2ch      cmt_2ch_00
    (
    .clk          (clk),//50mhz
    .rst_n        (rst_n),
    //--------------------------------------
    //Configuration inf
    .str0_i       (str0),//start timer0   
    .str1_i       (str1),//start timer1
    .cks0_i       (cks0),//select clock(:8,:32,:128,:512) for timer0
    .cks1_i       (cks1),//select clock(:8,:32,:128,:512) for timer1
    .const0_i     (const0),//constant value of timer0
    .const1_i     (const1),//constant value of timer0
    .set_cnt0_i   (set_cnt0),
    .wdata_cnt0_i (wdata_cnt0),
    .set_cnt1_i   (set_cnt1),
    .wdata_cnt1_i (wdata_cnt1),
    .cmf0_o       (cmf0),//timer0 match pulse
    .cmf1_o       (cmf1),//timer1 match pulse
    .cnt0_o       (cnt0),
    .cnt1_o       (cnt1)
    );




endmodule
