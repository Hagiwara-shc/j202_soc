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
// Filename        : cfg_reg.v
// Description     : Read/Write configuration register
//
// Author          : Duong Nguyen
// Created On      : 9/9/2015
// History (Date, Changed By)
//
//////////////////////////////////////////////////////////////////////////////////
module cfg_reg
    (
    clk,
    rst_n,
    //--------------------------------------
    //cpu access
    cpuren_i,  	//read enable
    cpuwen_i,  	//write enable
    cpudi_i,  	// Input data from CPU
    cpudo_o,	// Output data for CPU
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
input                   rst_n;
input                   cpuren_i;  
input                   cpuwen_i; 
input   [DW-1:0]        cpudi_i; 
output  [DW-1:0]        cpudo_o;

output  [DW-1:0]        reg_o;
input			clr_i;
//-----------------------------------------------------------------------------
//Internal variable
reg    [DW-1:0]         reg_o;
wire    [DW-1:0]        nxt_reg;

//-----------------------------------------------------------------------------
//Logic implementation
assign cpudo_o = cpuren_i ? reg_o : {DW{1'b0}};
assign nxt_reg = clr_i ? RST_VAL : 
                 cpuwen_i ? cpudi_i : 
                 reg_o;

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        reg_o <= RST_VAL;
    else  
        reg_o <= nxt_reg; 
    end 
	
endmodule
////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : dffa_rstn.v
// Description : D flip flop with asynchronous active low reset signal
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module dffa_rstn
    (
    clk,
    rst_n,
    din,
    dout
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               clk;
input               rst_n;
input [DW-1:0]	    din;
output [DW-1:0]	    dout;
//------------------------------------------------------------------------------
//internal signal
reg  [DW-1:0]	    dout;
//------------------------------------------------------------------------------
// FF
always @ (posedge clk or negedge rst_n)
    begin
    if(!rst_n)
        dout <= {DW{1'b0}};
    else
        dout <= din;
    end

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : dff_rstn.v
// Description : D flip flop with synchronous reset signal (active low)
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module dff_rstn
    (
    clk,
    rst_n,
    din,
    dout
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               clk;
input               rst_n;
input [DW-1:0]	    din;
output [DW-1:0]	    dout;
//------------------------------------------------------------------------------
//internal signal
reg  [DW-1:0]	    dout;
//------------------------------------------------------------------------------
// FF
always @ (posedge clk)
    begin
    if(!rst_n)
        dout <= {DW{1'b0}};
    else
        dout <= din;
    end

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : dff_rst.v
// Description : D flip flop with synchronous reset signal (active high)
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module dff_rst
    (
    clk,
    rst,
    din,
    dout
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
parameter RST_VL = {DW{1'b0}};
//------------------------------------------------------------------------------
// Port declarations
input               clk;
input               rst;
input [DW-1:0]	    din;
output [DW-1:0]	    dout;
//------------------------------------------------------------------------------
//internal signal
reg  [DW-1:0]	    dout;
//------------------------------------------------------------------------------
// FF
always @(posedge clk)
    begin
    if(rst)
        dout <= RST_VL;
    else
        dout <= din;
    end

endmodule 

//////////////////////////////////////////////////////////////////////////////////
//  SH Consulting
//
// Filename    : int_status_reg.v
// Description : Latching interrupt status of the design.
// Author      : duong nguyen
// Created On  : 9/9/2015
// History (Date, Changed By)
//
//////////////////////////////////////////////////////////////////////////////////
module int_status_reg
    (
     clk,
     rst_n,
     //--------------------------------------
     //cpu access
     cpuren_i, //read enable
     cpuwen_i, //write enable
     cpudi_i,// Input data from CPU
     cpudo_o,// Output data for CPU
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
input                     rst_n;
input                     cpuren_i;  
input                     cpuwen_i; 
input   [DW-1:0]          cpudi_i; 
output  [DW-1:0]          cpudo_o;

input  [DW-1:0]           status_i;
input	                  clr_i;
//-----------------------------------------------------------------------------
//Internal variable
wire  [DW-1:0] 	          sts_or_latch_sts;
wire  [DW-1:0]            wdata_or_sts;
reg   [DW-1:0] 	          latch_status;
wire  [DW-1:0]            nxt_latch_status;

//-----------------------------------------------------------------------------
//Logic implementation
assign sts_or_latch_sts = status_i | latch_status;
assign wdata_or_sts = (latch_status & cpudi_i) | status_i;// write 0 to clear
assign nxt_latch_status = cpuwen_i ? wdata_or_sts : 
                          clr_i ? {DW{1'b0}} :
                          sts_or_latch_sts;
assign cpudo_o = cpuren_i ? latch_status : {DW{1'b0}};

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        latch_status <= RST_VAL;
    else  
        latch_status <= nxt_latch_status; 
    end 
	
endmodule
////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : mux10
// Description : 10:1 parallel mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module mux10
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    sel4,
    in4,
    //-------------------
    sel5,
    in5,
    //-------------------
    sel6,
    in6,
    //-------------------
    sel7,
    in7,
    //-------------------
    sel8,
    in8,
    //-------------------
    sel9,
    in9,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
input               sel4;
input [DW-1:0]	    in4;
//
input               sel5;
input [DW-1:0]	    in5;
//
input               sel6;
input [DW-1:0]	    in6;
//
input               sel7;
input [DW-1:0]	    in7;
//
input               sel8;
input [DW-1:0]	    in8;
//
input               sel9;
input [DW-1:0]	    in9;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal
wire [DW-1:0]       out04;
wire [DW-1:0]       out59;
//------------------------------------------------------------------------------
//Mux 5:1
mux5   #(.DW(DW))   mux5_0 
    (
    .sel0  (sel0),
    .in0   (in0),
    //-------------------
    .sel1  (sel1),
    .in1   (in1),
    //-------------------
    .sel2  (sel2),
    .in2   (in2),
    //-------------------
    .sel3  (sel3),
    .in3   (in3),
    //-------------------
    .sel4  (sel4),
    .in4   (in4),
    //-------------------
    .out   (out04)
    );
//------------------------------------------------------------------------------
//Mux 5:1
mux5   #(.DW(DW))   mux5_1 
    (
    .sel0  (sel5),
    .in0   (in5),
    //-------------------
    .sel1  (sel6),
    .in1   (in6),
    //-------------------
    .sel2  (sel7),
    .in2   (in7),
    //-------------------
    .sel3  (sel8),
    .in3   (in8),
    //-------------------
    .sel4  (sel9),
    .in4   (in9),
    //-------------------
    .out   (out59)
    );
//------------------------------------------------------------------------------
//Mux 2:1
assign out = out04 | out59;

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : mux12.v
// Description : 12:1 parallel mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module mux12
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    sel4,
    in4,
    //-------------------
    sel5,
    in5,
    //-------------------
    sel6,
    in6,
    //-------------------
    sel7,
    in7,
    //-------------------
    sel8,
    in8,
    //-------------------
    sel9,
    in9,
    //-------------------
    sel10,
    in10,
    //-------------------
    sel11,
    in11,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
input               sel4;
input [DW-1:0]	    in4;
//
input               sel5;
input [DW-1:0]	    in5;
//
input               sel6;
input [DW-1:0]	    in6;
//
input               sel7;
input [DW-1:0]	    in7;
//
input               sel8;
input [DW-1:0]	    in8;
//
input               sel9;
input [DW-1:0]	    in9;
//
input               sel10;
input [DW-1:0]	    in10;
//
input               sel11;
input [DW-1:0]	    in11;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal
wire [DW-1:0]       out0_5;
wire [DW-1:0]       out6_11;
//------------------------------------------------------------------------------
//Mux 6:1
mux6   #(.DW(DW))   mux0_5
    (
    .sel0  (sel0),
    .in0   (in0),
    //-------------------
    .sel1  (sel1),
    .in1   (in1),
    //-------------------
    .sel2  (sel2),
    .in2   (in2),
    //-------------------
    .sel3  (sel3),
    .in3   (in3),
    //-------------------
    .sel4  (sel4),
    .in4   (in4),
    //-------------------
    .sel5  (sel5),
    .in5   (in5),
    //-------------------
    .out   (out0_5)
    );
//------------------------------------------------------------------------------
//Mux 6:1
mux6   #(.DW(DW))   mux6_11
    (
    .sel0  (sel6),
    .in0   (in6),
    //-------------------
    .sel1  (sel7),
    .in1   (in7),
    //-------------------
    .sel2  (sel8),
    .in2   (in8),
    //-------------------
    .sel3  (sel9),
    .in3   (in9),
    //-------------------
    .sel4  (sel10),
    .in4   (in10),
    //-------------------
    .sel5  (sel11),
    .in5   (in11),
    //-------------------
    .out   (out6_11)
    );
//------------------------------------------------------------------------------
//Mux 2:1
assign out = out0_5 | out6_11;

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : mux13.v
// Description : 13:1 parallel mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module mux13
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    sel4,
    in4,
    //-------------------
    sel5,
    in5,
    //-------------------
    sel6,
    in6,
    //-------------------
    sel7,
    in7,
    //-------------------
    sel8,
    in8,
    //-------------------
    sel9,
    in9,
    //-------------------
    sel10,
    in10,
    //-------------------
    sel11,
    in11,
    //-------------------
    sel12,
    in12,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
input               sel4;
input [DW-1:0]	    in4;
//
input               sel5;
input [DW-1:0]	    in5;
//
input               sel6;
input [DW-1:0]	    in6;
//
input               sel7;
input [DW-1:0]	    in7;
//
input               sel8;
input [DW-1:0]	    in8;
//
input               sel9;
input [DW-1:0]	    in9;
//
input               sel10;
input [DW-1:0]	    in10;
//
input               sel11;
input [DW-1:0]	    in11;
//
input               sel12;
input [DW-1:0]	    in12;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal
wire [DW-1:0]       out0_5;
wire [DW-1:0]       out6_12;
//------------------------------------------------------------------------------
//Mux 6:1
mux6   #(.DW(DW))   mux0_5
    (
    .sel0  (sel0),
    .in0   (in0),
    //-------------------
    .sel1  (sel1),
    .in1   (in1),
    //-------------------
    .sel2  (sel2),
    .in2   (in2),
    //-------------------
    .sel3  (sel3),
    .in3   (in3),
    //-------------------
    .sel4  (sel4),
    .in4   (in4),
    //-------------------
    .sel5  (sel5),
    .in5   (in5),
    //-------------------
    .out   (out0_5)
    );
//------------------------------------------------------------------------------
//Mux 7:1
mux7   #(.DW(DW))   mux6_12
    (
    .sel0  (sel6),
    .in0   (in6),
    //-------------------
    .sel1  (sel7),
    .in1   (in7),
    //-------------------
    .sel2  (sel8),
    .in2   (in8),
    //-------------------
    .sel3  (sel9),
    .in3   (in9),
    //-------------------
    .sel4  (sel10),
    .in4   (in10),
    //-------------------
    .sel5  (sel11),
    .in5   (in11),
    //-------------------
    .sel6  (sel12),
    .in6   (in12),
    //-------------------
    .out   (out6_12)
    );
//------------------------------------------------------------------------------
//Mux 2:1
assign out = out0_5 | out6_12;

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : mux16.v
// Description : 16:1 parallel mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module mux16
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    sel4,
    in4,
    //-------------------
    sel5,
    in5,
    //-------------------
    sel6,
    in6,
    //-------------------
    sel7,
    in7,
    //-------------------
    sel8,
    in8,
    //-------------------
    sel9,
    in9,
    //-------------------
    sel10,
    in10,
    //-------------------
    sel11,
    in11,
    //-------------------
    sel12,
    in12,
    //-------------------
    sel13,
    in13,
    //-------------------
    sel14,
    in14,
    //-------------------
    sel15,
    in15,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
input               sel4;
input [DW-1:0]	    in4;
//
input               sel5;
input [DW-1:0]	    in5;
//
input               sel6;
input [DW-1:0]	    in6;
//
input               sel7;
input [DW-1:0]	    in7;
//
input               sel8;
input [DW-1:0]	    in8;
//
input               sel9;
input [DW-1:0]	    in9;
//
input               sel10;
input [DW-1:0]	    in10;
//
input               sel11;
input [DW-1:0]	    in11;
//
input               sel12;
input [DW-1:0]	    in12;
//
input               sel13;
input [DW-1:0]	    in13;
//
input               sel14;
input [DW-1:0]	    in14;
//
input               sel15;
input [DW-1:0]	    in15;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal
wire [DW-1:0]       out0_7;
wire [DW-1:0]       out8_15;
//------------------------------------------------------------------------------
//Mux 8:1
mux8   #(.DW(DW))   mux0_7
    (
    .sel0  (sel0),
    .in0   (in0),
    //-------------------
    .sel1  (sel1),
    .in1   (in1),
    //-------------------
    .sel2  (sel2),
    .in2   (in2),
    //-------------------
    .sel3  (sel3),
    .in3   (in3),
    //-------------------
    .sel4  (sel4),
    .in4   (in4),
    //-------------------
    .sel5  (sel5),
    .in5   (in5),
    //-------------------
    .sel6  (sel6),
    .in6   (in6),
    //-------------------
    .sel7  (sel7),
    .in7   (in7),
    //-------------------
    .out   (out0_7)
    );
//------------------------------------------------------------------------------
//Mux 8:1
mux8   #(.DW(DW))   mux8_15
    (
    .sel0  (sel8),
    .in0   (in8),
    //-------------------
    .sel1  (sel9),
    .in1   (in9),
    //-------------------
    .sel2  (sel10),
    .in2   (in10),
    //-------------------
    .sel3  (sel11),
    .in3   (in11),
    //-------------------
    .sel4  (sel12),
    .in4   (in12),
    //-------------------
    .sel5  (sel13),
    .in5   (in13),
    //-------------------
    .sel6  (sel14),
    .in6   (in14),
    //-------------------
    .sel7  (sel15),
    .in7   (in15),
    //-------------------
    .out   (out8_15)
    );
//------------------------------------------------------------------------------
//Mux 2:1
assign out = out0_7 | out8_15;

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : mux20.v
// Description : 20:1 parallel mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module mux20
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    sel4,
    in4,
    //-------------------
    sel5,
    in5,
    //-------------------
    sel6,
    in6,
    //-------------------
    sel7,
    in7,
    //-------------------
    sel8,
    in8,
    //-------------------
    sel9,
    in9,
    //-------------------
    sel10,
    in10,
    //-------------------
    sel11,
    in11,
    //-------------------
    sel12,
    in12,
    //-------------------
    sel13,
    in13,
    //-------------------
    sel14,
    in14,
    //-------------------
    sel15,
    in15,
    //-------------------
    sel16,
    in16,
    //-------------------
    sel17,
    in17,
    //-------------------
    sel18,
    in18,
    //-------------------
    sel19,
    in19,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
input               sel4;
input [DW-1:0]	    in4;
//
input               sel5;
input [DW-1:0]	    in5;
//
input               sel6;
input [DW-1:0]	    in6;
//
input               sel7;
input [DW-1:0]	    in7;
//
input               sel8;
input [DW-1:0]	    in8;
//
input               sel9;
input [DW-1:0]	    in9;
//
input               sel10;
input [DW-1:0]	    in10;
//
input               sel11;
input [DW-1:0]	    in11;
//
input               sel12;
input [DW-1:0]	    in12;
//
input               sel13;
input [DW-1:0]	    in13;
//
input               sel14;
input [DW-1:0]	    in14;
//
input               sel15;
input [DW-1:0]	    in15;
//
input               sel16;
input [DW-1:0]	    in16;
//
input               sel17;
input [DW-1:0]	    in17;
//
input               sel18;
input [DW-1:0]	    in18;
//
input               sel19;
input [DW-1:0]	    in19;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal
wire [DW-1:0]       out0_9;
wire [DW-1:0]       out10_19;
//------------------------------------------------------------------------------
//Mux 10:1
mux10   #(.DW(DW))   mux0_9
    (
    .sel0  (sel0),
    .in0   (in0),
    //-------------------
    .sel1  (sel1),
    .in1   (in1),
    //-------------------
    .sel2  (sel2),
    .in2   (in2),
    //-------------------
    .sel3  (sel3),
    .in3   (in3),
    //-------------------
    .sel4  (sel4),
    .in4   (in4),
    //-------------------
    .sel5  (sel5),
    .in5   (in5),
    //-------------------
    .sel6  (sel6),
    .in6   (in6),
    //-------------------
    .sel7  (sel7),
    .in7   (in7),
    //-------------------
    .sel8  (sel8),
    .in8   (in8),
    //-------------------
    .sel9  (sel9),
    .in9   (in9),
    //-------------------
    .out   (out0_9)
    );
//------------------------------------------------------------------------------
//Mux 10:1
mux10   #(.DW(DW))   mux10_19
    (
    .sel0  (sel10),
    .in0   (in10),
    //-------------------
    .sel1  (sel11),
    .in1   (in11),
    //-------------------
    .sel2  (sel12),
    .in2   (in12),
    //-------------------
    .sel3  (sel13),
    .in3   (in13),
    //-------------------
    .sel4  (sel14),
    .in4   (in14),
    //-------------------
    .sel5  (sel15),
    .in5   (in15),
    //-------------------
    .sel6  (sel16),
    .in6   (in16),
    //-------------------
    .sel7  (sel17),
    .in7   (in17),
    //-------------------
    .sel8  (sel18),
    .in8   (in18),
    //-------------------
    .sel9  (sel19),
    .in9   (in19),
    //-------------------
    .out   (out10_19)
    );
//------------------------------------------------------------------------------
//Mux 2:1
assign out = out0_9 | out10_19;

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : mux24.v
// Description : 24:1 parallel mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module mux24
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    sel4,
    in4,
    //-------------------
    sel5,
    in5,
    //-------------------
    sel6,
    in6,
    //-------------------
    sel7,
    in7,
    //-------------------
    sel8,
    in8,
    //-------------------
    sel9,
    in9,
    //-------------------
    sel10,
    in10,
    //-------------------
    sel11,
    in11,
    //-------------------
    sel12,
    in12,
    //-------------------
    sel13,
    in13,
    //-------------------
    sel14,
    in14,
    //-------------------
    sel15,
    in15,
    //-------------------
    sel16,
    in16,
    //-------------------
    sel17,
    in17,
    //-------------------
    sel18,
    in18,
    //-------------------
    sel19,
    in19,
    //-------------------
    sel20,
    in20,
    //-------------------
    sel21,
    in21,
    //-------------------
    sel22,
    in22,
    //-------------------
    sel23,
    in23,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
input               sel4;
input [DW-1:0]	    in4;
//
input               sel5;
input [DW-1:0]	    in5;
//
input               sel6;
input [DW-1:0]	    in6;
//
input               sel7;
input [DW-1:0]	    in7;
//
input               sel8;
input [DW-1:0]	    in8;
//
input               sel9;
input [DW-1:0]	    in9;
//
input               sel10;
input [DW-1:0]	    in10;
//
input               sel11;
input [DW-1:0]	    in11;
//
input               sel12;
input [DW-1:0]	    in12;
//
input               sel13;
input [DW-1:0]	    in13;
//
input               sel14;
input [DW-1:0]	    in14;
//
input               sel15;
input [DW-1:0]	    in15;
//
input               sel16;
input [DW-1:0]	    in16;
//
input               sel17;
input [DW-1:0]	    in17;
//
input               sel18;
input [DW-1:0]	    in18;
//
input               sel19;
input [DW-1:0]	    in19;
//
input               sel20;
input [DW-1:0]	    in20;
//
input               sel21;
input [DW-1:0]	    in21;
//
input               sel22;
input [DW-1:0]	    in22;
//
input               sel23;
input [DW-1:0]	    in23;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal
wire [DW-1:0]       out0_11;
wire [DW-1:0]       out12_23;
//------------------------------------------------------------------------------
//Mux 12:1
mux12   #(.DW(DW))   mux0_11
    (
    .sel0  (sel0),
    .in0   (in0),
    //-------------------
    .sel1  (sel1),
    .in1   (in1),
    //-------------------
    .sel2  (sel2),
    .in2   (in2),
    //-------------------
    .sel3  (sel3),
    .in3   (in3),
    //-------------------
    .sel4  (sel4),
    .in4   (in4),
    //-------------------
    .sel5  (sel5),
    .in5   (in5),
    //-------------------
    .sel6  (sel6),
    .in6   (in6),
    //-------------------
    .sel7  (sel7),
    .in7   (in7),
    //-------------------
    .sel8  (sel8),
    .in8   (in8),
    //-------------------
    .sel9  (sel9),
    .in9   (in9),
    //-------------------
    .sel10  (sel10),
    .in10   (in10),
    //-------------------
    .sel11  (sel11),
    .in11   (in11),
    //-------------------
    .out   (out0_11)
    );
//------------------------------------------------------------------------------
//Mux 10:1
mux12   #(.DW(DW))   mux12_23
    (
    .sel0  (sel12),
    .in0   (in12),
    //-------------------
    .sel1  (sel13),
    .in1   (in13),
    //-------------------
    .sel2  (sel14),
    .in2   (in14),
    //-------------------
    .sel3  (sel15),
    .in3   (in15),
    //-------------------
    .sel4  (sel16),
    .in4   (in16),
    //-------------------
    .sel5  (sel17),
    .in5   (in17),
    //-------------------
    .sel6  (sel18),
    .in6   (in18),
    //-------------------
    .sel7  (sel19),
    .in7   (in19),
    //-------------------
    .sel8  (sel20),
    .in8   (in20),
    //-------------------
    .sel9  (sel21),
    .in9   (in21),
    //-------------------
    .sel10  (sel22),
    .in10   (in22),
    //-------------------
    .sel11  (sel23),
    .in11   (in23),
    //-------------------
    .out   (out12_23)
    );
//------------------------------------------------------------------------------
//Mux 2:1
assign out = out0_11 | out12_23;

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : mux26.v
// Description : 26:1 parallel mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module mux26
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    sel4,
    in4,
    //-------------------
    sel5,
    in5,
    //-------------------
    sel6,
    in6,
    //-------------------
    sel7,
    in7,
    //-------------------
    sel8,
    in8,
    //-------------------
    sel9,
    in9,
    //-------------------
    sel10,
    in10,
    //-------------------
    sel11,
    in11,
    //-------------------
    sel12,
    in12,
    //-------------------
    sel13,
    in13,
    //-------------------
    sel14,
    in14,
    //-------------------
    sel15,
    in15,
    //-------------------
    sel16,
    in16,
    //-------------------
    sel17,
    in17,
    //-------------------
    sel18,
    in18,
    //-------------------
    sel19,
    in19,
    //-------------------
    sel20,
    in20,
    //-------------------
    sel21,
    in21,
    //-------------------
    sel22,
    in22,
    //-------------------
    sel23,
    in23,
    //-------------------
    sel24,
    in24,
    //-------------------
    sel25,
    in25,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
input               sel4;
input [DW-1:0]	    in4;
//
input               sel5;
input [DW-1:0]	    in5;
//
input               sel6;
input [DW-1:0]	    in6;
//
input               sel7;
input [DW-1:0]	    in7;
//
input               sel8;
input [DW-1:0]	    in8;
//
input               sel9;
input [DW-1:0]	    in9;
//
input               sel10;
input [DW-1:0]	    in10;
//
input               sel11;
input [DW-1:0]	    in11;
//
input               sel12;
input [DW-1:0]	    in12;
//
input               sel13;
input [DW-1:0]	    in13;
//
input               sel14;
input [DW-1:0]	    in14;
//
input               sel15;
input [DW-1:0]	    in15;
//
input               sel16;
input [DW-1:0]	    in16;
//
input               sel17;
input [DW-1:0]	    in17;
//
input               sel18;
input [DW-1:0]	    in18;
//
input               sel19;
input [DW-1:0]	    in19;
//
input               sel20;
input [DW-1:0]	    in20;
//
input               sel21;
input [DW-1:0]	    in21;
//
input               sel22;
input [DW-1:0]	    in22;
//
input               sel23;
input [DW-1:0]	    in23;
//
input               sel24;
input [DW-1:0]	    in24;
//
input               sel25;
input [DW-1:0]	    in25;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal
wire [DW-1:0]       out0_12;
wire [DW-1:0]       out13_25;
//------------------------------------------------------------------------------
//Mux 13:1
mux13   #(.DW(DW))   mux0_12
    (
    .sel0  (sel0),
    .in0   (in0),
    //-------------------
    .sel1  (sel1),
    .in1   (in1),
    //-------------------
    .sel2  (sel2),
    .in2   (in2),
    //-------------------
    .sel3  (sel3),
    .in3   (in3),
    //-------------------
    .sel4  (sel4),
    .in4   (in4),
    //-------------------
    .sel5  (sel5),
    .in5   (in5),
    //-------------------
    .sel6  (sel6),
    .in6   (in6),
    //-------------------
    .sel7  (sel7),
    .in7   (in7),
    //-------------------
    .sel8  (sel8),
    .in8   (in8),
    //-------------------
    .sel9  (sel9),
    .in9   (in9),
    //-------------------
    .sel10  (sel10),
    .in10   (in10),
    //-------------------
    .sel11  (sel11),
    .in11   (in11),
    //-------------------
    .sel12  (sel12),
    .in12   (in12),
    //-------------------
    .out   (out0_12)
    );
//------------------------------------------------------------------------------
//Mux 13:1
mux13   #(.DW(DW))   mux13_25
    (
    .sel0  (sel13),
    .in0   (in13),
    //-------------------
    .sel1  (sel14),
    .in1   (in14),
    //-------------------
    .sel2  (sel15),
    .in2   (in15),
    //-------------------
    .sel3  (sel16),
    .in3   (in16),
    //-------------------
    .sel4  (sel17),
    .in4   (in17),
    //-------------------
    .sel5  (sel18),
    .in5   (in18),
    //-------------------
    .sel6  (sel19),
    .in6   (in19),
    //-------------------
    .sel7  (sel20),
    .in7   (in20),
    //-------------------
    .sel8  (sel21),
    .in8   (in21),
    //-------------------
    .sel9  (sel22),
    .in9   (in23),
    //-------------------
    .sel10  (sel23),
    .in10   (in23),
    //-------------------
    .sel11  (sel24),
    .in11   (in24),
    //-------------------
    .sel12  (sel25),
    .in12   (in25),
    //-------------------
    .out   (out13_25)
    );
//------------------------------------------------------------------------------
//Mux 2:1
assign out = out0_12 | out13_25;

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : mux2
// Description : 2:1 parallel mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module mux2
    (
    //-------------------
    //In 0
    sel0,
    in0,
    //-------------------
    //In 1
    sel1,
    in1,
    //-------------------
    //Out
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal

//------------------------------------------------------------------------------
//Logic
assign out = ({DW{sel0}} & in0) |
             ({DW{sel1}} & in1);

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : mux3
// Description : 3:1 parallel mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module mux3
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal

//------------------------------------------------------------------------------
//Logic
assign out = ({DW{sel0}} & in0) |
             ({DW{sel1}} & in1) |
             ({DW{sel2}} & in2);

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : mux4
// Description : 4:1 parallel mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module mux4
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal

//------------------------------------------------------------------------------
//Logic
assign out = ({DW{sel0}} & in0) |
             ({DW{sel1}} & in1) |
             ({DW{sel2}} & in2) |
             ({DW{sel3}} & in3);

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : mux5
// Description : 5:1 parallel mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module mux5
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    sel4,
    in4,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
input               sel4;
input [DW-1:0]	    in4;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal

//------------------------------------------------------------------------------
//Logic
assign out = ({DW{sel0}} & in0) |
             ({DW{sel1}} & in1) |
             ({DW{sel2}} & in2) |
             ({DW{sel3}} & in3) |
             ({DW{sel4}} & in4);

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : mux6
// Description : 6:1 parallel mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module mux6
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    sel4,
    in4,
    //-------------------
    sel5,
    in5,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
input               sel4;
input [DW-1:0]	    in4;
//
input               sel5;
input [DW-1:0]	    in5;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal

//------------------------------------------------------------------------------
//Logic
assign out = ({DW{sel0}} & in0) |
             ({DW{sel1}} & in1) |
             ({DW{sel2}} & in2) |
             ({DW{sel3}} & in3) |
             ({DW{sel4}} & in4) |
             ({DW{sel5}} & in5);

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : mux7
// Description : 7:1 parallel mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module mux7
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    sel4,
    in4,
    //-------------------
    sel5,
    in5,
    //-------------------
    sel6,
    in6,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
input               sel4;
input [DW-1:0]	    in4;
//
input               sel5;
input [DW-1:0]	    in5;
//
input               sel6;
input [DW-1:0]	    in6;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal

//------------------------------------------------------------------------------
//Logic
assign out = ({DW{sel0}} & in0) |
             ({DW{sel1}} & in1) |
             ({DW{sel2}} & in2) |
             ({DW{sel3}} & in3) |
             ({DW{sel4}} & in4) |
             ({DW{sel5}} & in5) |
             ({DW{sel6}} & in6);

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : mux8
// Description : 8:1 parallel mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module mux8
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    sel4,
    in4,
    //-------------------
    sel5,
    in5,
    //-------------------
    sel6,
    in6,
    //-------------------
    sel7,
    in7,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
input               sel4;
input [DW-1:0]	    in4;
//
input               sel5;
input [DW-1:0]	    in5;
//
input               sel6;
input [DW-1:0]	    in6;
//
input               sel7;
input [DW-1:0]	    in7;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal
wire [DW-1:0]       out03;
wire [DW-1:0]       out47;
//------------------------------------------------------------------------------
//Mux 4:1
mux4   #(.DW(DW))   mux4_0 
    (
    .sel0  (sel0),
    .in0   (in0),
    //-------------------
    .sel1  (sel1),
    .in1   (in1),
    //-------------------
    .sel2  (sel2),
    .in2   (in2),
    //-------------------
    .sel3  (sel3),
    .in3   (in3),
    //-------------------
    .out   (out03)
    );
//------------------------------------------------------------------------------
//Mux 4:1
mux4   #(.DW(DW))   mux4_1 
    (
    .sel0  (sel4),
    .in0   (in4),
    //-------------------
    .sel1  (sel5),
    .in1   (in5),
    //-------------------
    .sel2  (sel6),
    .in2   (in6),
    //-------------------
    .sel3  (sel7),
    .in3   (in7),
    //-------------------
    .out   (out47)
    );
//------------------------------------------------------------------------------
//Mux 2:1
assign out = out03 | out47;

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : mux9
// Description : 9:1 parallel mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module mux9
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    sel4,
    in4,
    //-------------------
    sel5,
    in5,
    //-------------------
    sel6,
    in6,
    //-------------------
    sel7,
    in7,
    //-------------------
    sel8,
    in8,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
input               sel4;
input [DW-1:0]	    in4;
//
input               sel5;
input [DW-1:0]	    in5;
//
input               sel6;
input [DW-1:0]	    in6;
//
input               sel7;
input [DW-1:0]	    in7;
//
input               sel8;
input [DW-1:0]	    in8;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal
wire [DW-1:0]       out04;
wire [DW-1:0]       out58;
//------------------------------------------------------------------------------
//Mux 5:1
mux5   #(.DW(DW))   mux5_0 
    (
    .sel0  (sel0),
    .in0   (in0),
    //-------------------
    .sel1  (sel1),
    .in1   (in1),
    //-------------------
    .sel2  (sel2),
    .in2   (in2),
    //-------------------
    .sel3  (sel3),
    .in3   (in3),
    //-------------------
    .sel4  (sel4),
    .in4   (in4),
    //-------------------
    .out   (out04)
    );
//------------------------------------------------------------------------------
//Mux 4:1
mux4   #(.DW(DW))   mux4_0 
    (
    .sel0  (sel5),
    .in0   (in5),
    //-------------------
    .sel1  (sel6),
    .in1   (in6),
    //-------------------
    .sel2  (sel7),
    .in2   (in7),
    //-------------------
    .sel3  (sel8),
    .in3   (in8),
    //-------------------
    .out   (out58)
    );
//------------------------------------------------------------------------------
//Mux 2:1
assign out = out04 | out58;

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : mux
// Description : Generic mux.
//
// Author      : K.Hagiwara
// Created On  : 2022.11.20
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module mux
(
  sel,  // Select signal, onehot or zero
  in,   // Inputs
  out   // Output
);

//------------------------------------------------------------------------------
// Parameters
parameter NUM = 4;  // Number of inputs
parameter DW = 1;   // Bit width of input

//------------------------------------------------------------------------------
// Port declarations
input  [NUM-1:0]         sel;
input  [NUM-1:0][DW-1:0] in;
output [DW-1:0]	         out;

//------------------------------------------------------------------------------
// Logic
wire [NUM:0][DW-1:0] tmp;

assign tmp[0] = {DW{1'b0}};

genvar i;
for (i = 0; i < NUM; i = i + 1) begin: g_sel
  assign tmp[i+1] = sel[i] ? in[i] : tmp[i];
end

assign out = tmp[NUM];

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : pri_mux3
// Description : 3:1 priority mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module pri_mux3
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal
wire                en0;
wire                en1;
wire                en2;
//------------------------------------------------------------------------------
//Logic
assign en0 = sel0;
assign en1 = sel1 & (~sel0);
assign en2 = sel2 & (~sel1) & (~sel0);
assign out = ({DW{en0}} & in0) |
             ({DW{en1}} & in1) |
             ({DW{en2}} & in2);

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : pri_mux4
// Description : 4:1 priority mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module pri_mux4
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal
wire                en0;
wire                en1;
wire                en2;
wire                en3;
//------------------------------------------------------------------------------
//Logic
assign en0 = sel0;
assign en1 = sel1 & (~sel0);
assign en2 = sel2 & (~sel1) & (~sel0);
assign en3 = sel3 & (~sel2) & (~sel1) & (~sel0);
assign out = ({DW{en0}} & in0) |
             ({DW{en1}} & in1) |
             ({DW{en2}} & in2) |
             ({DW{en3}} & in3);

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : pri_mux5
// Description : 5:1 priority mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module pri_mux5
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    sel4,
    in4,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
input               sel4;
input [DW-1:0]	    in4;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal
wire                en0;
wire                en1;
wire                en2;
wire                en3;
wire                en4;
//------------------------------------------------------------------------------
//Logic
assign en0 = sel0;
assign en1 = sel1 & (~sel0);
assign en2 = sel2 & (~sel1) & (~sel0);
assign en3 = sel3 & (~sel2) & (~sel1) & (~sel0);
assign en4 = sel4 & (~sel3) & (~sel2) & (~sel1) & (~sel0);
assign out = ({DW{en0}} & in0) |
             ({DW{en1}} & in1) |
             ({DW{en2}} & in2) |
             ({DW{en3}} & in3) |
             ({DW{en4}} & in4);

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : pri_mux6
// Description : 5:1 priority mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module pri_mux6
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    sel4,
    in4,
    //-------------------
    sel5,
    in5,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
input               sel4;
input [DW-1:0]	    in4;
//
input               sel5;
input [DW-1:0]	    in5;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal
wire [DW-1:0]       out02;
wire                vld02;
wire [DW-1:0]       out35;
//------------------------------------------------------------------------------
//3:1 mux
pri_vld_mux3  #(.DW(DW))   pri_vld_mux3_0
    (
    .sel0  (sel0),
    .in0   (in0),
    //-------------------
    .sel1  (sel1),
    .in1   (in1),
    //-------------------
    .sel2  (sel2),
    .in2   (in2),
    //-------------------
    .out   (out02),
    .vld_o (vld02)
    );
//------------------------------------------------------------------------------
//3:1 mux
pri_mux3  #(.DW(DW))   pri_mux3_0
    (
    .sel0  (sel3),
    .in0   (in3),
    //-------------------
    .sel1  (sel4),
    .in1   (in4),
    //-------------------
    .sel2  (sel5),
    .in2   (in5),
    //-------------------
    .out   (out35)
    );
//------------------------------------------------------------------------------
//2:1 mux
assign out = vld02 ? out02 : out35;

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : pri_mux7
// Description : 7:1 priority mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module pri_mux7
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    sel4,
    in4,
    //-------------------
    sel5,
    in5,
    //-------------------
    sel6,
    in6,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
input               sel4;
input [DW-1:0]	    in4;
//
input               sel5;
input [DW-1:0]	    in5;
//
input               sel6;
input [DW-1:0]	    in6;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal
wire [DW-1:0]       out02;
wire                vld02;
wire [DW-1:0]       out36;
//------------------------------------------------------------------------------
//3:1 mux
pri_vld_mux3  #(.DW(DW))   pri_vld_mux3_0
    (
    .sel0  (sel0),
    .in0   (in0),
    //-------------------
    .sel1  (sel1),
    .in1   (in1),
    //-------------------
    .sel2  (sel2),
    .in2   (in2),
    //-------------------
    .out   (out02),
    .vld_o (vld02)
    );
//------------------------------------------------------------------------------
//4:1 mux
pri_mux4  #(.DW(DW))   pri_mux4_0
    (
    .sel0  (sel3),
    .in0   (in3),
    //-------------------
    .sel1  (sel4),
    .in1   (in4),
    //-------------------
    .sel2  (sel5),
    .in2   (in5),
    //-------------------
    .sel3  (sel6),
    .in3   (in6),
    //-------------------
    .out   (out36)
    );
//------------------------------------------------------------------------------
//2:1 mux
assign out = vld02 ? out02 : out36;

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : pri_mux8
// Description : 8:1 priority mux.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module pri_mux8
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    sel4,
    in4,
    //-------------------
    sel5,
    in5,
    //-------------------
    sel6,
    in6,
    //-------------------
    sel7,
    in7,
    //-------------------
    out
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
input               sel4;
input [DW-1:0]	    in4;
//
input               sel5;
input [DW-1:0]	    in5;
//
input               sel6;
input [DW-1:0]	    in6;
//
input               sel7;
input [DW-1:0]	    in7;
//
output [DW-1:0]	    out;
//------------------------------------------------------------------------------
//internal signal
wire [DW-1:0]       out03;
wire                vld03;
wire [DW-1:0]       out47;
//------------------------------------------------------------------------------
//4:1 mux
pri_vld_mux4  #(.DW(DW))   pri_vld_mux4_0
    (
    .sel0  (sel0),
    .in0   (in0),
    //-------------------
    .sel1  (sel1),
    .in1   (in1),
    //-------------------
    .sel2  (sel2),
    .in2   (in2),
    //-------------------
    .sel3  (sel3),
    .in3   (in3),
    //-------------------
    .out   (out03),
    .vld_o (vld03)
    );
//------------------------------------------------------------------------------
//4:1 mux
pri_mux4  #(.DW(DW))   pri_mux4_0
    (
    .sel0  (sel4),
    .in0   (in4),
    //-------------------
    .sel1  (sel5),
    .in1   (in5),
    //-------------------
    .sel2  (sel6),
    .in2   (in6),
    //-------------------
    .sel3  (sel7),
    .in3   (in7),
    //-------------------
    .out   (out47)
    );
//------------------------------------------------------------------------------
//2:1 mux
assign out = vld03 ? out03 : out47;

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : pri_vld_mux3
// Description : 3:1 priority mux with output valid signal.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module pri_vld_mux3
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    out,
    vld_o
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
output [DW-1:0]	    out;
output              vld_o;
//------------------------------------------------------------------------------
//internal signal
wire                en0;
wire                en1;
wire                en2;
//------------------------------------------------------------------------------
//Logic
assign en0 = sel0;
assign en1 = sel1 & (~sel0);
assign en2 = sel2 & (~sel1) & (~sel0);
assign vld_o = sel0 | sel1 | sel2;
assign out = ({DW{en0}} & in0) |
             ({DW{en1}} & in1) |
             ({DW{en2}} & in2);

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : pri_vld_mux4
// Description : 3:1 priority mux with output valid signal.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module pri_vld_mux4
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    in3,
    //-------------------
    out,
    vld_o
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input [DW-1:0]	    in3;
//
output [DW-1:0]	    out;
output              vld_o;
//------------------------------------------------------------------------------
//internal signal
wire                en0;
wire                en1;
wire                en2;
wire                en3;
//------------------------------------------------------------------------------
//Logic
assign en0 = sel0;
assign en1 = sel1 & (~sel0);
assign en2 = sel2 & (~sel1) & (~sel0);
assign en3 = (~sel2) & (~sel1) & (~sel0);
assign vld_o = sel0 | sel1 | sel2;
assign out = ({DW{en0}} & in0) |
             ({DW{en1}} & in1) |
             ({DW{en2}} & in2) |
             ({DW{en3}} & in3);

endmodule 

//----------------------------------------------------------------------------- 
//SH consulting
//File Name		: regfile8xnb.v
//Description	: Refister file with depth = 128 and width = N,
//				  data is returned at current clock.
//
//Author		: duongnguyen
//Created On	: 11/30/2015
//-----------------------------------------------------------------------------
module	regfile8xnb
	(
	clk,
	rst_n,	
	//-----------------------------
	//Write
	wen_i,//Write enable
	waddr_i,//write address
	wdata_i,//write data
        clr_i,
	//-----------------------------
	//Read
	raddr_i,//Read address
	rdata_o//Read data
	);


//-----------------------------------------------------------------------------
//Parameters
parameter		AW = 3;
parameter		DW = 8;
//-----------------------------------------------------------------------------
//Port declaration
input                   clk;
input                   rst_n;	
//-----------------------------
//Write
input                   wen_i;//Write enable
input	[AW-1:0]	waddr_i;//write address
input	[DW-1:0]	wdata_i;//write data
input                   clr_i;
//-----------------------------
//Read
input	[AW-1:0]	raddr_i;//Read address
output	[DW-1:0]	rdata_o;//Read data

reg 	[DW-1:0]	rdata_o;//Read data

//-----------------------------------------------------------------------------
//Internal variables
wire                    wen0;
wire                    wen1;
wire                    wen2;
wire                    wen3;
wire                    wen4;
wire                    wen5;
wire                    wen6;
wire                    wen7;

wire	[DW-1:0]	rdata0;
wire	[DW-1:0]	rdata1;
wire	[DW-1:0]	rdata2;
wire	[DW-1:0]	rdata3;
wire	[DW-1:0]	rdata4;
wire	[DW-1:0]	rdata5;
wire	[DW-1:0]	rdata6;
wire	[DW-1:0]	rdata7;

//-----------------------------------------------------------------------------
//Reg 0
regnb
	#(.DW	(DW)
	)	reg0
	(
	.clk		(clk),
	.rst_n		(rst_n),	
	.wen_i		(wen0),
	.wdata_i	(wdata_i),
        .clr_i      (clr_i),
	.ren_i		(1'b1),
	.rdata_o	(rdata0)
	);
//-----------------------------------------------------------------------------
//Reg 1
regnb
	#(.DW	(DW)
	)	reg1
	(
	.clk		(clk),
	.rst_n		(rst_n),	
	.wen_i		(wen1),
	.wdata_i	(wdata_i),
        .clr_i      (clr_i),
	.ren_i		(1'b1),
	.rdata_o	(rdata1)
	);
//-----------------------------------------------------------------------------
//Reg 2
regnb
	#(.DW	(DW)
	)	reg2
	(
	.clk		(clk),
	.rst_n		(rst_n),	
	.wen_i		(wen2),
	.wdata_i	(wdata_i),
        .clr_i      (clr_i),
	.ren_i		(1'b1),
	.rdata_o	(rdata2)
	);
//-----------------------------------------------------------------------------
//Reg 3
regnb
	#(.DW	(DW)
	)	reg3
	(
	.clk		(clk),
	.rst_n		(rst_n),	
	.wen_i		(wen3),
	.wdata_i	(wdata_i),
    .clr_i      (clr_i),
	.ren_i		(1'b1),
	.rdata_o	(rdata3)
	);
//-----------------------------------------------------------------------------
//Reg 4
regnb
	#(.DW	(DW)
	)	reg4
	(
	.clk		(clk),
	.rst_n		(rst_n),	
	.wen_i		(wen4),
	.wdata_i	(wdata_i),
        .clr_i      (clr_i),
	.ren_i		(1'b1),
	.rdata_o	(rdata4)
	);

//-----------------------------------------------------------------------------
//Reg 5
regnb
	#(.DW	(DW)
	)	reg5
	(
	.clk		(clk),
	.rst_n		(rst_n),	
	.wen_i		(wen5),
	.wdata_i	(wdata_i),
        .clr_i      (clr_i),
	.ren_i		(1'b1),
	.rdata_o	(rdata5)
	);
//-----------------------------------------------------------------------------
//Reg 6
regnb
	#(.DW	(DW)
	)	reg6
	(
	.clk		(clk),
	.rst_n		(rst_n),	
	.wen_i		(wen6),
	.wdata_i	(wdata_i),
        .clr_i      (clr_i),
	.ren_i		(1'b1),
	.rdata_o	(rdata6)
	);
//-----------------------------------------------------------------------------
//Reg 7
regnb
	#(.DW	(DW)
	)	reg7
	(
	.clk		(clk),
	.rst_n		(rst_n),	
	.wen_i		(wen7),
	.wdata_i	(wdata_i),
        .clr_i      (clr_i),
	.ren_i		(1'b1),
	.rdata_o	(rdata7)
	);


//-----------------------------------------------------------------------------
//Write control
assign wen0 = (waddr_i == 3'd0) & wen_i;
assign wen1 = (waddr_i == 3'd1) & wen_i;
assign wen2 = (waddr_i == 3'd2) & wen_i;
assign wen3 = (waddr_i == 3'd3) & wen_i;
assign wen4 = (waddr_i == 3'd4) & wen_i;
assign wen5 = (waddr_i == 3'd5) & wen_i;
assign wen6 = (waddr_i == 3'd6) & wen_i;
assign wen7 = (waddr_i == 3'd7) & wen_i;
//-----------------------------------------------------------------------------
//Read control

always @(*)
	begin
	case(raddr_i)
		3'd0 : rdata_o = rdata0;
		3'd1 : rdata_o = rdata1;
		3'd2 : rdata_o = rdata2;
		3'd3 : rdata_o = rdata3;
		3'd4 : rdata_o = rdata4;
		3'd5 : rdata_o = rdata5;
		3'd6 : rdata_o = rdata6;
		3'd7 : rdata_o = rdata7;
		default : rdata_o = {DW{1'b0}};
	endcase
	end

endmodule	
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
//////////////////////////////////////////////////////////////////////////////////
//  SH Consulting
//
// Filename    : status_reg.v
// Description : Latching status of the design.
// Author      : duong nguyen
// Created On  : 9/9/2015
// History (Date, Changed By)
//
//////////////////////////////////////////////////////////////////////////////////
module status_reg
    (
     clk,
     rst_n,
     //--------------------------------------
     //cpu access
     cpuren_i, //read enable
     cpuwen_i, //write enable
     cpudi_i,// Input data from CPU
     cpudo_o,// Output data for CPU
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
input                     rst_n;
input                     cpuren_i;  
input                     cpuwen_i; 
input   [DW-1:0]          cpudi_i; 
output  [DW-1:0]          cpudo_o;

input  [DW-1:0]           status_i;
input	                  clr_i;
//-----------------------------------------------------------------------------
//Internal variable
reg   [DW-1:0] 	          latch_status;
wire  [DW-1:0]            nxt_latch_status;
//-----------------------------------------------------------------------------
//Logic implementation
assign nxt_latch_status = clr_i ? {DW{1'b0}} : status_i;
assign cpudo_o = cpuren_i ? latch_status : {DW{1'b0}};

always @(posedge clk or negedge rst_n)
    begin
    if(!rst_n)   
        latch_status <= RST_VAL;
    else  
        latch_status <= nxt_latch_status; 
    end 
	
endmodule
//////////////////////////////////////////////////////////////////////////////////
//
//  SH Consulting
//
// Filename        : sync_fiford_ctrl.v
// Description     : Control reading FIFO 
//					
//
// Author          : Duong Nguyen
// Created On      : 9/9/2015
// History (Date, Changed By)
//
//////////////////////////////////////////////////////////////////////////////////
module sync_fiford_ctrl
    (
    rclk,
    rst_n,

    //--------------------------------------
    // input interface
    rfifo_i,  // request read fifo
    wptr_i, 
    //--------------------------------------
    // output interface
    ren_o,
    rempty_o,
    raddr_o, // reading address
    rptr_o
    );

//-----------------------------------------------------------------------------
//parameter
parameter AW = 3;

//-----------------------------------------------------------------------------
// Port declarations
input               rclk;
input               rst_n;
//--------------------------------------
// input interface
input               rfifo_i;
input   [AW:0]      wptr_i;
//--------------------------------------
// output interface
output              ren_o;
output              rempty_o;
output  [AW-1:0]    raddr_o;
output  [AW:0]      rptr_o;
//-----------------------------------------------------------------------------
//internal signal
wire [AW:0]         nxt_rptr;
reg  [AW:0]         rptr;
wire                ren;
wire                nxt_rempty;
reg                 rempty;
//------------------------------------------------------------------------------
//Latch read pointer
assign ren = rfifo_i & (~rempty);
assign nxt_rptr = ren ? (rptr + 1'b1) : rptr;
always @ (posedge rclk or negedge rst_n)
    begin
    if(!rst_n)
        rptr <= {(AW+1){1'b0}};
    else
        rptr <= nxt_rptr;
    end
assign raddr_o = rptr[AW-1:0];
assign ren_o = ren;
assign rptr_o = rptr;
//------------------------------------------------------------------------------
//Empty detection
assign nxt_rempty = (nxt_rptr == wptr_i);
always @ (posedge rclk or negedge rst_n)
    begin
    if(!rst_n)
        rempty <= 1'b1;
    else
        rempty <= nxt_rempty;
    end
assign rempty_o = rempty;
 
endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     :
//
// Filename    : sync_fifo.v
// Description : 
//
// Author      : 
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////
module sync_fifo
    (
     rst_n,
     // write
     wclk,
     wfifo_i,  // request write to fifo
     wdata_i,
     wfull_o,
     // read
     rclk, 
     rfifo_i,
     rempty_o,
     rdata_o  // request read from fifo
     );
//------------------------------------------------------------------------------
//parameter
parameter ADD_W = 3;
parameter DATA_W = 36;
//------------------------------------------------------------------------------
// Port declarations
input                   rst_n;
input                   wclk;
input                   wfifo_i;
input [DATA_W-1:0]      wdata_i;
output                  wfull_o;
// read
input                   rclk;
input                   rfifo_i;
output [DATA_W-1:0]     rdata_o;
output                  rempty_o;
//------------------------------------------------------------------------------
//internal signal
wire  [ADD_W:0]         rptr;
wire  [ADD_W:0]         wptr;
wire                    ren;
wire                    wen;
wire  [ADD_W-1:0]       waddr;
wire  [ADD_W-1:0]       raddr;
wire  [DATA_W-1:0]      rdata_o;
wire  [DATA_W-1:0]      ff_rdata;
wire  [DATA_W-1:0]      nxt_rdata;
//------------------------------------------------------------------------------
//Read control
sync_fiford_ctrl    #(.AW(ADD_W))  sync_fiford_ctrl_00
    (
    .rclk     (rclk),
    .rst_n    (rst_n),
    // input interface
    .rfifo_i  (rfifo_i), 
    .wptr_i   (wptr), 
    // output interface
    .ren_o    (ren),
    .rempty_o (rempty_o),
    .raddr_o  (raddr),
    .rptr_o   (rptr)
     );
//------------------------------------------------------------------------------
//Write control
sync_fifowr_ctrl   #(.AW(ADD_W))   sync_fifowr_ctrl_00
    (
    .wclk    (wclk),
    .rst_n   (rst_n),
    // input interface
    .wfifo_i (wfifo_i),
    .rptr_i  (rptr),
    // output interface
    .wen_o   (wen),
    .wfull_o (wfull_o),
    .waddr_o (waddr),
    .wptr_o  (wptr)
     );
/*
//------------------------------------------------------------------------------
//SRAM
model_alt_ram_dual_clk  #(.AW(ADD_W),
                          .DW(DATA_W),
                          .DEPTH(DEPTH))  model_alt_ram_dual_clk_00
    (
    //Read
    .rclk    (rclk),
    .raddr_i (raddr),
    .rdata_o (rdata_o),
    //Write
    .wclk    (wclk),
    .wen_i   (wen),
    .wdata_i (wdata_i),
    .waddr_i (waddr)
    );

*/

//------------------------------------------------------------------------------
//Register MEM
regfile8xnb   #(.AW(ADD_W),
                .DW(DATA_W))    regfile8xnb_00
    (
    .clk     (wclk),
    .rst_n   (rst_n),	
    //-----------------------------
    //Write
    .wen_i   (wen),//Write enable
    .waddr_i (waddr),//write address
    .wdata_i (wdata_i),//write data
    .clr_i   (1'b0),
    //-----------------------------
    //Read
    .raddr_i (raddr),//Read address
    .rdata_o (ff_rdata)//Read data
    );
//------------------------------------------------------------------------------
//Latch output data
/*
assign nxt_rdata = ren ? ff_rdata : rdata_o;
always@(posedge rclk or negedge rst_n)
    begin
    if (!rst_n)
        rdata_o <= {DATA_W{1'b0}};
    else
        rdata_o <= nxt_rdata;
    end
*/
 assign rdata_o = ff_rdata;
endmodule 

//////////////////////////////////////////////////////////////////////////////////
//
//  SH Consulting
//
// Filename        : sync_fifowr_ctrl.v
// Description     : Control writing FIFO. 
//					
//
// Author          : Duong Nguyen
// Created On      : 9/9/2015
// History (Date, Changed By)
//
//////////////////////////////////////////////////////////////////////////////////
module sync_fifowr_ctrl
    (
    wclk,
    rst_n,

    //--------------------------------------
    // input interface
    wfifo_i,
    rptr_i,
    //--------------------------------------
    // output interface
    wen_o,
    wfull_o,
    waddr_o,
    wptr_o
     );

//-----------------------------------------------------------------------------
//parameter
parameter AW = 3;

//-----------------------------------------------------------------------------
// Port declarations
input               wclk;
input               rst_n;
//--------------------------------------
// input interface
input               wfifo_i;
input   [AW:0]      rptr_i;
//--------------------------------------
// output interface
output              wen_o;
output              wfull_o;
output  [AW-1:0]    waddr_o;
output  [AW:0]      wptr_o;
//-----------------------------------------------------------------------------
//internal signal
wire [AW:0]         nxt_wptr;
reg  [AW:0]         wptr;
wire                wen;
wire                nxt_wfull;
reg                 wfull;
//------------------------------------------------------------------------------
//Latch read pointer
assign wen = wfifo_i & (~wfull);
assign nxt_wptr = wen ? (wptr + 1'b1) : wptr;
always @ (posedge wclk or negedge rst_n)
    begin
    if(!rst_n)
        wptr <= {(AW+1){1'b0}};
    else
        wptr <= nxt_wptr;
    end
assign waddr_o = wptr[AW-1:0];
assign wen_o = wen;
assign wptr_o = wptr;
//------------------------------------------------------------------------------
//Empty detection
assign nxt_wfull = ({~nxt_wptr[AW],wptr[AW-1:0]} == rptr_i);
always@(posedge wclk or negedge rst_n)
    begin
    if(!rst_n)
        wfull <= 1'b0;
    else
        wfull <= nxt_wfull;
    end
assign wfull_o = wfull;
 
endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : vld_mux4
// Description : 4:1 parallel mux with valid output.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module vld_mux4
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    out,
    vld_o
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
output [DW-1:0]	    out;
output              vld_o;
//------------------------------------------------------------------------------
//internal signal

//------------------------------------------------------------------------------
//Logic
assign out = ({DW{sel0}} & in0) |
             ({DW{sel1}} & in1) |
             ({DW{sel2}} & in2) |
             ({DW{sel3}} & in3);
assign vld_o = sel0 | sel1 | sel2 | sel3;

endmodule 

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : vld_mux5
// Description : 5:1 parallel mux with output valid.
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module vld_mux5
    (
    sel0,
    in0,
    //-------------------
    sel1,
    in1,
    //-------------------
    sel2,
    in2,
    //-------------------
    sel3,
    in3,
    //-------------------
    sel4,
    in4,
    //-------------------
    out,
    vld_o
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW = 1'b1;
//------------------------------------------------------------------------------
// Port declarations
input               sel0;
input [DW-1:0]	    in0;
//
input               sel1;
input [DW-1:0]	    in1;
//
input               sel2;
input [DW-1:0]	    in2;
//
input               sel3;
input [DW-1:0]	    in3;
//
input               sel4;
input [DW-1:0]	    in4;
//
output [DW-1:0]	    out;
output              vld_o;
//------------------------------------------------------------------------------
//internal signal

//------------------------------------------------------------------------------
//Logic
assign out = ({DW{sel0}} & in0) |
             ({DW{sel1}} & in1) |
             ({DW{sel2}} & in2) |
             ({DW{sel3}} & in3) |
             ({DW{sel4}} & in4);
assign vld_o = sel0 | sel1 | sel2 | sel3 | sel4;

endmodule 

