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
// Filename        : bldc_hall.v
// Description     : Capturing new hall sensor value
//					
//
// Author          : Duong Nguyen
// Created On      : 9/9/2015
// History (Date, Changed By)
//
//////////////////////////////////////////////////////////////////////////////////
module bldc_hall
    (
    clk,
    rst_n,
    //--------------------------------------
    //Hall sensor inputs
    hall_data_i,
    //--------------------------------------
    //Hall sensor output
    hall_data_o,
    hall_change_o
    );
//-----------------------------------------------------------------------------
//Parameter

//-----------------------------------------------------------------------------
//Port
input                clk;
input                rst_n;
//--------------------------------------
//Hall sensor inputs
input [2:0]          hall_data_i;
//--------------------------------------
//Hall sensor output
output [2:0]         hall_data_o;
output               hall_change_o;
//-----------------------------------------------------------------------------
//Internal variable
reg [2:0]            hall_data_o;

reg [2:0]            hall_data_1;
reg [2:0]            hall_data_2;
reg [2:0]            hall_data_3;
wire [2:0]           nxt_hall_data;
wire                 latch_data_en;
reg                  latch_data_en_1;
reg                  latch_data_en_2;
//-----------------------------------------------------------------------------
//Pipeline input data
always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        hall_data_1 <= 3'd0;
    else  
        hall_data_1 <= hall_data_i; 
    end
always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        hall_data_2 <= 3'd0;
    else  
        hall_data_2 <= hall_data_1; 
    end
always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        hall_data_3 <= 3'd0;
    else  
        hall_data_3 <= hall_data_2; 
    end
//-----------------------------------------------------------------------------
//Capturing new data when it is stable
assign latch_data_en = (hall_data_3 == hall_data_1) & (|hall_data_3);
assign nxt_hall_data = latch_data_en ? hall_data_3 : hall_data_o;

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        hall_data_o <= 3'd0;
    else  
        hall_data_o <= nxt_hall_data; 
    end
//-----------------------------------------------------------------------------
//Generating interrupt status pulse when hall sensor value change to new value.
always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        latch_data_en_1 <= 1'd0;
    else  
        latch_data_en_1 <= latch_data_en; 
    end
always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        latch_data_en_2 <= 1'd0;
    else  
        latch_data_en_2 <= latch_data_en_1; 
    end

assign hall_change_o = (~latch_data_en_2) & latch_data_en_1;

endmodule
