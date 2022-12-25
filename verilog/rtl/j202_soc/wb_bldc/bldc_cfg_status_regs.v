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
// Filename        : bldc_cfg_status_regs.v
// Description     : Configuration and status registers.
//                   
//					
//
// Author          : Duong Nguyen
// Created On      : 9/9/2015
// History (Date, Changed By)
//
//////////////////////////////////////////////////////////////////////////////////
module bldc_cfg_status_regs
    (
    clk,
    rst_n,
    //--------------------------------------
    //Internal inf
    addr_i,
    wdata_i, 
    wen_i,
    ren_i, 
    rdata_o, 
    //--------------------------------------
    //Output config
    pwm_en_o,
    adc_en_o,
    pwm_duty_o,
    pwm_period_o,
    comm_o,//commutation control
    //--------------------------------------
    //interrupt
    bldc_int_o,
    //--------------------------------------
    //Input status
    adc_ch0_data_i,
    adc_ch1_data_i,
    adc_ch2_data_i,
    hall_value_i,//Hall sensor value
    hall_int_i//Hall interrupt
    );
//-----------------------------------------------------------------------------
//Parameter
parameter ADDR_W = 6'd32;
parameter DATA_W = 6'd32;

parameter PPR_W  = 5'd24;
parameter PDCR_W = 2'd2;
parameter HSVR_W = 4'd3;
parameter CCR_W  = 2'd3;
parameter BISR_W = 2'd1;
parameter BIER_W = 2'd1;
parameter BICR_W = 2'd1;
parameter AC0DR_W = 4'd12;

//-----------------------------------------------------------------------------
//Port
input                clk;
input                rst_n;
//--------------------------------------
//Internal interface
input [ADDR_W-1:0]   addr_i;
input [DATA_W-1:0]   wdata_i; 
input                wen_i; 
input                ren_i; 
output [DATA_W-1:0]  rdata_o; 
//--------------------------------------
//Output config
output               pwm_en_o;
output               adc_en_o;
output [11:0]        pwm_duty_o;
output [11:0]        pwm_period_o;
output [2:0]         comm_o;
//--------------------------------------
//interrupt
output               bldc_int_o;
//--------------------------------------
//Input status
input [11:0]         adc_ch0_data_i;
input [11:0]         adc_ch1_data_i;
input [11:0]         adc_ch2_data_i;
input [2:0]          hall_value_i;
input                hall_int_i;
//-----------------------------------------------------------------------------
//Internal variable
reg                  bldc_int_o;


wire                 ppr_addr_vld;
wire                 ppr_wen;
wire                 ppr_ren;
wire                 ppr_clr;
wire  [PPR_W-1:0]    ppr_di;       
wire  [PPR_W-1:0]    ppr_do;       
wire  [PPR_W-1:0]    ppr;       
wire  [31:0]         ppr_cpudo;     

wire                 pdcr_addr_vld;
wire                 pdcr_wen;
wire                 pdcr_ren;
wire                 pdcr_clr;
wire  [PDCR_W-1:0]   pdcr_di;       
wire  [PDCR_W-1:0]   pdcr_do;       
wire  [PDCR_W-1:0]   pdcr;       
wire  [31:0]         pdcr_cpudo;    

wire                 hsvr_addr_vld;
wire                 hsvr_wen;
wire                 hsvr_ren;
wire                 hsvr_clr;
wire  [HSVR_W-1:0]   hsvr_di;       
wire  [HSVR_W-1:0]   hsvr_do;       
wire  [HSVR_W-1:0]   hsvr_status;       
wire  [31:0]         hsvr_cpudo;    
 
wire                 ccr_addr_vld;
wire                 ccr_wen;
wire                 ccr_ren;
wire                 ccr_clr;
wire  [CCR_W-1:0]    ccr_di;       
wire  [CCR_W-1:0]    ccr_do;       
wire  [CCR_W-1:0]    ccr;       
wire  [31:0]         ccr_cpudo;  

wire                 bisr_addr_vld;
wire                 bisr_wen;
wire                 bisr_ren;
wire                 bisr_clr;
wire  [BISR_W-1:0]   bisr_di;       
wire  [BISR_W-1:0]   bisr_do;       
wire  [31:0]         bisr_cpudo;  
wire                 hall_int;
wire                 bisr_status;

wire                 bier_addr_vld;
wire                 bier_wen;
wire                 bier_ren;
wire                 bier_clr;
wire  [BIER_W-1:0]   bier_di;       
wire  [BIER_W-1:0]   bier_do;       
wire  [BIER_W-1:0]   bier;       
wire  [31:0]         bier_cpudo;
  
  
wire                 bicr_addr_vld;
wire                 bicr_wen;
reg                  bicr_wen_1;
wire                 bicr_ren;
wire                 bicr_clr;
wire  [BICR_W-1:0]   bicr_di;       
wire  [BICR_W-1:0]   bicr_do;       
wire  [BICR_W-1:0]   bicr;       

wire                 ac0dr_addr_vld;
wire                 ac0dr_wen;
wire                 ac0dr_ren;
wire                 ac0dr_clr;
wire  [AC0DR_W-1:0]  ac0dr_di;       
wire  [AC0DR_W-1:0]  ac0dr_do;       
wire  [AC0DR_W-1:0]  ac0dr_status;       
wire  [31:0]         ac0dr_cpudo; 

wire                 ac1dr_addr_vld;
wire                 ac1dr_wen;
wire                 ac1dr_ren;
wire                 ac1dr_clr;
wire  [AC0DR_W-1:0]  ac1dr_di;       
wire  [AC0DR_W-1:0]  ac1dr_do;       
wire  [AC0DR_W-1:0]  ac1dr_status;       
wire  [31:0]         ac1dr_cpudo; 

wire                 ac2dr_addr_vld;
wire                 ac2dr_wen;
wire                 ac2dr_ren;
wire                 ac2dr_clr;
wire  [AC0DR_W-1:0]  ac2dr_di;       
wire  [AC0DR_W-1:0]  ac2dr_do;       
wire  [AC0DR_W-1:0]  ac2dr_status;       
wire  [31:0]         ac2dr_cpudo; 


wire                 nxt_bldc_int; 
//-----------------------------------------------------------------------------
// PWM period register (ppr) 
// Addr : 0x00
// Access : RW 
// Fields : [31:12] : Reserved 
//          [23:12]  : DUTY
//          [11:0]  : PERIOD
assign ppr_addr_vld = (addr_i[7:0] == 8'b0000_0000);
assign ppr_wen = ppr_addr_vld & wen_i;
assign ppr_ren = ppr_addr_vld & ren_i;

cfg_reg	#(.DW(PPR_W))	ppr_00
    (
    .clk      (clk),
    .rst_n    (rst_n),
    //--------------------------------------
    //cpu access
    .cpuren_i (ppr_ren),
    .cpuwen_i (ppr_wen),
    .cpudi_i  (ppr_di),
    .cpudo_o  (ppr_do),
    //--------------------------------------
    //Output of configuration register
    .reg_o    (ppr),
    //--------------------------------------
    //Clear
    .clr_i    (ppr_clr)
    );
assign ppr_di = wdata_i[23:0];
assign pwm_period_o = ppr[11:0];
assign pwm_duty_o = ppr[23:12];
assign ppr_clr = 1'b0;
assign ppr_cpudo = {8'd0,ppr_do};


//-----------------------------------------------------------------------------
// BLDC control register (bcr) 
// Addr : 0x04
// Access : RW 
// Fields : [31:13] : Reserved 
//          [12:1] : DUTY
//          [0] : PWM_EN
assign pdcr_addr_vld = (addr_i[7:0] == 8'b0000_0100);
assign pdcr_wen = pdcr_addr_vld & wen_i;
assign pdcr_ren = pdcr_addr_vld & ren_i;

cfg_reg	#(.DW(PDCR_W))	bcr_00
    (
    .clk      (clk),
    .rst_n    (rst_n),
    //--------------------------------------
    //cpu access
    .cpuren_i (pdcr_ren),
    .cpuwen_i (pdcr_wen),
    .cpudi_i  (pdcr_di),
    .cpudo_o  (pdcr_do),
    //--------------------------------------
    //Output of configuration register
    .reg_o    (pdcr),
    //--------------------------------------
    //Clear
    .clr_i    (pdcr_clr)
    );
assign pdcr_di = wdata_i[1:0];
assign pwm_en_o = pdcr[0];
assign adc_en_o = pdcr[1];
assign pdcr_clr = 1'b0;
assign pdcr_cpudo = {30'd0,pdcr_do};
//-----------------------------------------------------------------------------
// Hall sensor value register (hsvr) 
// Addr : 0x08
// Access : RW
// Fields : [31:3] : Reserved 
//          [2:0] : HALL_VALUE
assign hsvr_addr_vld = (addr_i[7:0] == 8'b0000_1000);
assign hsvr_wen = hsvr_addr_vld & wen_i;
assign hsvr_ren = hsvr_addr_vld & ren_i;

status_reg   #(.DW(HSVR_W))  hsvr_00
    (
     .clk       (clk),
     .rst_n     (rst_n),
     //--------------------------------------
     //cpu access
     .cpuren_i	(hsvr_ren),
     .cpuwen_i	(hsvr_wen),
     .cpudi_i	(hsvr_di),
     .cpudo_o	(hsvr_do),
     //--------------------------------------
     //Status signal from IP
     .status_i	(hsvr_status),
     .clr_i     (hsvr_clr)
     );
assign hsvr_status = hall_value_i; 
assign hsvr_di = wdata_i[2:0];
assign hsvr_clr = 1'b0;
assign hsvr_cpudo = {29'd0,hsvr_do};
//-----------------------------------------------------------------------------
// commutation control register (ccr) 
// Addr : 0x0C
// Access : RW
// Fields : [31:3] : Reserved 
//          [2:0] : COMM
assign ccr_addr_vld = (addr_i[7:0] == 8'b0000_1100);
assign ccr_wen = ccr_addr_vld & wen_i;
assign ccr_ren = ccr_addr_vld & ren_i;

cfg_reg	#(.DW(CCR_W))	ccr_00
    (
    .clk      (clk),
    .rst_n    (rst_n),
    //--------------------------------------
    //cpu access
    .cpuren_i (ccr_ren),
    .cpuwen_i (ccr_wen),
    .cpudi_i  (ccr_di),
    .cpudo_o  (ccr_do),
    //--------------------------------------
    //Output of configuration register
    .reg_o    (ccr),
    //--------------------------------------
    //Clear
    .clr_i    (ccr_clr)
    );
assign ccr_di = wdata_i[2:0];
assign comm_o = ccr;
assign ccr_clr = 1'b0;
assign ccr_cpudo = {29'd0,ccr_do};
//-----------------------------------------------------------------------------
// BLDC Interrupt Status Register(bisr)
// Addr : 0x10
// Access : R only
// Fields : [31:1] : Reserved 
//          [0] : HALL_STATUS

assign bisr_addr_vld = (addr_i[7:0] == 8'b0001_0000);
assign bisr_wen = bicr_wen_1;//Write when writting 1 to interrupt cleared reg.
assign bisr_ren = bisr_addr_vld & ren_i;

int_status_reg	#(.DW(BISR_W))	bisr_00
    (
     .clk       (clk),
     .rst_n     (rst_n),
     //--------------------------------------
     //cpu access
     .cpuren_i	(bisr_ren),
     .cpuwen_i	(bisr_wen | bisr_clr),
     .cpudi_i	(bisr_di),
     .cpudo_o	(bisr_do),
     //--------------------------------------
     //Status signal from IP
     .status_i	(bisr_status),
     .clr_i     (bisr_clr)
     );

assign hall_int = hall_int_i & bier[0]; 
assign bisr_status = hall_int;
assign bisr_di = ((~bicr) & bisr_do);
assign bisr_cpudo = {31'd0,bisr_do};
assign bisr_clr = 1'b0;
//-----------------------------------------------------------------------------
// BLDC Interrupt enable Register(bier)
// Addr : 0x14
// Access : RW
// Fields : [31:9] : Reserved 
//          [0] : HALL_EN
assign bier_addr_vld = (addr_i[7:0] == 8'b0001_0100);
assign bier_wen = bier_addr_vld & wen_i;
assign bier_ren = bier_addr_vld & ren_i;

cfg_reg	#(.DW(BIER_W))	bier_00
    (
    .clk      (clk),
    .rst_n    (rst_n),
    //--------------------------------------
    //cpu access
    .cpuren_i (bier_ren),
    .cpuwen_i (bier_wen),
    .cpudi_i  (bier_di),
    .cpudo_o  (bier_do),
    //--------------------------------------
    //Output of configuration register
    .reg_o    (bier),
    //--------------------------------------
    //Clear
    .clr_i    (bier_clr)
    );
assign bier_di = wdata_i[0];
assign bier_clr = 1'b0;
assign bier_cpudo = {31'd0,bier_do};
//-----------------------------------------------------------------------------
// BLDC Interrupt Clear Register(bicr)
// Addr : 0x18
// Access : W only
// Fields :[31:1]	: Reserved 
//         [0] : HALL_CLR
assign bicr_addr_vld = (addr_i[7:0] == 8'b0001_1000);
assign bicr_wen = bicr_addr_vld & wen_i;
assign bicr_ren = bicr_addr_vld & ren_i;

cfg_reg	#(.DW(BICR_W))	bicr_00
    (
    .clk      (clk),
    .rst_n    (rst_n),
    //--------------------------------------
    //cpu access
    .cpuren_i (bicr_ren),
    .cpuwen_i (bicr_wen),
    .cpudi_i  (bicr_di),
    .cpudo_o  (bicr_do),
    //--------------------------------------
    //Output of configuration register
    .reg_o    (bicr),
    //--------------------------------------
    //Clear
    .clr_i    (bicr_clr)
    );
assign bicr_di = wdata_i[0];
assign bicr_clr = bicr_wen_1;//clear all bits


always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        bicr_wen_1 <= 1'b0;
    else  
        bicr_wen_1 <= bicr_wen; 
    end
//-----------------------------------------------------------------------------
// ADC channel 0 data Register(ac0dr)
// Addr : 0x1C
// Access : RW only
// Fields :[31:12] : Reserved 
//         [11:0]  : CH0_DATA
assign ac0dr_addr_vld = (addr_i[7:0] == 8'b0001_1100);
assign ac0dr_wen = ac0dr_addr_vld & wen_i;
assign ac0dr_ren = ac0dr_addr_vld & ren_i;

status_reg   #(.DW(AC0DR_W))  ac0dr_00
    (
     .clk       (clk),
     .rst_n     (rst_n),
     //--------------------------------------
     //cpu access
     .cpuren_i	(ac0dr_ren),
     .cpuwen_i	(ac0dr_wen),
     .cpudi_i	(ac0dr_di),
     .cpudo_o	(ac0dr_do),
     //--------------------------------------
     //Status signal from IP
     .status_i	(ac0dr_status),
     .clr_i     (ac0dr_clr)
     );

assign ac0dr_status = adc_ch0_data_i;
assign ac0dr_di = wdata_i[11:0];
assign ac0dr_clr = 1'b0;
assign ac0dr_cpudo = {20'd0,ac0dr_do};
//-----------------------------------------------------------------------------
// ADC channel 1 data Register(ac1dr)
// Addr : 0x20
// Access : RW only
// Fields :[31:12] : Reserved 
//         [11:0]  : CH1_DATA
assign ac1dr_addr_vld = (addr_i[7:0] == 8'b0010_0000);
assign ac1dr_wen = ac1dr_addr_vld & wen_i;
assign ac1dr_ren = ac1dr_addr_vld & ren_i;

status_reg   #(.DW(AC0DR_W))  ac1dr_00
    (
     .clk       (clk),
     .rst_n     (rst_n),
     //--------------------------------------
     //cpu access
     .cpuren_i	(ac1dr_ren),
     .cpuwen_i	(ac1dr_wen),
     .cpudi_i	(ac1dr_di),
     .cpudo_o	(ac1dr_do),
     //--------------------------------------
     //Status signal from IP
     .status_i	(ac1dr_status),
     .clr_i     (ac1dr_clr)
     );

assign ac1dr_status = adc_ch1_data_i;
assign ac1dr_di = wdata_i[11:0];
assign ac1dr_clr = 1'b0;
assign ac1dr_cpudo = {20'd0,ac1dr_do};
//-----------------------------------------------------------------------------
// ADC channel 2 data Register(ac2dr)
// Addr : 0x24
// Access : RW only
// Fields :[31:12] : Reserved 
//         [11:0]  : CH2_DATA
assign ac2dr_addr_vld = (addr_i[7:0] == 8'b0010_0100);
assign ac2dr_wen = ac2dr_addr_vld & wen_i;
assign ac2dr_ren = ac2dr_addr_vld & ren_i;

status_reg   #(.DW(AC0DR_W))  ac2dr_00
    (
     .clk       (clk),
     .rst_n     (rst_n),
     //--------------------------------------
     //cpu access
     .cpuren_i	(ac2dr_ren),
     .cpuwen_i	(ac2dr_wen),
     .cpudi_i	(ac2dr_di),
     .cpudo_o	(ac2dr_do),
     //--------------------------------------
     //Status signal from IP
     .status_i	(ac2dr_status),
     .clr_i     (ac2dr_clr)
     );

assign ac2dr_status = adc_ch2_data_i;
assign ac2dr_di = wdata_i[11:0];
assign ac2dr_clr = 1'b0;
assign ac2dr_cpudo = {20'd0,ac2dr_do};
//-----------------------------------------------------------------------------
//Read data is returned after 1 clk
assign rdata_o = ppr_cpudo | pdcr_cpudo | hsvr_cpudo | ccr_cpudo |
                 bisr_cpudo | bier_cpudo | ac0dr_cpudo | ac1dr_cpudo |
                 ac2dr_cpudo;				 
//-----------------------------------------------------------------------------
//Interrupt output control
assign nxt_bldc_int = bicr_wen_1 ? 1'b0 : (|bisr_do);

always @ (posedge clk or negedge rst_n)
    begin
    if(!rst_n)
        bldc_int_o <= 1'd0;
    else
        bldc_int_o <= nxt_bldc_int;
    end

endmodule
