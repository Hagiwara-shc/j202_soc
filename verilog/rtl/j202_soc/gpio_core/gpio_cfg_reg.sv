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
// Filename        : gpio_cfg_reg.sv
// Description     : Read/Write configuration register
//
// Author          : Duong Nguyen
// Created On      : 9/9/2015
// History (Date, Changed By)
//
//////////////////////////////////////////////////////////////////////////////////
module gpio_cfg_reg
    (
    clk,
    rst,
    //--------------------------------------
    //cpu access
    ren_i,  	//read enable
    wen_i,  	//write enable
    di_i,  	// Input data from CPU
    //--------------------------------------
    //Output of configuration register
    reg_o,
    //--------------------------------------
    //Clear
    clr_i
     );
//-----------------------------------------------------------------------------
//Parameter	 
parameter	DW = 8;
parameter 	RST_VAL = {DW{1'b0}};
//-----------------------------------------------------------------------------
//Port
input                   clk;
input                   rst;
input                   ren_i;  
input                   wen_i; 
input   [DW-1:0]        di_i; 

output  [DW-1:0]        reg_o;
input			clr_i;
//-----------------------------------------------------------------------------
//Internal variable
reg    [DW-1:0]         reg_o;
wire    [DW-1:0]        nxt_reg;

//-----------------------------------------------------------------------------
//Logic implementation
assign nxt_reg = clr_i ? RST_VAL : 
                 wen_i ? di_i : 
                 reg_o;

always @(posedge clk)
    begin
    if(rst)   
        reg_o <= RST_VAL;
    else  
        reg_o <= nxt_reg; 
    end 
	
endmodule
