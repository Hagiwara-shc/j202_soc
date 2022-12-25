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
// Filename    : intc_sel_cpu.v
// Description : Interrupt selection for one cpu
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module intc_sel_cpu
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

//------------------------------------------------------------------------------
//parameter
parameter REG_NUM = 1;

//------------------------------------------------------------------------------
// Port declarations
//------------------------------------------------------------------------------
input                       clk;
input                       rst;
input logic                 sync_cpu_int_i;

//---------------------------------
//CPU IF
input                       cp_intack_all_i;
output                      sl_req_o;
output [4:0]                sl_level_o;
output [7:0]                sl_vec_o;
//---------------------------------
//Register interface
input                       in_intreq_nmi_i;
input                       in_intreq_err_i;
input [REG_NUM*32-1:0]      in_intreq_i;
input [REG_NUM*32-1:0]      rg_itgt_i;
input [REG_NUM*32-1:0][3:0] rg_ipr_i;

//------------------------------------------------------------------------------
//Internal variables
logic [13:0]                dat_nmi_err;
logic [12:0]                dat_int;
logic [REG_NUM*32-1:0][4:0] req_ipr;
logic [REG_NUM*32-1:0]      req;
logic                       sl_req;



//------------------------------------------------------------------------------
//Checking CPU target
assign req = in_intreq_i & rg_itgt_i;

genvar k;
generate
    for(k=0; k<REG_NUM*32; k=k+1)
        begin : req_ipr_label
        assign req_ipr[k] = {req[k],rg_ipr_i[k]};
        end
endgenerate
//------------------------------------------------------------------------------
//ERR or NMI selection
intc_2to1_sel #(.DW(14),
                .PRI_DW(5))   intc_2to1_sel_00
    (
    //---------------------------------
    //Input
    .dat0_i ({in_intreq_err_i,5'd16,8'd9}),
    .dat1_i ({in_intreq_nmi_i,5'd16,8'd11}),
    //---------------------------------
    //Register interface
    .dat_o  (dat_nmi_err)
    );
//------------------------------------------------------------------------------
//Normal interrupt selection

intc_32to1_sel    #(.DW(5),
                    .PRI_DW(4))   intc_32to1_sel_00
    (
    //---------------------------------
    //Input
    .dat_i   (req_ipr),
    //---------------------------------
    //Register interface
    .dat_o   (dat_int)
    );
//------------------------------------------------------------------------------
//Output selection
intc_2to1_sel #(.DW(14),
                .PRI_DW(5))   intc_2to1_sel_01
    (
    //---------------------------------
    //Input
    .dat0_i (dat_nmi_err),
    .dat1_i ({dat_int[12],{1'b0,dat_int[11:8]},dat_int[7:0]}),
    //---------------------------------
    //Register interface
    .dat_o  ({sl_req,sl_level_o,sl_vec_o})
    );

assign sl_req_o = sl_req & (~(sync_cpu_int_i & cp_intack_all_i));

endmodule 

