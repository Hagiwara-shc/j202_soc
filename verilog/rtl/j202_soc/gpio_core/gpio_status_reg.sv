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
//  SH Consulting
//
// Filename    : gpio_status_reg.sv
// Description : Latching status.
// Author      : duong nguyen
// Created On  : 9/9/2015
// History (Date, Changed By)
//
//////////////////////////////////////////////////////////////////////////////////
module gpio_status_reg
    (
     clk,
     rst,
     //--------------------------------------
     //cpu access
     ren_i, //read enable
     wen_i, //write enable
     di_i,// Input data from CPU
     reg_o,// Output data for CPU
     //--------------------------------------
     //Status signal from IP
     status_i,
     //--------------------------------------
     //Clear
     clr_i
     );
//-----------------------------------------------------------------------------
//Parameter	 
parameter DW = 8;
parameter RST_VAL = {DW{1'b0}};
//-----------------------------------------------------------------------------
//Port
input                     clk;
input                     rst;
input                     ren_i;  
input                     wen_i; 
input   [DW-1:0]          di_i; 
output  [DW-1:0]          reg_o;

input  [DW-1:0]           status_i;
input	                  clr_i;
//-----------------------------------------------------------------------------
//Internal variable
reg   [DW-1:0] 	          latch_status;
wire  [DW-1:0]            nxt_latch_status;
wire  [DW-1:0]            new_status;
//-----------------------------------------------------------------------------
//Logic implementation
assign new_status = latch_status | status_i;

assign nxt_latch_status = clr_i ? {DW{1'b0}} : 
                          wen_i ? (di_i | status_i) : new_status;

always @(posedge clk)
    begin
    if(rst)   
        latch_status <= RST_VAL;
    else  
        latch_status <= nxt_latch_status; 
    end 
	
assign reg_o = latch_status;

endmodule
