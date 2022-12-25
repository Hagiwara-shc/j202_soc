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

//----------------------------------------------------------------------------- 
//SH consulting
//File Name		: regnb.v
//Description	: N bits Refister
//
//Author		: duongnguyen
//Created On	: 11/30/2015
//-----------------------------------------------------------------------------
module	regnb
    (
    clk,
    rst_n,	
    //-----------------------------
    //Write
    wen_i,//Write enable
    wdata_i,//write data
    clr_i,
    //-----------------------------
    //Read
    ren_i,//Read en
    rdata_o//Read data
    );


//-----------------------------------------------------------------------------
//Parameters
parameter    DW = 8;
//-----------------------------------------------------------------------------
//Port declaration
input          clk;
input          rst_n;	
//-----------------------------
//Write
input          wen_i;//Write enable
input [DW-1:0] wdata_i;//write data
input          clr_i;
//-----------------------------
//Read
input          ren_i;//Read enable
output [DW-1:0]rdata_o;//Read data

//-----------------------------------------------------------------------------
//Internal variables
reg [DW-1:0]   data;
wire [DW-1:0]  nxt_data;

//-----------------------------------------------------------------------------
//Write
always@(posedge clk or negedge rst_n)
    begin
    if (!rst_n)
        data <= {DW{1'b0}};
    else
        data <= nxt_data;
    end
//-----------------------------------------------------------------------------
//Read
assign nxt_data = clr_i ? {DW{1'b0}} :
                  wen_i ? wdata_i : data;
assign rdata_o = ren_i ? data : {DW{1'b0}};

endmodule	
