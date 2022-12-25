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
// Filename        : bldc_core.v
// Description     : bldc core based on Wishbone bus.
//                   
//					
//
// Author          : Duong Nguyen
// Created On      : 9/9/2015
// History (Date, Changed By)
//
//////////////////////////////////////////////////////////////////////////////////

module bldc_core
    (
    clk,//50mhz
    rst_n,
    //--------------------------------------
    //WB slave interface
    sel_i, 
    dat_i,   
    addr_i,   
    cyc_i,  
    we_i,   
    stb_i,    
    ack_o,   
    dat_o,   
    //--------------------------------------
    //output to inverter
    pwm_posa_o,
    pwm_nega_o,
    pwm_posb_o,
    pwm_negb_o,
    pwm_posc_o,
    pwm_negc_o,
    //--------------------------------------
    //Altera ADC interface
    cmd_vld_o, //Command valid
    cmd_ch_o, // command channel
    cmd_sop_o,
    cmd_eop_o,
    cmd_ready_i,//Command ready
    rsp_sop_i,
    rsp_eop_i,
    rsp_vld_i,//Response valid
    rsp_ch_i,//Response channel
    rsp_data_i,//Response data
    //--------------------------------------
    //interrupt
    bldc_int_o,
    //--------------------------------------
    //Hall sensor interface
    over_cur_i,//Over current
    hall_i
    );
//-----------------------------------------------------------------------------
//Parameter
parameter WB_DW  =  32;// data width
parameter WB_AW  =  32;// address width
	 
//-----------------------------------------------------------------------------
//Port
input                     clk;
input                     rst_n;
//--------------------------------------
//WB slave interface
input [3:0]               sel_i;
input [WB_DW-1:0]         dat_i;   
input [WB_AW-1:0]         addr_i;   
input                     cyc_i;
input                     we_i; 
input                     stb_i;    
output                    ack_o;   
output [WB_DW-1:0]        dat_o;   


//--------------------------------------
//output to PIN
output                    pwm_posa_o;
output                    pwm_nega_o;
output                    pwm_posb_o;
output                    pwm_negb_o;
output                    pwm_posc_o;
output                    pwm_negc_o;
//--------------------------------------
//ADC interface
output                    cmd_vld_o; //Command valid
output [4:0]              cmd_ch_o;// command channel
output                    cmd_sop_o;
output                    cmd_eop_o;
input                     cmd_ready_i;//Command ready
input                     rsp_sop_i;
input                     rsp_eop_i;
input                     rsp_vld_i;//Response valid
input [4:0]               rsp_ch_i;//Response channel
input [11:0]              rsp_data_i;//Response data
//--------------------------------------
//interrupt
output                    bldc_int_o;
//--------------------------------------
//Hall sensor interface
input [2:0]               hall_i;
input                     over_cur_i;
//-----------------------------------------------------------------------------
//Internal variables
wire [WB_AW-1:0]          addr;
wire [WB_DW-1:0]          wdata; 
wire [WB_DW-1:0]          rdata;
wire                      wen;
wire                      ren;

wire                      pwm_en;
wire                      adc_en;
wire                      pwm_en_ov;
wire [11:0]               pwm_duty;
wire [11:0]               pwm_period;
wire                      pwm_middle;
wire [2:0]                comm;
wire [2:0]                hall_value;
wire                      hall_int;
wire [11:0]               data_ch0;
wire [11:0]               data_ch1;
wire [11:0]               data_ch2;
wire [11:0]               data_ch3;
wire [11:0]               data_ch4;
wire [11:0]               data_ch5;
//-----------------------------------------------------------------------------
//Wishbone slave instance
bldc_wb_slave   bldc_wb_slave_00
    (
    .clk         (clk),
    .rst_n       (rst_n),
    //---------------------------------
    //Wishbone interface
    .sel_i       (sel_i),
    .dat_i       (dat_i),
    .addr_i      (addr_i),
    .cyc_i       (cyc_i),
    .we_i        (we_i),
    .stb_i       (stb_i),
    .ack_o       (ack_o),
    .dat_o       (dat_o),
    //---------------------------------
    //BLDC register interface
    .reg_wdata_o (wdata),
    .reg_wen_o   (wen),
    .reg_ren_o   (ren),
    .reg_addr_o  (addr),
    .reg_rdata_i (rdata)
    );
    
//-----------------------------------------------------------------------------
//Config and status instance
bldc_cfg_status_regs   bldc_cfg_status_regs_00
    (
    .clk          (clk),
    .rst_n        (rst_n),
    //--------------------------------------
    //Internal inf
    .addr_i       (addr),
    .wdata_i      (wdata), 
    .wen_i        (wen),
    .ren_i        (ren),
    .rdata_o      (rdata), 
    //--------------------------------------
    //Output config
    .pwm_en_o     (pwm_en),
    .adc_en_o     (adc_en),
    .pwm_duty_o   (pwm_duty),
    .pwm_period_o (pwm_period),
    .comm_o       (comm),//commutation control
    //--------------------------------------
    //interrupt
    .bldc_int_o   (bldc_int_o),
    //--------------------------------------
    //Input status
	.adc_ch0_data_i (data_ch0[11:0]),
    .adc_ch1_data_i (data_ch1[11:0]),
    .adc_ch2_data_i (data_ch2[11:0]),
    .hall_value_i   (hall_value),//Hall sensor value
    .hall_int_i     (hall_int)//Hall interrupt
    );


//-----------------------------------------------------------------------------
//Hall instance
bldc_hall   bldc_hall_00
    (
    .clk           (clk),
    .rst_n         (rst_n),
    //--------------------------------------
    //Hall sensor inputs
    .hall_data_i   (hall_i),
    //--------------------------------------
    //Hall sensor output
    .hall_data_o   (hall_value),
    .hall_change_o (hall_int)
    );

//-----------------------------------------------------------------------------
//PWM instance
bldc_pwm    bldc_pwm_00
    (
    .clk          (clk),//50mhz
    .rst_n        (rst_n),
    //--------------------------------------
    //output to PIN
    .pwm_posa_o   (pwm_posa_o),
    .pwm_nega_o   (pwm_nega_o),
    .pwm_posb_o   (pwm_posb_o),
    .pwm_negb_o   (pwm_negb_o),
    .pwm_posc_o   (pwm_posc_o),
    .pwm_negc_o   (pwm_negc_o),
    //--------------------------------------
    //to SPI
    .pwm_middle_o (pwm_middle),//indicate from the middle of pwm pulse to end pulse.
    //--------------------------------------
    //Configuration inf
    .pwm_duty_i   (pwm_duty),//Duty cycle
    .pwm_period_i (pwm_period),
    .pwm_en_i     (pwm_en_ov), //Enable
    .comm_i       (comm)//commutation control
    );

assign pwm_en_ov = pwm_en & (~over_cur_i);
//-----------------------------------------------------------------------------
//ADC reading control
bldc_adc_ctrl     bldc_adc_ctrl_00
    (
    .clk        (clk),
    .rst_n      (rst_n),
    //--------------------------------------
    //ADC interface
    .cmd_vld_o  (cmd_vld_o), //Command valid
    .cmd_ch_o   (cmd_ch_o), // command channel
    .cmd_sop_o  (cmd_sop_o),
    .cmd_eop_o  (cmd_eop_o),
    .cmd_ready_i(cmd_ready_i),//Command ready
    .rsp_sop_i  (rsp_sop_i),
    .rsp_eop_i  (rsp_eop_i),
    .rsp_vld_i  (rsp_vld_i),//Response valid
    .rsp_ch_i   (rsp_ch_i),//Response channel
    .rsp_data_i (rsp_data_i),//Response data
    //--------------------------------------
    //Configuration interface
    .adc_en_i   (adc_en),
    .data_ch0_o (data_ch0[11:0]),//chanel 0, Iu 
    .data_ch1_o (data_ch1[11:0]),//chanel 1, Iv 
    .data_ch2_o (data_ch2[11:0]),//chanel 2, Iw 
    .data_ch3_o (data_ch3[11:0]),//chanel 3, Vu 
    .data_ch4_o (data_ch4[11:0]),//chanel 4, Vv 
    .data_ch5_o (data_ch5[11:0]) //chanel 5, Vw 
    );

endmodule
