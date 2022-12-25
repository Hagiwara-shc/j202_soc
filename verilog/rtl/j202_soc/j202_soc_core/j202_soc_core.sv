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
// Filename    : j202_soc_core.sv
// Description : System on chip.
//               J22 cpu
//               AHB-Lite interconnect
//               AHB-Lite-to-APB bridge
//               CMT
//               INTC
//               GPIO
//               UART
//               BLDC PWM
//               Boot ROM
//               (AHB memory)
//               (APB memory)
//
// Author      : Duong Nguyen
// Created On  : August 9, 2017
// History     : Initial 	
//             : 2022.12.25 K.Hagiwara
//                 Replace AHB interconnect and AHB->APB bridges with SHC's design
//
////////////////////////////////////////////////////////////////////////////////

import cpu_pkg::*;

module j202_soc_core
    (
    clk,
    rst_n,
    md_boot,
    //---------------------------------
    //GPIO
    gpio_i,
    gpio_o,
    gpio_en_o,
    //---------------------------------
    //BLDC PWM
`ifdef HAVE_BLDC
    pwm_posa_o,
    pwm_nega_o,
    pwm_posb_o,
    pwm_negb_o,
    pwm_posc_o,
    pwm_negc_o,
//  adc_cmd_vld_o,
//  adc_cmd_ch_o,
//  adc_cmd_sop_o,
//  adc_cmd_eop_o,
//  adc_cmd_ready_i,
//  adc_rsp_sop_i,
//  adc_rsp_eop_i,
//  adc_rsp_vld_i,
//  adc_rsp_ch_i,
//  adc_rsp_data_i,
    over_cur_i,
    hall_i,	
`endif
    //---------------------------------
    //UART
    uart_rxd_i,
    uart_cts_i,
    uart_txd_o,
    uart_rts_o,
    //---------------------------------
    //QSPI
    qspi_sck_o,
    qspi_cs_n_o,
    qspi_dat_o,
    qspi_dat_oe,
    qspi_dat_i
    );

//------------------------------------------------------------------------------
//parameter
parameter CPU_NUM = 1;
parameter INTC_REG_NUM = 1;
parameter SW_INT_NUM = 16;

//------------------------------------------------------------------------------
// Port declarations
input logic         clk;        // Clock
input logic         rst_n;      // Reset (low active)
input logic  [1:0]  md_boot;    // 00:Boot ROM, 01:TCM0, 10:SPI Flash, 11:Boot ROM

//---------------------------------
//GPIO
input  logic [31:0] gpio_i;
output logic [31:0] gpio_o;
output logic [31:0] gpio_en_o;

//---------------------------------
//BLDC PWM
`ifdef HAVE_BLDC
output logic        pwm_posa_o;
output logic        pwm_nega_o;
output logic        pwm_posb_o;
output logic        pwm_negb_o;
output logic        pwm_posc_o;
output logic        pwm_negc_o;
//output logic        adc_cmd_vld_o;
//output logic [4:0]  adc_cmd_ch_o;
//output logic        adc_cmd_sop_o;
//output logic        adc_cmd_eop_o;
//input logic         adc_cmd_ready_i;
//input logic         adc_rsp_sop_i;
//input logic         adc_rsp_eop_i;
//input logic         adc_rsp_vld_i;
//input logic [4:0]   adc_rsp_ch_i;
//input logic [11:0]  adc_rsp_data_i;
input logic         over_cur_i;
input logic [2:0]   hall_i;
`endif

//---------------------------------
//UART
input logic         uart_rxd_i;
input logic         uart_cts_i;
output logic        uart_txd_o;
output logic        uart_rts_o;

//---------------------------------
//QSPI
output logic        qspi_sck_o;
output logic        qspi_cs_n_o;
output logic [3:0]  qspi_dat_o;  // output data
output logic [3:0]  qspi_dat_oe; // output enable (high-active)
input  logic [3:0]  qspi_dat_i;  // input data

//------------------------------------------------------------------------------
// Reset synchronizer
logic   rst, rst0, rst1;

always_ff @(posedge clk) begin
  rst0 <= ~rst_n;
  rst1 <= rst0;
  rst  <= rst1;
end

// AHB-Lite interconnect
localparam MD_BOOT_ROM  = 2'b00;
localparam MD_BOOT_TCM0 = 2'b01;
localparam MD_BOOT_SPI  = 2'b10;
localparam MD_BOOT_ROM2 = 2'b11;

localparam HADDR_SIZE  = 32;
localparam HDATA_SIZE  = 32;
localparam PADDR_SIZE  = 32;
localparam PDATA_SIZE  = 32;

localparam AHB_MASTERS = 1; //number of AHB Masters
`ifdef HAVE_APBMEM
localparam AHB_SLAVES  = 8; //number of AHB slaves
`else
localparam AHB_SLAVES  = 7; //number of AHB slaves
`endif

localparam AHB_MST_CPU0 = 0;

localparam AHB_SLV_APB0 = 0;
localparam AHB_SLV_APB1 = 1;
localparam AHB_SLV_APB2 = 2;
localparam AHB_SLV_AQU  = 3;
localparam AHB_SLV_MEM  = 4;
localparam AHB_SLV_QSPI = 5;
localparam AHB_SLV_BROM = 6;
`ifdef HAVE_APBMEM
localparam AHB_SLV_APB3 = 7;
`endif

// Address map of AHB-Lite slaves
logic [HADDR_SIZE-1:0]  AHB_SLV_ADDR_MASK [AHB_SLAVES];
logic [HADDR_SIZE-1:0]  AHB_SLV_ADDR_BASE [AHB_SLAVES];

// APB0 (CMT)
assign AHB_SLV_ADDR_MASK[AHB_SLV_APB0] = 32'hfffff000;
assign AHB_SLV_ADDR_BASE[AHB_SLV_APB0] = 32'habcc0000;

// APB1 (INTC)
assign AHB_SLV_ADDR_MASK[AHB_SLV_APB1] = 32'hfffff000;
assign AHB_SLV_ADDR_BASE[AHB_SLV_APB1] = 32'habcc1000;

// APB2 (GPIO)
assign AHB_SLV_ADDR_MASK[AHB_SLV_APB2] = 32'hfffff000;
assign AHB_SLV_ADDR_BASE[AHB_SLV_APB2] = 32'habcc2000;

// ahb2aqu (UART, PWM)
assign AHB_SLV_ADDR_MASK[AHB_SLV_AQU]  = 32'hffff0000;
assign AHB_SLV_ADDR_BASE[AHB_SLV_AQU]  = 32'habcd0000;

// QSPI
assign AHB_SLV_ADDR_MASK[AHB_SLV_QSPI] = 32'hfe000000;
assign AHB_SLV_ADDR_BASE[AHB_SLV_QSPI] = (md_boot == MD_BOOT_SPI) ? 32'h00000000: 32'h20000000;

// ahbmem
assign AHB_SLV_ADDR_MASK[AHB_SLV_MEM]  = 32'hfffc0000;
assign AHB_SLV_ADDR_BASE[AHB_SLV_MEM]  = 32'h10000000;

// Boot ROM
assign AHB_SLV_ADDR_MASK[AHB_SLV_BROM] = 32'hfffc0000;
assign AHB_SLV_ADDR_BASE[AHB_SLV_BROM] = (md_boot == MD_BOOT_ROM || md_boot == MD_BOOT_ROM2) ? 32'h00000000: 32'h30000000;

`ifdef HAVE_APBMEM
// APB3 (APB memory)
assign AHB_SLV_ADDR_MASK[AHB_SLV_APB3] = 32'hffff0000;
assign AHB_SLV_ADDR_BASE[AHB_SLV_APB3] = 32'habce0000;
`endif

//logic                   HRESETn;
//logic                   HCLK;
logic  [           2:0] mst_priority  [AHB_MASTERS];
logic                   mst_HSEL      [AHB_MASTERS];
logic  [HADDR_SIZE-1:0] mst_HADDR     [AHB_MASTERS];
logic  [HDATA_SIZE-1:0] mst_HWDATA    [AHB_MASTERS];
logic  [HDATA_SIZE-1:0] mst_HRDATA    [AHB_MASTERS];
logic                   mst_HWRITE    [AHB_MASTERS];
logic  [           2:0] mst_HSIZE     [AHB_MASTERS];
logic  [           2:0] mst_HBURST    [AHB_MASTERS];
logic  [           3:0] mst_HPROT     [AHB_MASTERS];
logic  [           1:0] mst_HTRANS    [AHB_MASTERS];
logic                   mst_HMASTLOCK [AHB_MASTERS];
logic                   mst_HREADYOUT [AHB_MASTERS];
logic                   mst_HREADY    [AHB_MASTERS];
logic                   mst_HRESP     [AHB_MASTERS];

logic  [HADDR_SIZE-1:0] slv_addr_mask [AHB_SLAVES];
logic  [HADDR_SIZE-1:0] slv_addr_base [AHB_SLAVES];
logic                   slv_HSEL      [AHB_SLAVES];
logic  [HADDR_SIZE-1:0] slv_HADDR     [AHB_SLAVES];
logic  [HDATA_SIZE-1:0] slv_HWDATA    [AHB_SLAVES];
logic  [HDATA_SIZE-1:0] slv_HRDATA    [AHB_SLAVES];
logic                   slv_HWRITE    [AHB_SLAVES];
logic  [           2:0] slv_HSIZE     [AHB_SLAVES];
logic  [           2:0] slv_HBURST    [AHB_SLAVES];
logic  [           3:0] slv_HPROT     [AHB_SLAVES];
logic  [           1:0] slv_HTRANS    [AHB_SLAVES];
logic                   slv_HMASTLOCK [AHB_SLAVES];
logic                   slv_HREADYOUT [AHB_SLAVES];
logic                   slv_HREADY    [AHB_SLAVES];
logic                   slv_HRESP     [AHB_SLAVES];

//------------------------------------------------------------------------------
// AHB-Lite-APB bridge <-> APB slave(s)
`ifdef HAVE_APBMEM
localparam APB_SLAVES = 4; //number of APB slaves
`else
localparam APB_SLAVES = 3; //number of APB slaves
`endif

localparam APB_SLV_CMT  = 0;
localparam APB_SLV_INTC = 1;
localparam APB_SLV_GPIO = 2;
`ifdef HAVE_APBMEM
localparam APB_SLV_MEM  = 3;
`endif

logic                   psel    [APB_SLAVES];
logic                   penable [APB_SLAVES];
logic  [           2:0] pprot   [APB_SLAVES];
logic                   pwrite  [APB_SLAVES];
logic  [PDATA_SIZE/8-1:0] pstrb [APB_SLAVES];
logic  [PADDR_SIZE-1:0] paddr   [APB_SLAVES];
logic  [PDATA_SIZE-1:0] pwdata  [APB_SLAVES];
logic  [PDATA_SIZE-1:0] prdata  [APB_SLAVES];
logic                   pready  [APB_SLAVES];
logic                   pslverr [APB_SLAVES];


//------------------------------------------------------------------------------
//internal signal
//logic [CPU_NUM-1:0]              in_intreq_err;
//logic [INTC_REG_NUM*32-1:0]      in_intreq;

CpuMode                          cpumode;
IntA                             inta; // Interrupt acknowledge
IntR                             intr; // Interrupt request
MemC [1:0]                       memc; // TCM command
MemR [1:0]                       memr; // TCM responcse
AhbC                             ahbcm[AHB_MASTERS]; // AHB command from master(s)
AhbR                             ahbrm[AHB_MASTERS]; // AHB response to master(s)
AhbC                             ahbcs[AHB_SLAVES];  // AHB command to slaves(s)
AhbR                             ahbrs[AHB_SLAVES];  // AHB response from slaves(s)
AquC                             aquc; // WishBone command
AquR                             aqur; // WishBone response

logic                            cmt0_int;
logic                            cmt1_int;
logic                            bldc_int;
logic                            gpio_int;
logic                            qspi_int;

//------------------------------------------------------------------------------
//CPU Mode control 
assign cpumode.tcm[1:0] = 2'b11;    // TCMs are always enabled

//------------------------------------------------------------------------------
//J22 CPU
cpu j22_cpu (.*, .ahbr(ahbrm[AHB_MST_CPU0]), .ahbc(ahbcm[AHB_MST_CPU0]));

//------------------------------------------------------------------------------
//TCMs
memory #(.AW(`TCM0_AW)) memory0(.clk(clk), .memc(memc[0]), .memr(memr[0]));
`ifdef HAVE_TCM1
  memory #(.AW(`TCM1_AW)) memory1(.clk(clk), .memc(memc[1]), .memr(memr[1]));
`else
  assign memr[1].q = 32'd0;
`endif

//-------------------------------------------------------------------------------
//AHB-Lite Interconnect
genvar m, s;
generate
  // Master(s) <-> Interconnect
  for (m = 0; m < AHB_MASTERS; m++) begin : ahb_master_conn
    assign mst_priority  [m] = 3'b001;
    assign mst_HREADY    [m] = mst_HREADYOUT[m];
    assign mst_HSEL      [m] = 1'b1;
    assign mst_HADDR     [m] = ahbcm[m].HADDR;
    assign mst_HWDATA    [m] = ahbcm[m].HWDATA;
    assign mst_HWRITE    [m] = ahbcm[m].HWRITE;
    assign mst_HSIZE     [m] = ahbcm[m].HSIZE;
    assign mst_HBURST    [m] = ahbcm[m].HBURST;
    assign mst_HPROT     [m] = ahbcm[m].HPROT;
    assign mst_HTRANS    [m] = ahbcm[m].HTRANS;
    assign mst_HMASTLOCK [m] = ahbcm[m].HMASTLOCK;
    assign ahbrm[m].HREADY   = mst_HREADYOUT[m];
    assign ahbrm[m].HRDATA   = mst_HRDATA[m];
    assign ahbrm[m].HRESP    = HRESP_T'(mst_HRESP[m]);
  end

  // Slaves(s) <-> Interconnect
  for (s = 0; s < AHB_SLAVES; s++) begin : ahb_slave_conn
    assign slv_addr_mask[s]    = AHB_SLV_ADDR_MASK[s];
    assign slv_addr_base[s]    = AHB_SLV_ADDR_BASE[s];
    assign ahbcs[s].HREADY     = slv_HREADY[s];
    assign ahbcs[s].HSEL       = slv_HSEL[s];
    assign ahbcs[s].HADDR      = slv_HADDR[s];
    assign ahbcs[s].HWDATA     = slv_HWDATA[s];
    assign ahbcs[s].HWRITE     = slv_HWRITE[s];
    assign ahbcs[s].HSIZE      = slv_HSIZE[s];
    assign ahbcs[s].HBURST     = HBURST_T'(slv_HBURST[s]);
    assign ahbcs[s].HPROT      = slv_HPROT[s];
    assign ahbcs[s].HTRANS     = HTRANS_T'(slv_HTRANS[s]);
    assign ahbcs[s].HMASTLOCK  = slv_HMASTLOCK[s];
    assign slv_HRDATA[s]       = ahbrs[s].HRDATA;
    assign slv_HREADYOUT[s]    = ahbrs[s].HREADY;
    assign slv_HRESP[s]        = ahbrs[s].HRESP;
  end
endgenerate

ahblite_interconnect #(.MST_NUM(AHB_MASTERS), .SLV_NUM(AHB_SLAVES))
  ahblite_interconnect (
     .rst         (rst),
     .clk         (clk),
     //---------------------------------
     // Address of slaves
     .addr_mask_i (slv_addr_mask),
     .addr_base_i (slv_addr_base),
     //---------------------------------
     // AHB slave ports (b/w masters)
     .hready_i    (mst_HREADY),
     .haddr_i     (mst_HADDR),
     .hwrite_i    (mst_HWRITE),
     .htrans_i    (mst_HTRANS),
     .hsize_i     (mst_HSIZE),
     .hburst_i    (mst_HBURST),
     .hprot_i     (mst_HPROT),
     .hwdata_i    (mst_HWDATA),
     .hmastlock_i (mst_HMASTLOCK),
     .hreadyout_o (mst_HREADYOUT),
     .hresp_o     (mst_HRESP),
     .hrdata_o    (mst_HRDATA),
     //---------------------------------
     // AHB master ports (b/w slaves)
     .hready_o    (slv_HREADY),
     .hsel_o      (slv_HSEL),
     .haddr_o     (slv_HADDR),
     .hwrite_o    (slv_HWRITE),
     .htrans_o    (slv_HTRANS),
     .hsize_o     (slv_HSIZE),
     .hburst_o    (slv_HBURST),
     .hprot_o     (slv_HPROT),
     .hwdata_o    (slv_HWDATA),
     .hmastlock_o (slv_HMASTLOCK),
     .hreadyout_i (slv_HREADYOUT),
     .hresp_i     (slv_HRESP),
     .hrdata_i    (slv_HRDATA)
  );

//-------------------------------------------------------------------------------
//AHB-to-APB bridge <-> CMT
ahb2apb_bridge #(.APB_AW(PADDR_SIZE), .APB_DW(PDATA_SIZE)) ahb2apb_00 (
     // AHB Slave Interface
     .rst_n        (~rst),
     .clk          (clk),
     .hsel_i       (ahbcs[AHB_SLV_APB0].HSEL),
     .haddr_i      (ahbcs[AHB_SLV_APB0].HADDR),
     .hwdata_i     (ahbcs[AHB_SLV_APB0].HWDATA),
     .hrdata_o     (ahbrs[AHB_SLV_APB0].HRDATA),
     .hwrite_i     (ahbcs[AHB_SLV_APB0].HWRITE),
     .hsize_i      (ahbcs[AHB_SLV_APB0].HSIZE),
     .hburst_i     (ahbcs[AHB_SLV_APB0].HBURST),
     .hprot_i      (ahbcs[AHB_SLV_APB0].HPROT),
     .htrans_i     (ahbcs[AHB_SLV_APB0].HTRANS),
     .hmastlock_i  (ahbcs[AHB_SLV_APB0].HMASTLOCK),
     .hreadyout_o  (ahbrs[AHB_SLV_APB0].HREADY),
     .hready_i     (ahbcs[AHB_SLV_APB0].HREADY),
     .hresp_o      (ahbrs[AHB_SLV_APB0].HRESP),
     // APB Master Interface
     .psel_o       (psel[APB_SLV_CMT]),
     .penable_o    (penable[APB_SLV_CMT]),
     .pprot_o      (pprot[APB_SLV_CMT]),
     .pwrite_o     (pwrite[APB_SLV_CMT]),
     .pstrb_o      (pstrb[APB_SLV_CMT]),
     .paddr_o      (paddr[APB_SLV_CMT]),
     .pwdata_o     (pwdata[APB_SLV_CMT]),
     .prdata_i     (prdata[APB_SLV_CMT]),
     .pready_i     (pready[APB_SLV_CMT]),
     .pslverr_i    (pslverr[APB_SLV_CMT]));

cmt_core cmt_core_00 (
    .clk        (clk),
    .rst_n      (~rst),
    //--------------------------------------
    //APB slave inf
    .psel_i     (psel[APB_SLV_CMT]),
    .pwrite_i   (pwrite[APB_SLV_CMT]),
    .penable_i  (penable[APB_SLV_CMT]),
    .paddr_i    (paddr[APB_SLV_CMT][7:0]),
    .pwdata_i   (pwdata[APB_SLV_CMT]),
    .prdata_o   (prdata[APB_SLV_CMT]),
    .pslverr_o  (pslverr[APB_SLV_CMT]),
    .pready_o   (pready[APB_SLV_CMT]),
    //--------------------------------------
    //Interrupt
    .cmt0_int_o (cmt0_int),
    .cmt1_int_o (cmt1_int));

//-------------------------------------------------------------------------------
//AHB-to-APB bridge <-> INTC
ahb2apb_bridge #(.APB_AW(PADDR_SIZE), .APB_DW(PDATA_SIZE)) ahb2apb_01 (
     // AHB Slave Interface
     .rst_n        (~rst),
     .clk          (clk),
     .hsel_i       (ahbcs[AHB_SLV_APB1].HSEL),
     .haddr_i      (ahbcs[AHB_SLV_APB1].HADDR),
     .hwdata_i     (ahbcs[AHB_SLV_APB1].HWDATA),
     .hrdata_o     (ahbrs[AHB_SLV_APB1].HRDATA),
     .hwrite_i     (ahbcs[AHB_SLV_APB1].HWRITE),
     .hsize_i      (ahbcs[AHB_SLV_APB1].HSIZE),
     .hburst_i     (ahbcs[AHB_SLV_APB1].HBURST),
     .hprot_i      (ahbcs[AHB_SLV_APB1].HPROT),
     .htrans_i     (ahbcs[AHB_SLV_APB1].HTRANS),
     .hmastlock_i  (ahbcs[AHB_SLV_APB1].HMASTLOCK),
     .hreadyout_o  (ahbrs[AHB_SLV_APB1].HREADY),
     .hready_i     (ahbcs[AHB_SLV_APB1].HREADY),
     .hresp_o      (ahbrs[AHB_SLV_APB1].HRESP),
     // APB Master Interface
     .psel_o       (psel[APB_SLV_INTC]),
     .penable_o    (penable[APB_SLV_INTC]),
     .pprot_o      (pprot[APB_SLV_INTC]),
     .pwrite_o     (pwrite[APB_SLV_INTC]),
     .pstrb_o      (pstrb[APB_SLV_INTC]),
     .paddr_o      (paddr[APB_SLV_INTC]),
     .pwdata_o     (pwdata[APB_SLV_INTC]),
     .prdata_i     (prdata[APB_SLV_INTC]),
     .pready_i     (pready[APB_SLV_INTC]),
     .pslverr_i    (pslverr[APB_SLV_INTC]));

// INTC
intc_core    #(.CPU_NUM(CPU_NUM),
               .REG_NUM(INTC_REG_NUM),
               .SW_INT_NUM(SW_INT_NUM))   intc_core_00
    (
    .clk_cpu        (clk),
    .clk_bus        (clk),
    .clk_int        (clk),
    .rst            (rst),//synchronous reset, active-high
    .sync_cpu_int_i (1'b1),
    .sync_bus_int_i (1'b1),
    //---------------------------------
    //Interrupt inputs
    .intreq_nmi_i   (1'b0),
    .intreq_err_i   (8'd0),
    .intreq_i       ({11'd0, qspi_int, bldc_int, gpio_int, cmt1_int, cmt0_int}),
    //---------------------------------
    //CPU interfaces
    .intr_req_o     (intr.req),
    .intr_level_o   (intr.level),
    .intr_vec_o     (intr.vec),
    .inta_ack_i     (inta.ack),
    //---------------------------------
    //APB interface
    .psel_i         (psel[APB_SLV_INTC]),
    .pwrite_i       (pwrite[APB_SLV_INTC]),
    .penable_i      (penable[APB_SLV_INTC]),
    .paddr_i        (paddr[APB_SLV_INTC]),
    .pwdata_i       (pwdata[APB_SLV_INTC]),
    .pstrb_i        (pstrb[APB_SLV_INTC]),
    .pprot_i        (pprot[APB_SLV_INTC]),
    .prdata_o       (prdata[APB_SLV_INTC]),
    .pslverr_o      (pslverr[APB_SLV_INTC]),
    .pready_o       (pready[APB_SLV_INTC]));

//-------------------------------------------------------------------------------
//AHB-to-APB bridge <-> GPIO
ahb2apb_bridge #(.APB_AW(PADDR_SIZE), .APB_DW(PDATA_SIZE)) ahb2apb_02 (
     // AHB Slave Interface
     .rst_n        (~rst),
     .clk          (clk),
     .hsel_i       (ahbcs[AHB_SLV_APB2].HSEL),
     .haddr_i      (ahbcs[AHB_SLV_APB2].HADDR),
     .hwdata_i     (ahbcs[AHB_SLV_APB2].HWDATA),
     .hrdata_o     (ahbrs[AHB_SLV_APB2].HRDATA),
     .hwrite_i     (ahbcs[AHB_SLV_APB2].HWRITE),
     .hsize_i      (ahbcs[AHB_SLV_APB2].HSIZE),
     .hburst_i     (ahbcs[AHB_SLV_APB2].HBURST),
     .hprot_i      (ahbcs[AHB_SLV_APB2].HPROT),
     .htrans_i     (ahbcs[AHB_SLV_APB2].HTRANS),
     .hmastlock_i  (ahbcs[AHB_SLV_APB2].HMASTLOCK),
     .hreadyout_o  (ahbrs[AHB_SLV_APB2].HREADY),
     .hready_i     (ahbcs[AHB_SLV_APB2].HREADY),
     .hresp_o      (ahbrs[AHB_SLV_APB2].HRESP),
     // APB Master Interface
     .psel_o       (psel[APB_SLV_GPIO]),
     .penable_o    (penable[APB_SLV_GPIO]),
     .pprot_o      (pprot[APB_SLV_GPIO]),
     .pwrite_o     (pwrite[APB_SLV_GPIO]),
     .pstrb_o      (pstrb[APB_SLV_GPIO]),
     .paddr_o      (paddr[APB_SLV_GPIO]),
     .pwdata_o     (pwdata[APB_SLV_GPIO]),
     .prdata_i     (prdata[APB_SLV_GPIO]),
     .pready_i     (pready[APB_SLV_GPIO]),
     .pslverr_i    (pslverr[APB_SLV_GPIO]));

gpio_core #(.AW(32), .DW(32)) gpio_core_00 (
    .clk        (clk),
    .rst        (rst),
    //--------------------------------------
    //APB slave inf
    .psel_i     (psel[APB_SLV_GPIO]),
    .pwrite_i   (pwrite[APB_SLV_GPIO]),
    .penable_i  (penable[APB_SLV_GPIO]),
    .paddr_i    (paddr[APB_SLV_GPIO]),
    .pwdata_i   (pwdata[APB_SLV_GPIO]),
    .pstrb_i    (pstrb[APB_SLV_GPIO]),
    .pprot_i    (pprot[APB_SLV_GPIO]),
    .prdata_o   (prdata[APB_SLV_GPIO]),
    .pslverr_o  (pslverr[APB_SLV_GPIO]),
    .pready_o   (pready[APB_SLV_GPIO]),
    //--------------------------------------
    //GPIO
    .gpio_o    (gpio_o),
    .gpio_i    (gpio_i),
    .gpio_en_o (gpio_en_o),
    //--------------------------------------
    //Interrupt
    .gpio_int_o(gpio_int));

//------------------------------------------------------------------------------
//AHB-to-Wishbone bridge <-> UART, BLDC(PWM)
// #Note : AHBLite-to_Wishbone bridge has no HREADYOUT signal.
ahb2aqu      ahb2aqu_00
    (
    .clk    (clk),
    .rst    (rst),
    .memc   (memc),//in
    .aquc   (aquc),//out
    .aqur   (aqur),//in
    .ahbc   (ahbcs[AHB_SLV_AQU]),//in from interconnect
    .ahbr   (ahbrs[AHB_SLV_AQU]) //out to interconnect
    );

assign aqur.ACK[2]  = 1'b1;
assign aqur.DATA[2] = 32'd0;

assign aqur.ACK[3]  = 1'b1;
assign aqur.DATA[3] = 32'd0;

//------------------------------------------------------------------------------
//Wishbone UART 
uart       uart
    (
    .CLK  (clk), 
    .RST  (rst),
    .CE   (aquc.CE[1]), 
    .WE   (aquc.WE),
    .SEL  (aquc.SEL),
    .DATI (aquc.DATA),
    .DATO (aqur.DATA[1]),
    .RXD  (uart_rxd_i), 
    .TXD  (uart_txd_o), 
    .CTS  (uart_cts_i), 
    .RTS  (uart_rts_o)
    );

assign aqur.ACK[1] = 1'b1;

//-------------------------------------------------------------------------------
//Wishbone PWM
`ifdef HAVE_BLDC
logic        adc_cmd_vld_o;
logic [4:0]  adc_cmd_ch_o;
logic        adc_cmd_sop_o;
logic        adc_cmd_eop_o;
logic        adc_cmd_ready_i = 'd0;
logic        adc_rsp_sop_i   = 'd0;
logic        adc_rsp_eop_i   = 'd0;
logic        adc_rsp_vld_i   = 'd0;
logic [4:0]  adc_rsp_ch_i    = 'd0;
logic [11:0] adc_rsp_data_i  = 'd0;

bldc_core     bldc_core_00
    (
    .clk        (clk),
    .rst_n      (~rst),
    //--------------------------------------
    //WB slave interface
    .sel_i      (aquc.SEL), 
    .dat_i      (aquc.DATA),   
    .addr_i     (aquc.ADR),   
    .cyc_i      (aquc.CE[0]),  
    .we_i       (aquc.WE),   
    .stb_i      (aquc.STB),    
    .ack_o      (aqur.ACK[0]),
    .dat_o      (aqur.DATA[0]),   
    //--------------------------------------
    //output to inverter
    .pwm_posa_o (pwm_posa_o),
    .pwm_nega_o (pwm_nega_o),
    .pwm_posb_o (pwm_posb_o),
    .pwm_negb_o (pwm_negb_o),
    .pwm_posc_o (pwm_posc_o),
    .pwm_negc_o (pwm_negc_o),
    //--------------------------------------
    //Altera ADC interface
    .cmd_vld_o  (adc_cmd_vld_o), //Command valid
    .cmd_ch_o   (adc_cmd_ch_o), // command channel
    .cmd_sop_o  (adc_cmd_sop_o),
    .cmd_eop_o  (adc_cmd_eop_o),
    .cmd_ready_i(adc_cmd_ready_i),//Command ready
    .rsp_sop_i  (adc_rsp_sop_i),
    .rsp_eop_i  (adc_rsp_eop_i),
    .rsp_vld_i  (adc_rsp_vld_i),//Response valid
    .rsp_ch_i   (adc_rsp_ch_i),//Response channel
    .rsp_data_i (adc_rsp_data_i),//Response data	
    //--------------------------------------
    //interrupt
    .bldc_int_o (bldc_int),
    //--------------------------------------
    //Hall sensor interface
    .over_cur_i (over_cur_i),//Over current
    .hall_i     (hall_i)
    );	
`else
  assign aqur.ACK[0]  = 1'b1;
  assign aqur.DATA[0] = 32'd0;
  assign bldc_int     = 1'b0;
`endif

//-------------------------------------------------------------------------------
//AHB <-> Wishbone <-> QSPI Flash Controller
logic [31:0]    qspi_wb_addr;
logic [31:0]    qspi_wb_wdat;
logic [31:0]    qspi_wb_rdat;
logic           qspi_wb_ack;
logic           qspi_wb_stall;
logic           qspi_wb_cyc;
logic           qspi_wb_we;
logic           qspi_wb_data_stb;
logic           qspi_wb_ctrl_stb;
logic [1:0]     qspi_mod;
logic [3:0]     qspi_dat_o_tmp;

ahb2wbqspi #(.AWIDTH(32), .DWIDTH(32)) ahb2wbqspi_00 (
    // WB interface
    .adr_o      (qspi_wb_addr),
    .dat_o      (qspi_wb_wdat),
    .stall_i    (qspi_wb_stall),
    .dat_i      (qspi_wb_rdat),
    .ack_i      (qspi_wb_ack),
    .cyc_o      (qspi_wb_cyc),
    .we_o       (qspi_wb_we),
    .stb_data_o (qspi_wb_data_stb),
    .stb_ctrl_o (qspi_wb_ctrl_stb),
    // AHB interface
    .hclk       (clk),
    .hresetn    (~rst),
    .haddr      (ahbcs[AHB_SLV_QSPI].HADDR),
    .htrans     (ahbcs[AHB_SLV_QSPI].HTRANS),
    .hwrite     (ahbcs[AHB_SLV_QSPI].HWRITE),
    .hsize      (ahbcs[AHB_SLV_QSPI].HSIZE),
    .hburst     (ahbcs[AHB_SLV_QSPI].HBURST),
    .hsel       (ahbcs[AHB_SLV_QSPI].HSEL),
    .hwdata     (ahbcs[AHB_SLV_QSPI].HWDATA),
    .hrdata     (ahbrs[AHB_SLV_QSPI].HRDATA),
    .hresp      (ahbrs[AHB_SLV_QSPI].HRESP),
    .hready     (ahbrs[AHB_SLV_QSPI].HREADY)
);

wbqspiflash #(.ADDRESS_WIDTH(24)) wbqspiflash_00 (
    .i_clk          (clk),
    .i_rst          (rst),
    // Internal wishbone connections
    .i_wb_cyc       (qspi_wb_cyc),
    .i_wb_data_stb  (qspi_wb_data_stb),
    .i_wb_ctrl_stb  (qspi_wb_ctrl_stb),
    .i_wb_we        (qspi_wb_we),
    .i_wb_addr      (qspi_wb_addr[23:2]),
    .i_wb_data      (qspi_wb_wdat),
    // Wishbone return values
    .o_wb_ack       (qspi_wb_ack),
    .o_wb_stall     (qspi_wb_stall),
    .o_wb_data      (qspi_wb_rdat),
    // Quad SPI connections to the external device (Flash)
    .o_qspi_sck     (qspi_sck_o),
    .o_qspi_cs_n    (qspi_cs_n_o),
    .o_qspi_mod     (qspi_mod),
    .o_qspi_dat     (qspi_dat_o_tmp),
    .i_qspi_dat     (qspi_dat_i),
    // Interrupt output
    .o_interrupt    (qspi_int)
);

// qspi_mod[1:0] = 0x : Single mode
//                 10 : Quad mode, output
//                 11 : Quad mode, input
assign qspi_dat_o[3:2] = qspi_mod[1] ? qspi_dat_o_tmp[3:2] : 2'b11;
assign qspi_dat_o[1:0] = qspi_dat_o_tmp[1:0];

assign qspi_dat_oe[3:2] = {2{~qspi_mod[1] | ~qspi_mod[0]}};
assign qspi_dat_oe[1]   =  qspi_mod[1] & ~qspi_mod[0];
assign qspi_dat_oe[0]   = ~qspi_mod[1] | ~qspi_mod[0];

//------------------------------------------------------------------------------
// AHB Memory(RAM)
`ifdef HAVE_AHBMEM
ahbmem #(.AW(`AHBMEM_AW)) ahbmem_00 (
  .clk(clk),
  .ahbc(ahbcs[AHB_SLV_MEM]),
  .ahbr(ahbrs[AHB_SLV_MEM])
);
`else
  assign ahbrs[AHB_SLV_MEM].HREADY = 1'b1;
  assign ahbrs[AHB_SLV_MEM].HRESP  = AHB_OKAY;
  assign ahbrs[AHB_SLV_MEM].HRDATA = 32'd0;
`endif

//------------------------------------------------------------------------------
// Boot ROM
bootrom bootrom_00 (
  .clk(clk),
  .ahbc(ahbcs[AHB_SLV_BROM]),
  .ahbr(ahbrs[AHB_SLV_BROM])
);

//-------------------------------------------------------------------------------
//AHB-to-APB bridge <-> APB memory
`ifdef HAVE_APBMEM
ahb2apb_bridge #(.APB_AW(PADDR_SIZE), .APB_DW(PDATA_SIZE)) ahb2apb_03 (
     // AHB Slave Interface
     .rst_n        (~rst),
     .clk          (clk),
     .hsel_i       (ahbcs[AHB_SLV_APB3].HSEL),
     .haddr_i      (ahbcs[AHB_SLV_APB3].HADDR),
     .hwdata_i     (ahbcs[AHB_SLV_APB3].HWDATA),
     .hrdata_o     (ahbrs[AHB_SLV_APB3].HRDATA),
     .hwrite_i     (ahbcs[AHB_SLV_APB3].HWRITE),
     .hsize_i      (ahbcs[AHB_SLV_APB3].HSIZE),
     .hburst_i     (ahbcs[AHB_SLV_APB3].HBURST),
     .hprot_i      (ahbcs[AHB_SLV_APB3].HPROT),
     .htrans_i     (ahbcs[AHB_SLV_APB3].HTRANS),
     .hmastlock_i  (ahbcs[AHB_SLV_APB3].HMASTLOCK),
     .hreadyout_o  (ahbrs[AHB_SLV_APB3].HREADY),
     .hready_i     (ahbcs[AHB_SLV_APB3].HREADY),
     .hresp_o      (ahbrs[AHB_SLV_APB3].HRESP),
     // APB Master Interface
     .psel_o       (psel[APB_SLV_MEM]),
     .penable_o    (penable[APB_SLV_MEM]),
     .pprot_o      (pprot[APB_SLV_MEM]),
     .pwrite_o     (pwrite[APB_SLV_MEM]),
     .pstrb_o      (pstrb[APB_SLV_MEM]),
     .paddr_o      (paddr[APB_SLV_MEM]),
     .pwdata_o     (pwdata[APB_SLV_MEM]),
     .prdata_i     (prdata[APB_SLV_MEM]),
     .pready_i     (pready[APB_SLV_MEM]),
     .pslverr_i    (pslverr[APB_SLV_MEM]));

// APB memory
apbmem #(.WAIT_CYCLES(3)) apbmem_00 (
    .clk            (clk),
    .psel_i         (psel[APB_SLV_MEM]),
    .pwrite_i       (pwrite[APB_SLV_MEM]),
    .penable_i      (penable[APB_SLV_MEM]),
    .paddr_i        (paddr[APB_SLV_MEM]),
    .pwdata_i       (pwdata[APB_SLV_MEM]),
    .pstrb_i        (pstrb[APB_SLV_MEM]),
    .pprot_i        (pprot[APB_SLV_MEM]),
    .prdata_o       (prdata[APB_SLV_MEM]),
    .pslverr_o      (pslverr[APB_SLV_MEM]),
    .pready_o       (pready[APB_SLV_MEM]));
`endif

endmodule 

