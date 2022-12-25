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
// Filename    : intc_ahb.v
// Description : AHB slave state machine
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module intc_ahb
    (
    clk,
    rst,//synchronous reset, active-high
    //---------------------------------
    //AHB slave interface
    hsel_i,
    haddr_i,
    hwrite_i,
    htrans_i,
    hsize_i,
    hburst_i,
    hwdata_i,
    hready_i,
    hmastlock_i,
    hreadyout_o,
    hresp_o,
    hrdata_o,
    //---------------------------------
    //Register interface
    bs_sel_o,
    bs_wr_o,
    bs_addr_o,
    bs_wdata_o,
    rg_rdata_i
    );

////////////////////////////////////////////////////////////////////////////////
//parameter
parameter AHB_AW  = 6'd32;
parameter AHB_DW  = 6'd32;


////////////////////////////////////////////////////////////////////////////////
// Port declarations
input logic               clk;
input logic               rst;
//---------------------------------
//AHB inputs
input logic               hsel_i;
input logic [AHB_AW-1:0]  haddr_i;
input logic               hwrite_i;
input logic  [1:0]        htrans_i;
input logic  [2:0]        hsize_i;
input logic  [2:0]        hburst_i;
input logic  [AHB_DW-1:0] hwdata_i;
input logic               hready_i;
input logic               hmastlock_i;
output logic              hreadyout_o;
output logic [1:0]        hresp_o;
output logic [AHB_DW-1:0] hrdata_o;
//---------------------------------
//Register interface
output logic              bs_sel_o;
output logic              bs_wr_o;
output logic [31:0]       bs_addr_o;
output logic [31:0]       bs_wdata_o;
input logic [31:0]        rg_rdata_i;
////////////////////////////////////////////////////////////////////////////////
//internal signal
logic                     trans_vld;
logic                     size_vld;
logic                     burst_vld;
logic                     trans_type_vld;
logic                     nxt_bs_sel;
logic                     bs_sel;
logic [31:0]              nxt_bs_addr;
logic [31:0]              bs_addr;
logic                     nxt_bs_wr;
logic                     bs_wr;


//------------------------------------------------------------------------------
//Checking transfer condition
//------------------------------------------------------------------------------
assign trans_vld = hsel_i & hready_i;//transfer valid
assign size_vld = (hsize_i == 3'b010);//32bit word
assign burst_vld = (hburst_i == 3'b000);//only support single burst
assign trans_type_vld = (htrans_i == 2'b10);//only support NONSEQUENTIAL
assign nxt_bs_sel = trans_vld & size_vld & burst_vld & trans_type_vld;


dff_rst  #(1)  dff_bs_sel  (clk,rst,nxt_bs_sel,bs_sel);

//------------------------------------------------------------------------------
//Reg Address
//------------------------------------------------------------------------------
assign nxt_bs_addr = haddr_i;

dff_rst  #(32)  dff_bs_addr  (clk,rst,nxt_bs_addr,bs_addr);

assign bs_addr_o = bs_addr;
//------------------------------------------------------------------------------
//Write/read signal
//------------------------------------------------------------------------------
assign nxt_bs_wr = hwrite_i;

dff_rst  #(32)  dff_bs_wr  (clk,rst,nxt_bs_wr,bs_wr);

assign bs_wr_o = bs_wr;
//------------------------------------------------------------------------------
//Register write data
//------------------------------------------------------------------------------
assign bs_wdata_o = hwdata_i;

//------------------------------------------------------------------------------
//HREADOUT
//------------------------------------------------------------------------------
assign hreadyout_o = 1'b1; //All register return read data after 1 clk

//------------------------------------------------------------------------------
//AHB read data
//------------------------------------------------------------------------------
assign hrdata_o = rg_rdata_i;

endmodule 

