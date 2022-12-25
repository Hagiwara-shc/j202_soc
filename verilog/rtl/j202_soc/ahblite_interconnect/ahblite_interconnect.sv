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
// Filename    : ahblite_interconnect.v
// Description : AHB Lite master port which connects to AHB lite master
//
// Author      : Duong Nguyen
// Created On  : 10-6-2015
// History     : Initial 	
//             : 2022.12.25 K.Hagiwara Simplify for only one master
////////////////////////////////////////////////////////////////////////////////

module ahblite_interconnect
#(
  parameter AHB_AW  = 32,
  parameter AHB_DW  = 32,
  parameter MST_NUM = 1,//NUmber of master (only 1 is supported)
  parameter SLV_NUM = 8 //NUmber of slave
) (
  //---------------------------------
  // Clock and Reset
  input logic               clk,
  input logic               rst,
  //---------------------------------
  // Address of slaves
  input  logic [AHB_AW-1:0] addr_mask_i [SLV_NUM],
  input  logic [AHB_AW-1:0] addr_base_i [SLV_NUM],
  //---------------------------------
  //AHB slave ports (b/w masters)
  input  logic              hready_i    [MST_NUM],
  input  logic [AHB_AW-1:0] haddr_i     [MST_NUM],
  input  logic              hwrite_i    [MST_NUM],
  input  logic [1:0]        htrans_i    [MST_NUM],
  input  logic [2:0]        hsize_i     [MST_NUM],
  input  logic [2:0]        hburst_i    [MST_NUM],
  input  logic [3:0]        hprot_i     [MST_NUM],
  input  logic [AHB_DW-1:0] hwdata_i    [MST_NUM],
  input  logic              hmastlock_i [MST_NUM],
  output logic              hreadyout_o [MST_NUM],
  output logic              hresp_o     [MST_NUM],
  output logic [AHB_DW-1:0] hrdata_o    [MST_NUM],
  //---------------------------------
  //AHB master ports (b/w slaves)
  output logic              hready_o    [SLV_NUM],
  output logic              hsel_o      [SLV_NUM],
  output logic [AHB_AW-1:0] haddr_o     [SLV_NUM],
  output logic              hwrite_o    [SLV_NUM],
  output logic [1:0]        htrans_o    [SLV_NUM],
  output logic [2:0]        hsize_o     [SLV_NUM],
  output logic [2:0]        hburst_o    [SLV_NUM],
  output logic [3:0]        hprot_o     [SLV_NUM],
  output logic [AHB_DW-1:0] hwdata_o    [SLV_NUM],
  output logic              hmastlock_o [SLV_NUM],
  input  logic              hreadyout_i [SLV_NUM],
  input  logic              hresp_i     [SLV_NUM],
  input  logic [AHB_DW-1:0] hrdata_i    [SLV_NUM]
);

//------------------------------------------------------------------------------
//internal signal
logic                 m_hready    [MST_NUM];
logic                 m_hsel      [MST_NUM][SLV_NUM];
logic [AHB_AW-1:0]    m_haddr     [MST_NUM];
logic                 m_hwrite    [MST_NUM];
logic [1:0]           m_htrans    [MST_NUM];
logic [2:0]           m_hsize     [MST_NUM];
logic [2:0]           m_hburst    [MST_NUM];
logic [AHB_DW-1:0]    m_hwdata    [MST_NUM];
logic                 m_hmastlock [MST_NUM];
logic [3:0]           m_hprot     [MST_NUM];

logic                 s_hsel      [SLV_NUM][MST_NUM];
logic                 s_hreadyout [SLV_NUM];
logic                 s_hresp     [SLV_NUM];
logic [AHB_DW-1:0]    s_hrdata    [SLV_NUM];

//------------------------------------------------------------------------------
//Master port generation
genvar m, s;
generate
  for (m = 0; m < MST_NUM; m = m + 1) begin : g_m_port
    ahblite_m_port
      #(.AHB_AW(AHB_AW),
        .AHB_DW(AHB_DW),
        .SLV_NUM(SLV_NUM))
      ahblite_m_port_inst (
        .clk           (clk),
        .rst           (rst),
        //---------------------------------
        // Address map of slaves
        .s_addr_mask_i (addr_mask_i), //Slave address masks
        .s_addr_base_i (addr_base_i), //Slave base addresses
        //---------------------------------
        //AHB slave interface
        .hready_i      (hready_i[m]),
        .haddr_i       (haddr_i[m]),
        .hwrite_i      (hwrite_i[m]),
        .htrans_i      (htrans_i[m]),
        .hsize_i       (hsize_i[m]),
        .hburst_i      (hburst_i[m]),
        .hprot_i       (hprot_i[m]),
        .hwdata_i      (hwdata_i[m]),
        .hmastlock_i   (hmastlock_i[m]),
        .hreadyout_o   (hreadyout_o[m]),
        .hresp_o       (hresp_o[m]),
        .hrdata_o      (hrdata_o[m]),
        //---------------------------------
        //Internal master port
        .m_hready_o    (m_hready[m]),
        .m_hsel_o      (m_hsel[m]),
        .m_haddr_o     (m_haddr[m]),
        .m_hwrite_o    (m_hwrite[m]),
        .m_htrans_o    (m_htrans[m]),
        .m_hsize_o     (m_hsize[m]),
        .m_hburst_o    (m_hburst[m]),
        .m_hwdata_o    (m_hwdata[m]),
        .m_hmastlock_o (m_hmastlock[m]),
        .m_hprot_o     (m_hprot[m]),
        .m_hreadyout_i (s_hreadyout),
        .m_hresp_i     (s_hresp),
        .m_hrdata_i    (s_hrdata)
      );

    for (s = 0; s < SLV_NUM; s = s + 1) begin : g_hsel
      assign s_hsel[s][m] = m_hsel[m][s];
    end

  end
endgenerate

//------------------------------------------------------------------------------
//Slave port generation
genvar s1;
generate
  for (s1 = 0; s1 < SLV_NUM; s1 = s1 + 1) begin : g_s_port
    ahblite_s_port
      #(.AHB_AW(AHB_AW),
        .AHB_DW(AHB_DW),
        .MST_NUM(MST_NUM))
      ahblite_s_port_inst (
        .clk           (clk),
        .rst           (rst),
        //---------------------------------
        //Internal slave port (b/w internal master ports)
        .s_hready_i    (m_hready),
        .s_hsel_i      (s_hsel[s1]),
        .s_haddr_i     (m_haddr),
        .s_hwrite_i    (m_hwrite),
        .s_htrans_i    (m_htrans),
        .s_hsize_i     (m_hsize),
        .s_hburst_i    (m_hburst),
        .s_hprot_i     (m_hprot),
        .s_hwdata_i    (m_hwdata),
        .s_hmastlock_i (m_hmastlock),
        .s_hreadyout_o (s_hreadyout[s1]),
        .s_hresp_o     (s_hresp[s1]), 
        .s_hrdata_o    (s_hrdata[s1]),
        //---------------------------------
        //AHB master port (b/w a slave)
        .hready_o      (hready_o[s1]),
        .hsel_o        (hsel_o[s1]),
        .haddr_o       (haddr_o[s1]),
        .hwrite_o      (hwrite_o[s1]),
        .htrans_o      (htrans_o[s1]),
        .hsize_o       (hsize_o[s1]),
        .hburst_o      (hburst_o[s1]),
        .hprot_o       (hprot_o[s1]),
        .hwdata_o      (hwdata_o[s1]),
        .hmastlock_o   (hmastlock_o[s1]), 
        .hreadyout_i   (hreadyout_i[s1]),
        .hresp_i       (hresp_i[s1]),
        .hrdata_i      (hrdata_i[s1])
      );
  end
endgenerate

endmodule 

