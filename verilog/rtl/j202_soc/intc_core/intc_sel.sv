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
// Filename    : intc_sel.v
// Description : Interrupt selection
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module intc_sel
    (
    clk,
    rst,//synchronous reset, active-high
    sync_cpu_int_i,
    //---------------------------------
    //CPU IF
    cp_intack_all_i,
    sl_req_o,
    sl_level_o,
    sl_vec_o,
    //---------------------------------
    //Register interface
    in_intreq_nmi_i,
    in_intreq_err_i,
    in_intreq_i,
    rg_itgt_i,
    rg_ipr_i
    );

////////////////////////////////////////////////////////////////////////////////
//parameter
parameter CPU_NUM = 1;
parameter REG_NUM = 1;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input logic                           clk;
input logic                           rst;
input logic                           sync_cpu_int_i;
//---------------------------------
//CPU IF
input logic  [CPU_NUM-1:0]            cp_intack_all_i;
output logic [CPU_NUM-1:0]            sl_req_o;
output logic [CPU_NUM-1:0][4:0]       sl_level_o;
output logic [CPU_NUM-1:0][7:0]       sl_vec_o;
//---------------------------------
//Register interface
input logic  [CPU_NUM-1:0]            in_intreq_nmi_i;
input logic [CPU_NUM-1:0]             in_intreq_err_i;
input logic [REG_NUM*32-1:0]          in_intreq_i;
input logic [3:0][REG_NUM*32-1:0]     rg_itgt_i;
input logic [REG_NUM*32-1:0][3:0]     rg_ipr_i;
//------------------------------------------------------------------------------
//internal signal




//------------------------------------------------------------------------------
//Checking transfer condition
//------------------------------------------------------------------------------


genvar k;
generate
    for(k=0; k<CPU_NUM; k=k+1)
        begin : intc_sel_cpu
        intc_sel_cpu   #(.REG_NUM(REG_NUM))   intc_sel_cpu_00
            (
            .clk             (clk),
            .rst             (rst),//synchronous reset, active-high
            .sync_cpu_int_i  (sync_cpu_int_i),
            //---------------------------------
            //CPU IF
            .cp_intack_all_i (cp_intack_all_i[k]),
            .sl_req_o        (sl_req_o[k]),
            .sl_level_o      (sl_level_o[k]),
            .sl_vec_o        (sl_vec_o[k]),
            //---------------------------------
            //Register interface
            .in_intreq_nmi_i (in_intreq_nmi_i[k]),
            .in_intreq_err_i (in_intreq_err_i[k]),
            .in_intreq_i     (in_intreq_i),
            .rg_itgt_i       (rg_itgt_i[k]),
            .rg_ipr_i        (rg_ipr_i)
            );
        end
endgenerate
endmodule 

