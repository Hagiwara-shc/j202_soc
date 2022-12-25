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

////////////////////////////////////////////////////////////////////////////////
// Company     : SH Consulting
//
// Filename    : intc_32to1_sel.sv
// Description : Interrupt selection for one cpu
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module intc_32to1_sel
    (
    //---------------------------------
    //Input
    dat_i,
    //---------------------------------
    //Register interface
    dat_o
    );

////////////////////////////////////////////////////////////////////////////////
//parameter
parameter DW = 5;
parameter PRI_DW = 4;

////////////////////////////////////////////////////////////////////////////////
// Port declarations

//---------------------------------
//Inputs
input logic  [31:0][DW-1:0]    dat_i;
//---------------------------------
//Output
output logic  [DW-1+8:0]       dat_o;
//------------------------------------------------------------------------------
//internal signal
logic [DW-1+8:0]               dat_0_1;
logic [DW-1+8:0]               dat_2_3;
logic [DW-1+8:0]               dat_4_5;
logic [DW-1+8:0]               dat_6_7;
logic [DW-1+8:0]               dat_8_9;
logic [DW-1+8:0]               dat_10_11;
logic [DW-1+8:0]               dat_12_13;
logic [DW-1+8:0]               dat_14_15;
logic [DW-1+8:0]               dat_16_17;
logic [DW-1+8:0]               dat_18_19;
logic [DW-1+8:0]               dat_20_21;
logic [DW-1+8:0]               dat_22_23;
logic [DW-1+8:0]               dat_24_25;
logic [DW-1+8:0]               dat_26_27;
logic [DW-1+8:0]               dat_28_29;
logic [DW-1+8:0]               dat_30_31;

logic [DW-1+8:0]               dat_0_3;
logic [DW-1+8:0]               dat_4_7;
logic [DW-1+8:0]               dat_8_11;
logic [DW-1+8:0]               dat_12_15;
logic [DW-1+8:0]               dat_16_19;
logic [DW-1+8:0]               dat_20_23;
logic [DW-1+8:0]               dat_24_27;
logic [DW-1+8:0]               dat_28_31;

logic [DW-1+8:0]               dat_0_7;
logic [DW-1+8:0]               dat_8_15;
logic [DW-1+8:0]               dat_16_23;
logic [DW-1+8:0]               dat_24_31;

logic [DW-1+8:0]               dat_0_15;
logic [DW-1+8:0]               dat_16_31;


//------------------------------------------------------------------------------
//Stage 1 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_0_1
    (
    //---------------------------------
    //Input
    .dat0_i ({dat_i[0],8'd64}),
    .dat1_i ({dat_i[1],8'd65}),
    //---------------------------------
    //Register interface
    .dat_o  (dat_0_1)
    );
// 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_2_3
    (
    //---------------------------------
    //Input
    .dat0_i ({dat_i[2],8'd66}),
    .dat1_i ({dat_i[3],8'd67}),
    //---------------------------------
    //Register interface
    .dat_o  (dat_2_3)
    );
// 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_4_5
    (
    //---------------------------------
    //Input
    .dat0_i ({dat_i[4],8'd68}),
    .dat1_i ({dat_i[5],8'd69}),
    //---------------------------------
    //Register interface
    .dat_o  (dat_4_5)
    );
// 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_6_7
    (
    //---------------------------------
    //Input
    .dat0_i ({dat_i[6],8'd70}),
    .dat1_i ({dat_i[7],8'd71}),
    //---------------------------------
    //Register interface
    .dat_o  (dat_6_7)
    );
// 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_8_9
    (
    //---------------------------------
    //Input
    .dat0_i ({dat_i[8],8'd72}),
    .dat1_i ({dat_i[9],8'd73}),
    //---------------------------------
    //Register interface
    .dat_o  (dat_8_9)
    );
// 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_10_11
    (
    //---------------------------------
    //Input
    .dat0_i ({dat_i[10],8'd74}),
    .dat1_i ({dat_i[11],8'd75}),
    //---------------------------------
    //Register interface
    .dat_o  (dat_10_11)
    );
// 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_12_13
    (
    //---------------------------------
    //Input
    .dat0_i ({dat_i[12],8'd76}),
    .dat1_i ({dat_i[13],8'd77}),
    //---------------------------------
    //Register interface
    .dat_o  (dat_12_13)
    );
// 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_14_15
    (
    //---------------------------------
    //Input
    .dat0_i ({dat_i[14],8'd78}),
    .dat1_i ({dat_i[15],8'd79}),
    //---------------------------------
    //Register interface
    .dat_o  (dat_14_15)
    );
// 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_16_17
    (
    //---------------------------------
    //Input
    .dat0_i ({dat_i[16],8'd80}),
    .dat1_i ({dat_i[17],8'd81}),
    //---------------------------------
    //Register interface
    .dat_o  (dat_16_17)
    );
// 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_18_19
    (
    //---------------------------------
    //Input
    .dat0_i ({dat_i[18],8'd82}),
    .dat1_i ({dat_i[19],8'd83}),
    //---------------------------------
    //Register interface
    .dat_o  (dat_18_19)
    );
// 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_20_21
    (
    //---------------------------------
    //Input
    .dat0_i ({dat_i[20],8'd84}),
    .dat1_i ({dat_i[21],8'd85}),
    //---------------------------------
    //Register interface
    .dat_o  (dat_20_21)
    );
// 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_22_23
    (
    //---------------------------------
    //Input
    .dat0_i ({dat_i[22],8'd86}),
    .dat1_i ({dat_i[23],8'd87}),
    //---------------------------------
    //Register interface
    .dat_o  (dat_22_23)
    );
// 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_24_25
    (
    //---------------------------------
    //Input
    .dat0_i ({dat_i[24],8'd88}),
    .dat1_i ({dat_i[25],8'd89}),
    //---------------------------------
    //Register interface
    .dat_o  (dat_24_25)
    );
// 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_26_27
    (
    //---------------------------------
    //Input
    .dat0_i ({dat_i[26],8'd90}),
    .dat1_i ({dat_i[27],8'd91}),
    //---------------------------------
    //Register interface
    .dat_o  (dat_26_27)
    );
// 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_28_29
    (
    //---------------------------------
    //Input
    .dat0_i ({dat_i[28],8'd92}),
    .dat1_i ({dat_i[29],8'd93}),
    //---------------------------------
    //Register interface
    .dat_o  (dat_28_29)
    );
// 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_30_31
    (
    //---------------------------------
    //Input
    .dat0_i ({dat_i[30],8'd94}),
    .dat1_i ({dat_i[31],8'd95}),
    //---------------------------------
    //Register interface
    .dat_o  (dat_30_31)
    );
//------------------------------------------------------------------------------
//Stage 2 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_0_3
    (
    //---------------------------------
    //Input
    .dat0_i (dat_0_1),
    .dat1_i (dat_2_3),
    //---------------------------------
    //Register interface
    .dat_o  (dat_0_3)
    );
//
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_4_7
    (
    //---------------------------------
    //Input
    .dat0_i (dat_4_5),
    .dat1_i (dat_6_7),
    //---------------------------------
    //Register interface
    .dat_o  (dat_4_7)
    );
//
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_8_11
    (
    //---------------------------------
    //Input
    .dat0_i (dat_8_9),
    .dat1_i (dat_10_11),
    //---------------------------------
    //Register interface
    .dat_o  (dat_8_11)
    );
//
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_12_15
    (
    //---------------------------------
    //Input
    .dat0_i (dat_12_13),
    .dat1_i (dat_14_15),
    //---------------------------------
    //Register interface
    .dat_o  (dat_12_15)
    );
//
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_16_19
    (
    //---------------------------------
    //Input
    .dat0_i (dat_16_17),
    .dat1_i (dat_18_19),
    //---------------------------------
    //Register interface
    .dat_o  (dat_16_19)
    );
//
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_20_23
    (
    //---------------------------------
    //Input
    .dat0_i (dat_20_21),
    .dat1_i (dat_22_23),
    //---------------------------------
    //Register interface
    .dat_o  (dat_20_23)
    );
//
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_24_27
    (
    //---------------------------------
    //Input
    .dat0_i (dat_24_25),
    .dat1_i (dat_26_27),
    //---------------------------------
    //Register interface
    .dat_o  (dat_24_27)
    );
//
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_28_31
    (
    //---------------------------------
    //Input
    .dat0_i (dat_28_29),
    .dat1_i (dat_30_31),
    //---------------------------------
    //Register interface
    .dat_o  (dat_28_31)
    );
//------------------------------------------------------------------------------
//Stage 3 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_0_7
    (
    //---------------------------------
    //Input
    .dat0_i (dat_0_3),
    .dat1_i (dat_4_7),
    //---------------------------------
    //Register interface
    .dat_o  (dat_0_7)
    );
//
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_8_15
    (
    //---------------------------------
    //Input
    .dat0_i (dat_8_11),
    .dat1_i (dat_12_15),
    //---------------------------------
    //Register interface
    .dat_o  (dat_8_15)
    );
//
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_16_23
    (
    //---------------------------------
    //Input
    .dat0_i (dat_16_19),
    .dat1_i (dat_20_23),
    //---------------------------------
    //Register interface
    .dat_o  (dat_16_23)
    );
//
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_24_31
    (
    //---------------------------------
    //Input
    .dat0_i (dat_24_27),
    .dat1_i (dat_28_31),
    //---------------------------------
    //Register interface
    .dat_o  (dat_24_31)
    );
//------------------------------------------------------------------------------
//Stage 3 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_0_15
    (
    //---------------------------------
    //Input
    .dat0_i (dat_0_7),
    .dat1_i (dat_8_15),
    //---------------------------------
    //Register interface
    .dat_o  (dat_0_15)
    );
//
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_16_31
    (
    //---------------------------------
    //Input
    .dat0_i (dat_16_23),
    .dat1_i (dat_24_31),
    //---------------------------------
    //Register interface
    .dat_o  (dat_16_31)
    );
//------------------------------------------------------------------------------
//Stage 4 
intc_2to1_sel  #(.DW(13),
                 .PRI_DW(4))  intc_2to1_sel_0_31
    (
    //---------------------------------
    //Input
    .dat0_i (dat_0_15),
    .dat1_i (dat_16_31),
    //---------------------------------
    //Register interface
    .dat_o  (dat_o)
    );



endmodule 

