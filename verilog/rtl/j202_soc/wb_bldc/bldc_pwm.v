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
// Filename        : bldc_pwm.v
// Description     : PWM and commutation module.
//                   PWM period is 50us,
//					
//
// Author          : Duong Nguyen
// Created On      : 9/9/2015
// History (Date, Changed By)
//
//////////////////////////////////////////////////////////////////////////////////
module bldc_pwm
    (
    clk,//50mhz
    rst_n,
    //--------------------------------------
    //output to PIN
    pwm_posa_o,
    pwm_nega_o,
    pwm_posb_o,
    pwm_negb_o,
    pwm_posc_o,
    pwm_negc_o,
    //--------------------------------------
    //to SPI
    pwm_middle_o,//indicate from the middle of pwm pulse to end pulse.
    //--------------------------------------
    //Configuration inf
    pwm_period_i,//PWM period
    pwm_duty_i,//Duty cycle
    pwm_en_i, //Enable
    comm_i//commutation control
    );
//-----------------------------------------------------------------------------
//Parameter
parameter DUTY_DW = 4'd12;
	 
//-----------------------------------------------------------------------------
//Port
input                clk;
input                rst_n;
//--------------------------------------
//output to PIN
output               pwm_posa_o;
output               pwm_nega_o;
output               pwm_posb_o;
output               pwm_negb_o;
output               pwm_posc_o;
output               pwm_negc_o;
//--------------------------------------
//to SPI
output               pwm_middle_o;
//--------------------------------------
//Configuration inf
input [DUTY_DW-1:0]  pwm_period_i;
input [DUTY_DW-1:0]  pwm_duty_i;//Duty cycle
input                pwm_en_i; //Enable
input [2:0]          comm_i;
//-----------------------------------------------------------------------------
//Internal variable
reg                  pwm_posa_o;
reg                  pwm_nega_o;
reg                  pwm_posb_o;
reg                  pwm_negb_o;
reg                  pwm_posc_o;
reg                  pwm_negc_o;
wire                 nxt_pwm_posa; 
wire                 nxt_pwm_nega; 
wire                 nxt_pwm_posb; 
wire                 nxt_pwm_negb; 
wire                 nxt_pwm_posc; 
wire                 nxt_pwm_negc; 
wire [11:0]          nxt_clkcnt;
reg  [11:0]          clkcnt;
wire                 set_clkcnt_to1;
wire                 set_duty_vld;
wire                 clr_duty_vld;
wire                 nxt_duty_vld;
reg                  duty_vld;
wire                 posa_negb;
wire                 posa_negc;
wire                 posb_negc;
wire                 posb_nega;
wire                 posc_nega;
wire                 posc_negb;
wire [DUTY_DW-1:0]   duty_div2;
wire                 nxt_pwm_middle;
reg                  pwm_middle_o;
wire                 clr_pwm_middle;
wire                 set_pwm_middle;


//-----------------------------------------------------------------------------
//PWM logic
assign set_clkcnt_to1 = (clkcnt == pwm_period_i);
assign nxt_clkcnt = set_clkcnt_to1 ? 12'd1 : (clkcnt + 1'b1);

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        clkcnt <= 12'd0;
    else  
        clkcnt <= nxt_clkcnt; 
    end
//Duty cycle control
assign set_duty_vld = set_clkcnt_to1 & pwm_en_i;
assign clr_duty_vld = (clkcnt == pwm_duty_i);
assign nxt_duty_vld = set_duty_vld ?  1'b1 :
                      clr_duty_vld ? 1'b0 : duty_vld;

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        duty_vld <= 1'b0;
    else  
        duty_vld <= nxt_duty_vld; 
    end
//-----------------------------------------------------------------------------
//Commutation logic
assign posa_negb = (comm_i == 3'b001);//u+ -> v-
assign posa_negc = (comm_i == 3'b010);//u+ -> w-
assign posb_negc = (comm_i == 3'b011);//v+ -> w-
assign posb_nega = (comm_i == 3'b100);//v+ -> u-
assign posc_nega = (comm_i == 3'b101);//w+ -> u-
assign posc_negb = (comm_i == 3'b110);//w+ -> v-

assign nxt_pwm_posa = (posa_negb | posa_negc) ? duty_vld : 1'b0; 
assign nxt_pwm_nega = (posb_nega | posc_nega) ? duty_vld : 1'b0; 

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        pwm_posa_o <= 1'b0;
    else  
        pwm_posa_o <= nxt_pwm_posa; 
    end
always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        pwm_nega_o <= 1'b0;
    else  
        pwm_nega_o <= nxt_pwm_nega; 
    end

assign nxt_pwm_posb = (posb_nega | posb_negc) ? duty_vld : 1'b0; 
assign nxt_pwm_negb = (posa_negb | posc_negb) ? duty_vld : 1'b0; 

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        pwm_posb_o <= 1'b0;
    else  
        pwm_posb_o <= nxt_pwm_posb; 
    end
always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        pwm_negb_o <= 1'b0;
    else  
        pwm_negb_o <= nxt_pwm_negb; 
    end

assign nxt_pwm_posc = (posc_nega | posc_negb) ? duty_vld : 1'b0; 
assign nxt_pwm_negc = (posa_negc | posb_negc) ? duty_vld : 1'b0; 

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        pwm_posc_o <= 1'b0;
    else  
        pwm_posc_o <= nxt_pwm_posc; 
    end
always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        pwm_negc_o <= 1'b0;
    else  
        pwm_negc_o <= nxt_pwm_negc; 
    end
//-----------------------------------------------------------------------------
//Enable zero crossing checking at middle of pwm pulse
assign duty_div2 = {1'b0,pwm_duty_i[DUTY_DW-1:1]};
assign set_pwm_middle = (clkcnt == duty_div2) & duty_vld;
assign clr_pwm_middle = ~duty_vld;
assign nxt_pwm_middle = clr_pwm_middle ? 1'b0 :
                        set_pwm_middle ? 1'b1 : pwm_middle_o;

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        pwm_middle_o <= 1'b0;
    else  
        pwm_middle_o <= nxt_pwm_middle; 
    end

endmodule
