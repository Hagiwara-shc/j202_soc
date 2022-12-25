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
// Filename        : cmt_regs.v
// Description     : Compare match timer Configuration and Status registers
//
// Author          : Duong Nguyen
// Created On      : 9/9/2015
// History (Date, Changed By)
//
//////////////////////////////////////////////////////////////////////////////////
module cmt_regs
    (
    clk,
    rst_n,
    //--------------------------------------
    // Write inf
    wen_i, 
    wdata_i,
    addr_i,
    //--------------------------------------
    // Read inf
    ren_i, 
    rdata_o,
    //--------------------------------------
    // outputs
    cks0_o,
    cks1_o,
    set_cnt0_o,
    wdata_cnt0_o,
    set_cnt1_o,
    wdata_cnt1_o,
    const0_o,
    const1_o,
    cmt0_int_o,
    cmt1_int_o,
    str0_o,
    str1_o,    
    //--------------------------------------
    // inputs	
    cmf0_i,
    cmf1_i,
    cnt0_i,
    cnt1_i
    );
	
//-----------------------------------------------------------------------------
//Parameter	 
parameter	AW = 8;
parameter	DW = 32;
//-----------------------------------------------------------------------------
//Port
input                     clk;
input                     rst_n;
   
//--------------------------------------
//Write inf
input                     wen_i; 
input   [DW-1:0]          wdata_i;
input   [AW-1:0]          addr_i;
//--------------------------------------
//Read inf

input                     ren_i; 
output  [DW-1:0]          rdata_o;

//--------------------------------------
// outputs
output [1:0]              cks0_o;
output [1:0]              cks1_o;
output                    set_cnt0_o;
output [15:0]             wdata_cnt0_o;
output                    set_cnt1_o;
output [15:0]             wdata_cnt1_o;
output [15:0]             const0_o;
output [15:0]             const1_o;
output                    cmt0_int_o;
output                    cmt1_int_o;    
output                    str0_o;
output                    str1_o;

//--------------------------------------
// inputs	
input                     cmf0_i;
input                     cmf1_i;
input [15:0]              cnt0_i;
input [15:0]              cnt1_i;


//-----------------------------------------------------------------------------
//Internal variable

wire [31:0]               nxt_rdata;
reg  [31:0]               rdata;

wire                      cmstr_en;
wire                      cmstr_wen;
wire                      cmstr_ren;
wire [1:0]                cmstr;
wire [1:0]                cmstrdi;
wire [1:0]                cmstrdo;		
wire [31:0]               cmstrcpudo;

wire                      cmcsr0_en;
wire                      cmcsr0_ren;
wire                      cmcsr0_wen;
wire [6:0]                cmcsr0di;
wire [6:0]                cmcsr0do;
wire [6:0]                cmcsr0;
wire [31:0]               cmcsr0cpudo;
wire                      cmie0;
wire                      cmf0di;
wire                      cmf0do;

wire                      cmcsr1_en;
wire                      cmcsr1_ren;
wire                      cmcsr1_wen;
wire [6:0]                cmcsr1di;
wire [6:0]                cmcsr1do;
wire [6:0]                cmcsr1;
wire [31:0]               cmcsr1cpudo;
wire                      cmie1;
wire                      cmf1di;
wire                      cmf1do;

wire                      cmcnt0_en;
wire                      cmcnt0_wen;
wire                      cmcnt0_ren;
wire [15:0]               cmcnt0di;
wire [15:0]               cmcnt0do;
wire [31:0]               cmcnt0cpudo;

wire                      cmcnt1_en;
wire                      cmcnt1_wen;
wire                      cmcnt1_ren;
wire [15:0]               cmcnt1di;
wire [15:0]               cmcnt1do;
wire [31:0]               cmcnt1cpudo;

wire                      cmcor0_en;
wire                      cmcor0_wen;
wire                      cmcor0_ren;
wire [15:0]               cmcor0di;
wire [15:0]               cmcor0do;
wire [15:0]               cmcor0;
wire [31:0]               cmcor0cpudo;

wire                      cmcor1_en;
wire                      cmcor1_wen;
wire                      cmcor1_ren;
wire [15:0]               cmcor1di;
wire [15:0]               cmcor1do;
wire [15:0]               cmcor1;
wire [31:0]               cmcor1cpudo;

//-----------------------------------------------------------------------------
// Compare Match Timer start Register(cmstr) 
// Addr : 0x00
// Access : RW 
// Fields : [31:2] : Reserved 
//          [1] : str1
//          [0] : str0
assign cmstr_en = (addr_i == 8'b0000_0000);
assign cmstr_wen = cmstr_en & wen_i;
assign cmstr_ren = cmstr_en & ren_i;

cfg_reg	#(.DW(2'd2))	cmstr_reg
    (
    .clk      (clk),
    .rst_n    (rst_n),
    //--------------------------------------
    //cpu access
    .cpuren_i (cmstr_ren),
    .cpuwen_i (cmstr_wen),
    .cpudi_i  (cmstrdi),
    .cpudo_o  (cmstrdo),
    //--------------------------------------
    //Output of configuration register
    .reg_o    (cmstr),
    //--------------------------------------
    //Clear
    .clr_i    (1'b0)
    );
	
assign cmstrdi = wdata_i[1:0];
assign str0_o = cmstr[0];
assign str1_o = cmstr[1];
assign cmstrcpudo = {30'd0,cmstrdo};

	
//-----------------------------------------------------------------------------
// Compare match timer 0 control/status Register(cmcsr0)
// Addr : 0x04
// Access : R/W
// Fields : [31:8] : Reserved 
//          [7]  : cmf0
//          [6]  : cmie0
//          [5:2]  : Reserved
//          [1:0]  : cks0
assign cmcsr0_en = (addr_i == 8'b0000_0100);
assign cmcsr0_wen = cmcsr0_en & wen_i;
assign cmcsr0_ren = cmcsr0_en & ren_i;

cfg_reg	#(.DW(3'd7))	cmcsr0_reg
    (
    .clk        (clk),
    .rst_n      (rst_n),
    //--------------------------------------
    //cpu access
    .cpuren_i	(cmcsr0_ren),
    .cpuwen_i	(cmcsr0_wen),
    .cpudi_i	(cmcsr0di),
    .cpudo_o	(cmcsr0do),
    //--------------------------------------
    //Output of configuration register
    .reg_o      (cmcsr0),
    //--------------------------------------
    //Clear
    .clr_i      (1'b0)
    );
	
assign cmcsr0di= wdata_i[6:0];
assign cmcsr0cpudo = {24'd0,cmf0do,cmcsr0do};
assign cks0_o = cmcsr0[1:0];
assign cmie0 = cmcsr0[6];//timer0 interrupt enable

//Compare match flag of timer 0
int_status_reg	#(.DW(1'b1))	cmf0_reg //1bit
    (
     .clk       (clk),
     .rst_n     (rst_n),
     //--------------------------------------
     //cpu access
     .cpuren_i	(cmcsr0_ren),
     .cpuwen_i	(cmcsr0_wen),
     .cpudi_i	(cmf0di),
     .cpudo_o	(cmf0do),
     //--------------------------------------
     //Status signal from IP
     .status_i	(cmf0_i),//Timer0 match flag signal
     .clr_i     (1'b0)
     );

assign cmf0di = wdata_i[7];
//-----------------------------------------------------------------------------
// Compare match timer 1 control/status Register(cmcsr1)
// Addr : 0x08
// Access : R/W
// Fields : [31:8] : Reserved 
//          [7]  : cmf1
//          [6]  : cmie1
//          [5:2]  : Reserved
//          [1:0]  : cks1
assign cmcsr1_en = (addr_i == 8'b0000_1000);
assign cmcsr1_wen = cmcsr1_en & wen_i;
assign cmcsr1_ren = cmcsr1_en & ren_i;

cfg_reg	#(.DW(3'd7))	cmcsr1_reg
    (
    .clk        (clk),
    .rst_n      (rst_n),
    //--------------------------------------
    //cpu access
    .cpuren_i	(cmcsr1_ren),
    .cpuwen_i	(cmcsr1_wen),
    .cpudi_i	(cmcsr1di),
    .cpudo_o	(cmcsr1do),
    //--------------------------------------
    //Output of configuration register
    .reg_o      (cmcsr1),
    //--------------------------------------
    //Clear
    .clr_i      (1'b0)
    );
	
assign cmcsr1di= wdata_i[6:0];
assign cmcsr1cpudo = {24'd0,cmf1do,cmcsr1do};
assign cks1_o = cmcsr1[1:0];
assign cmie1 = cmcsr1[6];//timer0 interrupt enable

//Compare match flag of timer 1
int_status_reg	#(.DW(1'b1))	cmf1_reg //1bit
    (
     .clk       (clk),
     .rst_n     (rst_n),
     //--------------------------------------
     //cpu access
     .cpuren_i	(cmcsr1_ren),
     .cpuwen_i	(cmcsr1_wen),
     .cpudi_i	(cmf1di),
     .cpudo_o	(cmf1do),
     //--------------------------------------
     //Status signal from IP
     .status_i	(cmf1_i),//Timer1 match flag signal
     .clr_i     (1'b0)
     );

assign cmf1di = wdata_i[7];


//-----------------------------------------------------------------------------
// Compare match timer counter 0 (cmcnt0)
// Addr : 0x0C
// Access : R/W
// Fields : [31:16] : Reserved 
//          [15:0] : CNT_VALUE0
assign cmcnt0_en = (addr_i == 8'b0000_1100);
assign cmcnt0_wen = cmcnt0_en & wen_i;
assign cmcnt0_ren = cmcnt0_en & ren_i;

status_reg	#(.DW(5'd16))	cmcnt0_reg
    (
     .clk       (clk),
     .rst_n     (rst_n),
     //--------------------------------------
     //cpu access
     .cpuren_i	(cmcnt0_ren),
     .cpuwen_i	(cmcnt0_wen),
     .cpudi_i	(cmcnt0di),
     .cpudo_o	(cmcnt0do),
     //--------------------------------------
     //Status signal from IP
     .status_i	(cnt0_i),
     .clr_i     (1'b0)
     );

assign cmcnt0di = wdata_i[15:0];
assign cmcnt0cpudo = {16'd0,cmcnt0do};
assign set_cnt0_o = cmcnt0_wen;
assign wdata_cnt0_o = cmcnt0di;
//-----------------------------------------------------------------------------
// Compare match timer counter 1 (cmcnt1)
// Addr : 0x10
// Access : R/W
// Fields : [31:16] : Reserved 
//          [15:0] : CNT_VALUE1
assign cmcnt1_en = (addr_i == 8'b0001_0000);
assign cmcnt1_wen = cmcnt1_en & wen_i;
assign cmcnt1_ren = cmcnt1_en & ren_i;

status_reg	#(.DW(5'd16))	cmcnt1_reg
    (
     .clk       (clk),
     .rst_n     (rst_n),
     //--------------------------------------
     //cpu access
     .cpuren_i	(cmcnt1_ren),
     .cpuwen_i	(cmcnt1_wen),
     .cpudi_i	(cmcnt1di),
     .cpudo_o	(cmcnt1do),
     //--------------------------------------
     //Status signal from IP
     .status_i	(cnt1_i),
     .clr_i     (1'b0)
     );

assign cmcnt1di = wdata_i[15:0];
assign cmcnt1cpudo = {16'd0,cmcnt1do};
assign set_cnt1_o = cmcnt1_wen;
assign wdata_cnt1_o = cmcnt1di;
//-----------------------------------------------------------------------------
// Compare Match Timer const Register 0(cmcor0) 
// Addr : 0x14
// Access : RW 
// Fields : [31:16] : Reserved 
//          [15:0] : const0
assign cmcor0_en = (addr_i == 8'b0001_0100);
assign cmcor0_wen = cmcor0_en & wen_i;
assign cmcor0_ren = cmcor0_en & ren_i;

cfg_reg	#(.DW(5'd16))	cmcor0_reg
    (
    .clk      (clk),
    .rst_n    (rst_n),
    //--------------------------------------
    //cpu access
    .cpuren_i (cmcor0_ren),
    .cpuwen_i (cmcor0_wen),
    .cpudi_i  (cmcor0di),
    .cpudo_o  (cmcor0do),
    //--------------------------------------
    //Output of configuration register
    .reg_o    (cmcor0),
    //--------------------------------------
    //Clear
    .clr_i    (1'b0)
    );
	
assign cmcor0di = wdata_i[15:0];
assign cmcor0cpudo = {16'd0,cmcor0do};
assign const0_o = cmcor0;
//-----------------------------------------------------------------------------
// Compare Match Timer const Register 1(cmcor1) 
// Addr : 0x18
// Access : RW 
// Fields : [31:16] : Reserved 
//          [15:0] : const1
assign cmcor1_en = (addr_i == 8'b0001_1000);
assign cmcor1_wen = cmcor1_en & wen_i;
assign cmcor1_ren = cmcor1_en & ren_i;

cfg_reg	#(.DW(5'd16))	cmcor1_reg
    (
    .clk      (clk),
    .rst_n    (rst_n),
    //--------------------------------------
    //cpu access
    .cpuren_i (cmcor1_ren),
    .cpuwen_i (cmcor1_wen),
    .cpudi_i  (cmcor1di),
    .cpudo_o  (cmcor1do),
    //--------------------------------------
    //Output of configuration register
    .reg_o    (cmcor1),
    //--------------------------------------
    //Clear
    .clr_i    (1'b0)
    );
	
assign cmcor1di = wdata_i[15:0];
assign cmcor1cpudo = {16'd0,cmcor1do};
assign const1_o = cmcor1;

//-----------------------------------------------------------------------------
//Mux read data
assign nxt_rdata = cmstrcpudo | cmcsr0cpudo | cmcsr1cpudo | cmcnt0cpudo | 
                   cmcnt1cpudo | cmcor0cpudo | cmcor1cpudo;

always @ (posedge clk or negedge rst_n)
    begin
    if(!rst_n)
        rdata <= 32'd0;
    else
        rdata <= nxt_rdata;
    end

assign rdata_o = rdata; 
//-----------------------------------------------------------------------------
//Interrupt generation
assign cmt0_int_o = cmf0_i & cmie0;
assign cmt1_int_o = cmf1_i & cmie1;

endmodule
