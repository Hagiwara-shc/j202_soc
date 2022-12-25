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
// Filename    : intc_cpuif.sv
// Description : Interrupt CPU interface module.
//
// Author      : Duong Nguyen
// Created On  : August 9, 2017
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module intc_cpuif
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
output logic [CPU_NUM-1:0]        intr_req_o;
output logic [CPU_NUM-1:0][4:0]   intr_level_o;
output logic [CPU_NUM-1:0][7:0]   intr_vec_o;
input  logic [CPU_NUM-1:0]        inta_ack_i;

//---------------------------------
//INTCSEL interfaces
input logic [CPU_NUM-1:0]         sl_req_i;
input logic [CPU_NUM-1:0][4:0]    sl_level_i;
input logic [CPU_NUM-1:0][7:0]    sl_vec_i;
output logic [CPU_NUM-1:0]        cp_intack_nmi_o;
output logic [CPU_NUM-1:0]        cp_intack_err_o;
output logic [REG_NUM*32-1:0]     cp_intack_o;
output logic [CPU_NUM-1:0]        cp_intack_all_o;
//------------------------------------------------------------------------------
//internal signal
logic [CPU_NUM-1:0][REG_NUM*32-1:0]     cp_intack;

//------------------------------------------------------------------------------
//CPU IF generation
genvar k;
generate
    for(k=0; k<CPU_NUM; k=k+1)
        begin : intc_cpuif_label
        intc_one_cpuif     #(.CPU_NUM(CPU_NUM),
                             .REG_NUM(REG_NUM))   intc_one_cpuif_inst
            (
            .clk             (clk),
            .rst             (rst),//synchronous reset, active-high
            .sync_cpu_int_i  (sync_cpu_int_i),
            //---------------------------------
            //CPU interfaces
            .intr_req_o      (intr_req_o[k]),
            .intr_level_o    (intr_level_o[k]),
            .intr_vec_o      (intr_vec_o[k]),
            .inta_ack_i      (inta_ack_i[k]),
            
            //---------------------------------
            //INTCSEL interfaces
            .sl_req_i        (sl_req_i[k]),
            .sl_level_i      (sl_level_i[k]),
            .sl_vec_i        (sl_vec_i[k]),
            .cp_intack_nmi_o (cp_intack_nmi_o[k]),
            .cp_intack_err_o (cp_intack_err_o[k]),
            .cp_intack_o     (cp_intack[k]),
            .cp_intack_all_o (cp_intack_all_o[k])
            );
        end
endgenerate

//Generate output mux for cp_inack 
genvar k1;
generate
  for (k1 = CPU_NUM; k1 <= CPU_NUM; k1 = k1 + 1)
    begin : ap_inack
    if (k1 == 1)
        assign cp_intack_o = cp_intack[0];
    else if (k1 == 2)
        assign cp_intack_o = cp_intack[0] | cp_intack[1];
    else if (k1 == 3)
        assign cp_intack_o = cp_intack[0] | cp_intack[1] | cp_intack[2];
    else if (k1 == 4)
        assign cp_intack_o = cp_intack[0] | cp_intack[1] | cp_intack[2] |
                             cp_intack[3];
    end
endgenerate



endmodule 

