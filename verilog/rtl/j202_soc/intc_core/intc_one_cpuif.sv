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
// Filename    : intc_one_cpuif.sv
// Description : Interrupt CPU interface module.
//
// Author      : Duong Nguyen
// Created On  : August 9, 2017
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module intc_one_cpuif
    (
    clk,
    rst,//synchronous reset, active-high
    sync_cpu_int_i,
    //---------------------------------
    //CPU interfaces
    intr_req_o,
    intr_level_o,
    intr_vec_o,
    inta_ack_i,
    
    //---------------------------------
    //INTCSEL interfaces
    sl_req_i,
    sl_level_i,
    sl_vec_i,
    cp_intack_nmi_o,
    cp_intack_err_o,
    cp_intack_o,
    cp_intack_all_o
    );

//------------------------------------------------------------------------------
//parameter
//------------------------------------------------------------------------------
parameter CPU_NUM = 1;
parameter REG_NUM = 1; //REG_NUM*32 is number of normal interrupt.

//------------------------------------------------------------------------------
// Port declarations
//------------------------------------------------------------------------------
input logic                       clk;
input logic                       rst;
input logic                       sync_cpu_int_i;
//---------------------------------
//CPU interfaces
output logic                      intr_req_o;
output logic [4:0]                intr_level_o;
output logic [7:0]                intr_vec_o;
input  logic                      inta_ack_i;

//---------------------------------
//INTCSEL interfaces
input logic                       sl_req_i;
input logic [4:0]                 sl_level_i;
input logic [7:0]                 sl_vec_i;
output logic                      cp_intack_nmi_o;
output logic                      cp_intack_err_o;
output logic [REG_NUM*32-1:0]     cp_intack_o;
output logic                      cp_intack_all_o;
//------------------------------------------------------------------------------
//Internal variables
logic                             nxt_intr_req;
logic                             nxt_cp_intack_all;
logic [7:0]                       nxt_intr_vec_latch;
logic [7:0]                       intr_vec_latch;

//------------------------------------------------------------------------------
//Request logic

assign nxt_intr_req = (sl_req_i | intr_req_o) & (~(inta_ack_i | cp_intack_all_o));
//Interrupt request FF
dff_rst  #(1)  dff_intr_req  (clk,rst,nxt_intr_req,intr_req_o);

//------------------------------------------------------------------------------
//ACK clear logic
assign nxt_cp_intack_all = ((~sync_cpu_int_i) & cp_intack_all_o) | inta_ack_i;
//ACK FF
dff_rst  #(1)  dff_intack_all  (clk,rst,nxt_cp_intack_all,cp_intack_all_o);
//------------------------------------------------------------------------------
//Level and vector FF
dff_rst  #(5)  dff_level  (clk,rst,sl_level_i,intr_level_o);
dff_rst  #(8)  dff_intr_vec  (clk,rst,sl_vec_i,intr_vec_o);
//------------------------------------------------------------------------------
//Level and vector FF

assign nxt_intr_vec_latch = inta_ack_i ? intr_vec_o : intr_vec_latch;
 
dff_rst  #(8)  dff_bs_intr_vec_1 (clk,rst,nxt_intr_vec_latch,intr_vec_latch);

assign cp_intack_err_o = (intr_vec_latch == 8'd9)  & cp_intack_all_o; 
assign cp_intack_nmi_o = (intr_vec_latch == 8'd11) & cp_intack_all_o; 
assign cp_intack_o[0]  = (intr_vec_latch == 8'd64) & cp_intack_all_o; 
assign cp_intack_o[1]  = (intr_vec_latch == 8'd65) & cp_intack_all_o; 
assign cp_intack_o[2]  = (intr_vec_latch == 8'd66) & cp_intack_all_o; 
assign cp_intack_o[3]  = (intr_vec_latch == 8'd67) & cp_intack_all_o; 
assign cp_intack_o[4]  = (intr_vec_latch == 8'd68) & cp_intack_all_o; 
assign cp_intack_o[5]  = (intr_vec_latch == 8'd69) & cp_intack_all_o; 
assign cp_intack_o[6]  = (intr_vec_latch == 8'd70) & cp_intack_all_o; 
assign cp_intack_o[7]  = (intr_vec_latch == 8'd71) & cp_intack_all_o; 
assign cp_intack_o[8]  = (intr_vec_latch == 8'd72) & cp_intack_all_o; 
assign cp_intack_o[9]  = (intr_vec_latch == 8'd73) & cp_intack_all_o; 
assign cp_intack_o[10] = (intr_vec_latch == 8'd74) & cp_intack_all_o; 
assign cp_intack_o[11] = (intr_vec_latch == 8'd75) & cp_intack_all_o; 
assign cp_intack_o[12] = (intr_vec_latch == 8'd76) & cp_intack_all_o; 
assign cp_intack_o[13] = (intr_vec_latch == 8'd77) & cp_intack_all_o; 
assign cp_intack_o[14] = (intr_vec_latch == 8'd78) & cp_intack_all_o; 
assign cp_intack_o[15] = (intr_vec_latch == 8'd79) & cp_intack_all_o; 
assign cp_intack_o[16] = (intr_vec_latch == 8'd80) & cp_intack_all_o; 
assign cp_intack_o[17] = (intr_vec_latch == 8'd81) & cp_intack_all_o; 
assign cp_intack_o[18] = (intr_vec_latch == 8'd82) & cp_intack_all_o; 
assign cp_intack_o[19] = (intr_vec_latch == 8'd83) & cp_intack_all_o; 
assign cp_intack_o[20] = (intr_vec_latch == 8'd84) & cp_intack_all_o; 
assign cp_intack_o[21] = (intr_vec_latch == 8'd85) & cp_intack_all_o; 
assign cp_intack_o[22] = (intr_vec_latch == 8'd86) & cp_intack_all_o; 
assign cp_intack_o[23] = (intr_vec_latch == 8'd87) & cp_intack_all_o; 
assign cp_intack_o[24] = (intr_vec_latch == 8'd88) & cp_intack_all_o; 
assign cp_intack_o[25] = (intr_vec_latch == 8'd89) & cp_intack_all_o; 
assign cp_intack_o[26] = (intr_vec_latch == 8'd90) & cp_intack_all_o; 
assign cp_intack_o[27] = (intr_vec_latch == 8'd91) & cp_intack_all_o; 
assign cp_intack_o[28] = (intr_vec_latch == 8'd92) & cp_intack_all_o; 
assign cp_intack_o[29] = (intr_vec_latch == 8'd93) & cp_intack_all_o; 
assign cp_intack_o[30] = (intr_vec_latch == 8'd94) & cp_intack_all_o; 
assign cp_intack_o[31] = (intr_vec_latch == 8'd95) & cp_intack_all_o; 


endmodule 

