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
// Filename        : cmt_2ch.v
// Description     : Compare match timer (2 channel)
//					
//
// Author          : Duong Nguyen
// Created On      : 9/9/2015
// History (Date, Changed By)
//
//////////////////////////////////////////////////////////////////////////////////
module cmt_2ch
    (
    clk,//50mhz
    rst_n,
    //--------------------------------------
    //Configuration inf
    str0_i,//start timer0   
    str1_i,//start timer1
    cks0_i,//select clock(:8,:32,:128,:512) for timer0
    cks1_i,//select clock(:8,:32,:128,:512) for timer1
    const0_i,//constant value of timer0
    const1_i,//constant value of timer0
    set_cnt0_i,
    wdata_cnt0_i,
    set_cnt1_i,
    wdata_cnt1_i,
    cmf0_o,//timer0 match pulse
    cmf1_o,//timer1 match pulse
    cnt0_o,
    cnt1_o
    );
//-----------------------------------------------------------------------------
//Parameter

//-----------------------------------------------------------------------------
//Port
input                clk;
input                rst_n;

input                str0_i;//start timer0   
input                str1_i;//start timer1
input  [1:0]         cks0_i;//select clock(:8,:32,:128,:512) for timer0
input  [1:0]         cks1_i;//select clock(:8,:32,:128,:512) for timer1
input  [15:0]        const0_i;//constant value of timer0
input  [15:0]        const1_i;//constant value of timer0
input                set_cnt0_i;
input  [15:0]        wdata_cnt0_i;
input                set_cnt1_i;
input  [15:0]        wdata_cnt1_i;
output               cmf0_o;//timer0 match pulse
output               cmf1_o;//timer1 match pulse
output [15:0]        cnt0_o;
output [15:0]        cnt1_o;

//-----------------------------------------------------------------------------
//Internal variable
reg                  cmf0_o;
reg                  cmf1_o;
wire                 nxt_cmf0;
wire                 nxt_cmf1;



wire [9:0]           nxt_clkcnt0;
reg  [9:0]           clkcnt0;
wire                 t0_div8_en;
wire                 t0_div32_en;
wire                 t0_div128_en;
wire                 t0_div512_en;
wire [15:0]          nxt_cmpcnt0;
reg  [15:0]          cmpcnt0;
wire                 set_clkcnt0_to1;
wire                 clkcnt0_is8;
wire                 clkcnt0_is32;
wire                 clkcnt0_is128;
wire                 clkcnt0_is512;
wire                 set_cmpcnt0_to1;
wire                 inc_cmpcnt0;
wire                 clkcnt0_mux_sel0;
wire                 clkcnt0_mux_sel1;
wire                 clkcnt0_mux_sel2;
wire                 cmpcnt0_mux_sel0;
wire                 cmpcnt0_mux_sel1;
wire                 cmpcnt0_mux_sel2;
wire                 cmpcnt0_mux_sel3;

wire [9:0]           nxt_clkcnt1;
reg  [9:0]           clkcnt1;
wire                 t1_div8_en;
wire                 t1_div32_en;
wire                 t1_div128_en;
wire                 t1_div512_en;
wire [15:0]          nxt_cmpcnt1;
reg  [15:0]          cmpcnt1;
wire                 set_clkcnt1_to1;
wire                 clkcnt1_is8;
wire                 clkcnt1_is32;
wire                 clkcnt1_is128;
wire                 clkcnt1_is512;
wire                 set_cmpcnt1_to1;
wire                 inc_cmpcnt1;
wire                 clkcnt1_mux_sel0;
wire                 clkcnt1_mux_sel1;
wire                 clkcnt1_mux_sel2;
wire                 cmpcnt1_mux_sel0;
wire                 cmpcnt1_mux_sel1;
wire                 cmpcnt1_mux_sel2;
wire                 cmpcnt1_mux_sel3;
//-----------------------------------------------------------------------------
// timer0

assign t0_div8_en = (cks0_i == 2'b00);
assign t0_div32_en = (cks0_i == 2'b01);
assign t0_div128_en = (cks0_i == 2'b10);
assign t0_div512_en = (cks0_i == 2'b11);
assign set_clkcnt0_to1 = clkcnt0_is8 | clkcnt0_is32 | clkcnt0_is128 | 
                         clkcnt0_is512 | set_cnt0_i; 
/*
assign nxt_clkcnt0 = set_clkcnt0_to1 ? 10'd1 :
                     str0_i ? (clkcnt0 + 1'b1) : clkcnt0;
*/
assign clkcnt0_mux_sel0 = set_clkcnt0_to1;
assign clkcnt0_mux_sel1 = str0_i & (~clkcnt0_mux_sel0);
assign clkcnt0_mux_sel2 = (~clkcnt0_mux_sel0) & (~clkcnt0_mux_sel1);


mux3  #(.DW(4'd10))  clkcnt0_mux
    (
    .sel0 (clkcnt0_mux_sel0),
    .in0  (10'd1),
    //-------------------
    .sel1 (clkcnt0_mux_sel1),
    .in1  (clkcnt0 + 1'b1),
    //-------------------
    .sel2 (clkcnt0_mux_sel2),
    .in2  (clkcnt0),
    //-------------------
    .out  (nxt_clkcnt0)
    );

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        clkcnt0 <= 10'd0;
    else  
        clkcnt0 <= nxt_clkcnt0; 
    end
assign clkcnt0_is8 = (clkcnt0 == 10'd8) & t0_div8_en;
assign clkcnt0_is32 = (clkcnt0 == 10'd32) & t0_div32_en;
assign clkcnt0_is128 = (clkcnt0 == 10'd128) & t0_div128_en;
assign clkcnt0_is512 = (clkcnt0 == 10'd512) & t0_div512_en;

assign set_cmpcnt0_to1 = nxt_cmf0;
assign inc_cmpcnt0 = set_clkcnt0_to1;
/*
assign nxt_cmpcnt0 = set_cnt0_i ? wdata_cnt0_i :
                     set_cmpcnt0_to1 ? 16'd1 :
                     inc_cmpcnt0 ? (cmpcnt0 + 1'b1) : cmpcnt0;
*/
assign cmpcnt0_mux_sel0 = set_cnt0_i;
assign cmpcnt0_mux_sel1 = set_cmpcnt0_to1 & (~cmpcnt0_mux_sel0);
assign cmpcnt0_mux_sel2 = inc_cmpcnt0 & (~cmpcnt0_mux_sel0) & 
                          (~cmpcnt0_mux_sel1);
assign cmpcnt0_mux_sel3 = (~cmpcnt0_mux_sel0) & (~cmpcnt0_mux_sel1) &
                          (~cmpcnt0_mux_sel2);


mux4  #(.DW(5'd16))  cmpcnt0_mux
    (
    .sel0 (cmpcnt0_mux_sel0),
    .in0  (wdata_cnt0_i),
    //-------------------
    .sel1 (cmpcnt0_mux_sel1),
    .in1  (16'd1),
    //-------------------
    .sel2 (cmpcnt0_mux_sel2),
    .in2  (cmpcnt0 + 1'b1),
    //-------------------
    .sel3 (cmpcnt0_mux_sel3),
    .in3  (cmpcnt0),
    //-------------------
    .out  (nxt_cmpcnt0)
    );

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        cmpcnt0 <= 16'd1;
    else  
        cmpcnt0 <= nxt_cmpcnt0; 
    end
//-----------------------------------------------------------------------------
// timer1

assign t1_div8_en = (cks1_i == 2'b00);
assign t1_div32_en = (cks1_i == 2'b01);
assign t1_div128_en = (cks1_i == 2'b10);
assign t1_div512_en = (cks1_i == 2'b11);
assign set_clkcnt1_to1 = clkcnt1_is8 | clkcnt1_is32 | clkcnt1_is128 | 
                         clkcnt1_is512 | set_cnt1_i; 
/*
assign nxt_clkcnt1 = set_clkcnt1_to1 ? 10'd1 :
                     str1_i ? (clkcnt1 + 1'b1) : clkcnt1;
*/
assign clkcnt1_mux_sel0 = set_clkcnt1_to1;
assign clkcnt1_mux_sel1 = str1_i & (~clkcnt1_mux_sel0);
assign clkcnt1_mux_sel2 = (~clkcnt1_mux_sel0) & (~clkcnt1_mux_sel1);


mux3  #(.DW(4'd10))  clkcnt1_mux
    (
    .sel0 (clkcnt1_mux_sel0),
    .in0  (10'd1),
    //-------------------
    .sel1 (clkcnt1_mux_sel1),
    .in1  (clkcnt1 + 1'b1),
    //-------------------
    .sel2 (clkcnt1_mux_sel2),
    .in2  (clkcnt1),
    //-------------------
    .out  (nxt_clkcnt1)
    );
 
always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        clkcnt1 <= 10'd0;
    else  
        clkcnt1 <= nxt_clkcnt1; 
    end
assign clkcnt1_is8 = (clkcnt1 == 10'd8) & t1_div8_en;
assign clkcnt1_is32 = (clkcnt1 == 10'd32) & t1_div32_en;
assign clkcnt1_is128 = (clkcnt1 == 10'd128) & t1_div128_en;
assign clkcnt1_is512 = (clkcnt1 == 10'd512) & t1_div512_en;

assign set_cmpcnt1_to1 = nxt_cmf1;
assign inc_cmpcnt1 = set_clkcnt1_to1;
/*
assign nxt_cmpcnt1 = set_cnt1_i ? wdata_cnt1_i :
                     set_cmpcnt1_to1 ? 16'd1 :
                     inc_cmpcnt1 ? (cmpcnt1 + 1'b1) : cmpcnt1;
*/
assign cmpcnt1_mux_sel0 = set_cnt1_i;
assign cmpcnt1_mux_sel1 = set_cmpcnt1_to1 & (~cmpcnt1_mux_sel0);
assign cmpcnt1_mux_sel2 = inc_cmpcnt1 & (~cmpcnt1_mux_sel0) & 
                          (~cmpcnt1_mux_sel1);
assign cmpcnt1_mux_sel3 = (~cmpcnt1_mux_sel0) & (~cmpcnt1_mux_sel1) &
                          (~cmpcnt1_mux_sel2);


mux4  #(.DW(5'd16))  cmpcnt1_mux
    (
    .sel0 (cmpcnt1_mux_sel0),
    .in0  (wdata_cnt1_i),
    //-------------------
    .sel1 (cmpcnt1_mux_sel1),
    .in1  (16'd1),
    //-------------------
    .sel2 (cmpcnt1_mux_sel2),
    .in2  (cmpcnt1 + 1'b1),
    //-------------------
    .sel3 (cmpcnt1_mux_sel3),
    .in3  (cmpcnt1),
    //-------------------
    .out  (nxt_cmpcnt1)
    );

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        cmpcnt1 <= 16'd1;
    else  
        cmpcnt1 <= nxt_cmpcnt1; 
    end
//-----------------------------------------------------------------------------
//Interrupt generation
assign nxt_cmf0 = (cmpcnt0 == const0_i) & set_clkcnt0_to1;

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        cmf0_o <= 1'b0;
    else  
        cmf0_o <= nxt_cmf0; 
    end

assign nxt_cmf1 = (cmpcnt1 == const1_i) & set_clkcnt1_to1;

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        cmf1_o <= 1'b0;
    else  
        cmf1_o <= nxt_cmf1; 
    end

assign cnt0_o = cmpcnt0;
assign cnt1_o = cmpcnt1;


endmodule
