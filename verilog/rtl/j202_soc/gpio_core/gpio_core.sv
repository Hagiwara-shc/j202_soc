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
// Filename    : gpio_core.sv
// Description : APB based GPIO IP.
//
// Author      : Duong Nguyen
// Created On  : 29-nov-2017
// History     : Initial 	
//             : 05-24-2018 K.Hagiwara, Change width of pprot_i to 3bit
//
////////////////////////////////////////////////////////////////////////////////

module gpio_core
    (
    clk,
    rst,//synchronous reset, active-high
    //---------------------------------
    //APB bus interface
    psel_i,
    pwrite_i,
    penable_i,
    paddr_i,
    pwdata_i,
    pstrb_i,
    pprot_i,
    prdata_o,
    pslverr_o,
    pready_o,
    //--------------------------------------
    //Output config
    gpio_o,
    gpio_i,
    gpio_en_o,
    //--------------------------------------
    //Interrupt
    gpio_int_o
    );

//------------------------------------------------------------------------------
//parameter

parameter AW  = 32;
parameter DW  = 32;
//------------------------------------------------------------------------------
// Port declarations
input logic                      clk;
input logic                      rst;
//---------------------------------
//APB interfaces
input logic                      psel_i;
input logic                      pwrite_i;
input logic                      penable_i;
input logic [AW-1:0]             paddr_i;
input logic [DW-1:0]             pwdata_i;
input logic [2:0]                pprot_i;
input logic [3:0]                pstrb_i;
output logic [DW-1:0]            prdata_o;
output logic                     pslverr_o;
output logic                     pready_o;
//--------------------------------------
//Output config
output logic [DW-1:0]            gpio_o;
input  logic [DW-1:0]            gpio_i;
output logic [DW-1:0]            gpio_en_o;
//--------------------------------------
//interrupt
output logic                     gpio_int_o;

//------------------------------------------------------------------------------
//Internal signal
logic [DW-1:0]                   reg_wdata;
logic                            reg_wen;
logic                            reg_ren;
logic [AW-1:0]                   reg_addr;
logic [DW-1:0]                   reg_rdata;

//------------------------------------------------------------------------------
//GPIO APB interface module
gpio_apb    #(.AW(AW),
              .DW(DW))    gpio_apb_00
    (
    .clk         (clk),
    .rst         (rst),//synchronous reset, active-high
    //---------------------------------
    //APB bus interface
    .psel_i      (psel_i   ),
    .pwrite_i    (pwrite_i ),
    .penable_i   (penable_i),
    .paddr_i     (paddr_i  ),
    .pwdata_i    (pwdata_i ),
    .pstrb_i     (pstrb_i  ),
    .pprot_i     (pprot_i  ),
    .prdata_o    (prdata_o ),
    .pslverr_o   (pslverr_o),
    .pready_o    (pready_o ),
    //---------------------------------
    //Register interface
    .reg_wdata_o (reg_wdata),
    .reg_wen_o   (reg_wen  ),
    .reg_ren_o   (reg_ren  ),
    .reg_addr_o  (reg_addr ),
    .reg_rdata_i (reg_rdata)
    );

//------------------------------------------------------------------------------
//GPIO registers
gpio_regs   #(.ADDR_W(AW),
              .DATA_W(DW))   gpio_regs_00
    (
    .clk        (clk      ),
    .rst        (rst      ),
    //--------------------------------------
    //Internal inf
    .addr_i     (reg_addr ),
    .wdata_i    (reg_wdata), 
    .wen_i      (reg_wen  ),
    .ren_i      (reg_ren  ), 
    .rdata_o    (reg_rdata), 
    //--------------------------------------
    //Output config
    .gpio_o     (gpio_o   ),
    .gpio_i     (gpio_i   ),
    .gpio_en_o  (gpio_en_o),
    //--------------------------------------
    //Interrupt
    .gpio_int_o (gpio_int_o)
    );

endmodule 

