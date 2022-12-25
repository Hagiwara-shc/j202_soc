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
// Filename    : ahblite_s_port.sv
// Description : AHB Lite slave port which connects to AHB lite slave
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//             : 2022.12.25 K.Hagiwara Simplify for only one master
////////////////////////////////////////////////////////////////////////////////

module ahblite_s_port
#(
  parameter AHB_AW  = 32,
  parameter AHB_DW  = 32,
  parameter MST_NUM = 1 // Number of master (only 1 is supported)
) (
  //---------------------------------
  // Clock and Reset
  input logic                 clk,
  input logic                 rst,
  //---------------------------------
  // Internal slave port (b/w internal master ports)
  input logic                 s_hready_i    [MST_NUM],
  input logic                 s_hsel_i      [MST_NUM],
  input logic [AHB_AW-1:0]    s_haddr_i     [MST_NUM],
  input logic                 s_hwrite_i    [MST_NUM],
  input logic [1:0]           s_htrans_i    [MST_NUM],
  input logic [2:0]           s_hsize_i     [MST_NUM],
  input logic [2:0]           s_hburst_i    [MST_NUM],
  input logic [3:0]           s_hprot_i     [MST_NUM],
  input logic [AHB_DW-1:0]    s_hwdata_i    [MST_NUM],
  input logic                 s_hmastlock_i [MST_NUM],
  output logic                s_hreadyout_o,
  output logic                s_hresp_o,
  output logic [AHB_DW-1:0]   s_hrdata_o,  
  //---------------------------------
  //AHB master port (b/w a slave)
  output logic                hready_o,
  output logic                hsel_o,
  output logic [AHB_AW-1:0]   haddr_o,
  output logic                hwrite_o,
  output logic [1:0]          htrans_o,
  output logic [2:0]          hsize_o,
  output logic [2:0]          hburst_o,
  output logic [3:0]          hprot_o,
  output logic [AHB_DW-1:0]   hwdata_o,
  output logic                hmastlock_o,
  input logic                 hreadyout_i,
  input logic                 hresp_i,
  input logic [AHB_DW-1:0]    hrdata_i
);

//------------------------------------------------------------------------------
// Only one master is supported, so just assign.
assign hready_o    = s_hready_i[0];
assign hsel_o      = s_hsel_i[0];
assign haddr_o     = s_haddr_i[0];
assign hwrite_o    = s_hwrite_i[0];
assign htrans_o    = s_htrans_i[0];
assign hsize_o     = s_hsize_i[0];
assign hburst_o    = s_hburst_i[0];
assign hprot_o     = s_hprot_i[0];
assign hwdata_o    = s_hwdata_i[0];
assign hmastlock_o = s_hmastlock_i[0];

assign s_hreadyout_o = hreadyout_i;
assign s_hresp_o     = hresp_i;
assign s_hrdata_o    = hrdata_i;

endmodule 
