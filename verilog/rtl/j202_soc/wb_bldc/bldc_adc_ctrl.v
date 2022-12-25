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
// Filename        : bldc_adc_ctrl.v
// Description     : control reading 6 ADC channels 
//					
//
// Author          : Duong Nguyen
// Created On      : 9/9/2015
// History (Date, Changed By)
//
//////////////////////////////////////////////////////////////////////////////////
module bldc_adc_ctrl
    (
    clk,
    rst_n,
    //--------------------------------------
    //ADC interface
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
    //Configuration interface
    adc_en_i,
    data_ch0_o,//chanel 0, Iu 
    data_ch1_o,//chanel 1, Iv 
    data_ch2_o,//chanel 2, Iw 
    data_ch3_o,//chanel 3, Vu 
    data_ch4_o,//chanel 4, Vv 
    data_ch5_o //chanel 5, Vw 
    );
//-----------------------------------------------------------------------------
//Parameter
parameter IDLE = 3'd0;
parameter CONVST = 3'd1;
parameter CONV = 3'd2;
parameter READ = 3'd3;
parameter HCONVST = 3'd4;

//-----------------------------------------------------------------------------
//Port
input                clk;
input                rst_n;
//--------------------------------------
//ADC interface
output               cmd_vld_o; //Command valid
output [4:0]         cmd_ch_o;// command channel
output               cmd_sop_o;
output               cmd_eop_o;
input                cmd_ready_i;//Command ready
input                rsp_sop_i;
input                rsp_eop_i;
input                rsp_vld_i;//Response valid
input [4:0]          rsp_ch_i;//Response channel
input [11:0]         rsp_data_i;//Response data
//--------------------------------------
//Configuration interface
input                adc_en_i;
output [11:0]        data_ch0_o;//chanel 0, Iu 
output [11:0]        data_ch1_o;//chanel 1, Iv 
output [11:0]        data_ch2_o;//chanel 2, Iw 
output [11:0]        data_ch3_o;//chanel 3, Vu 
output [11:0]        data_ch4_o;//chanel 4, Vv 
output [11:0]        data_ch5_o;//chanel 5, Vw 
//-----------------------------------------------------------------------------
//Internal variable
reg [11:0]           data_ch0_o;
reg [11:0]           data_ch1_o;
reg [11:0]           data_ch2_o;
reg [11:0]           data_ch3_o;
reg [11:0]           data_ch4_o;
reg [11:0]           data_ch5_o;
reg [4:0]            cmd_ch_o;

wire [4:0]           nxt_cmd_ch;
wire                 clr_cmd_ch;
wire                 cmd_ch_is5;
wire                 rsp_ch_is0;
wire                 rsp_ch_is1;
wire                 rsp_ch_is2;
wire                 rsp_ch_is3;
wire                 rsp_ch_is4;
wire                 rsp_ch_is5;
wire                 ch0_data_vld;
wire                 ch1_data_vld;
wire                 ch2_data_vld;
wire                 ch3_data_vld;
wire                 ch4_data_vld;
wire                 ch5_data_vld;
wire [11:0]          nxt_data_ch0;
wire [11:0]          nxt_data_ch1;
wire [11:0]          nxt_data_ch2;
wire [11:0]          nxt_data_ch3;
wire [11:0]          nxt_data_ch4;
wire [11:0]          nxt_data_ch5;

//-----------------------------------------------------------------------------
//Control valid, start of packet, end of packet
assign cmd_sop_o = 1'b1;//ignore in adc_control core
assign cmd_eop_o = 1'b1;//ignore in adc_control core
assign cmd_vld_o = adc_en_i;//Continuesed send command
//-----------------------------------------------------------------------------
//Control reading channel
assign clr_cmd_ch = cmd_ch_is5 & cmd_ready_i;
assign nxt_cmd_ch = clr_cmd_ch ? 5'd0 :
                    cmd_ready_i ? (cmd_ch_o + 1'b1) : cmd_ch_o;


always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        cmd_ch_o <= 5'd0;
    else  
        cmd_ch_o <= nxt_cmd_ch; 
    end

assign cmd_ch_is5 = (cmd_ch_o == 5'd5);
//-----------------------------------------------------------------------------
//Capture reading data
assign rsp_ch_is0 = (rsp_ch_i == 5'd0);
assign rsp_ch_is1 = (rsp_ch_i == 5'd1);
assign rsp_ch_is2 = (rsp_ch_i == 5'd2);
assign rsp_ch_is3 = (rsp_ch_i == 5'd3);
assign rsp_ch_is4 = (rsp_ch_i == 5'd4);
assign rsp_ch_is5 = (rsp_ch_i == 5'd5);
assign ch0_data_vld = rsp_ch_is0 & rsp_vld_i;
assign ch1_data_vld = rsp_ch_is1 & rsp_vld_i;
assign ch2_data_vld = rsp_ch_is2 & rsp_vld_i;
assign ch3_data_vld = rsp_ch_is3 & rsp_vld_i;
assign ch4_data_vld = rsp_ch_is4 & rsp_vld_i;
assign ch5_data_vld = rsp_ch_is5 & rsp_vld_i;
//-----------------------------------------------------------------------------
//Channel 0 Data
assign nxt_data_ch0 = ch0_data_vld ? rsp_data_i : data_ch0_o; 

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        data_ch0_o <= 12'd0;
    else  
        data_ch0_o <= nxt_data_ch0; 
    end
//-----------------------------------------------------------------------------
//Channel 1 Data
assign nxt_data_ch1 = ch1_data_vld ? rsp_data_i : data_ch1_o; 

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        data_ch1_o <= 12'd0;
    else  
        data_ch1_o <= nxt_data_ch1; 
    end
//-----------------------------------------------------------------------------
//Channel 2 Data
assign nxt_data_ch2 = ch2_data_vld ? rsp_data_i : data_ch2_o; 

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        data_ch2_o <= 12'd0;
    else  
        data_ch2_o <= nxt_data_ch2; 
    end
//-----------------------------------------------------------------------------
//Channel 3 Data
assign nxt_data_ch3 = ch3_data_vld ? rsp_data_i : data_ch3_o; 

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        data_ch3_o <= 12'd0;
    else  
        data_ch3_o <= nxt_data_ch3; 
    end
//-----------------------------------------------------------------------------
//Channel 4 Data
assign nxt_data_ch4 = ch4_data_vld ? rsp_data_i : data_ch4_o; 

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        data_ch4_o <= 12'd0;
    else  
        data_ch4_o <= nxt_data_ch4; 
    end
//-----------------------------------------------------------------------------
//Channel 4 Data
assign nxt_data_ch5 = ch5_data_vld ? rsp_data_i : data_ch5_o; 

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        data_ch5_o <= 12'd0;
    else  
        data_ch5_o <= nxt_data_ch5; 
    end

endmodule
