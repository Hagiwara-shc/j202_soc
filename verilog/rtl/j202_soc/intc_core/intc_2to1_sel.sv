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
// Filename    : intc_2to1_sel.sv
// Description : Interrupt selection for one cpu
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module intc_2to1_sel
    (
    //---------------------------------
    //Input
    dat0_i,
    dat1_i,
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
input logic  [DW-1:0]          dat0_i;
input logic  [DW-1:0]          dat1_i;
//---------------------------------
//Output
output logic  [DW-1:0]         dat_o;
//------------------------------------------------------------------------------
//internal signal
logic [DW-1:8]                 in0;
logic [DW-1:8]                 in1;
logic [PRI_DW+1:0]             sum;

//------------------------------------------------------------------------------
//Checking CPU target of interrupt request 
assign in0 = dat0_i[DW-1:8];
assign in1 = ~dat1_i[DW-1:8];
assign sum = {1'b0,in0} + {1'b0,in1}; //in0 + in1 + cin (1'b0)

assign dat_o = sum[PRI_DW+1] ? dat0_i : dat1_i;


endmodule 

