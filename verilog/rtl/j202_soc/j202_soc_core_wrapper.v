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

module j202_soc_core_wrapper
(
`ifdef USE_POWER_PINS
    inout vccd1,  // User area 1 1.8V supply
    inout vssd1,  // User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

`ifndef J202_SOC_CORE_EMPTY
//------------------------------------------------------------------------------
// Clock and Reset to j202_soc_core
wire clk;
wire rst_n;
reg  [31:0] reg_val;  // Wishbone register value

assign clk   = wb_clk_i;
assign rst_n = reg_val[0];

//------------------------------------------------------------------------------
// Wishbone slave port & register
wire        valid;
wire [3:0]  wstrb;
reg         ready;

assign valid = wbs_cyc_i & wbs_stb_i; 
assign wstrb = wbs_sel_i & {4{wbs_we_i}};
assign wbs_ack_o = ready;
assign wbs_dat_o = reg_val;

always @(posedge clk) begin
  if (wb_rst_i) begin
    reg_val <= 32'h00000000;
    ready <= 1'b0;
  end 
  else begin
    if (valid && !ready) begin
      ready <= 1'b1;
      if (wstrb[0]) reg_val[7:0]   <= wbs_dat_i[7:0];
      if (wstrb[1]) reg_val[15:8]  <= wbs_dat_i[15:8];
      if (wstrb[2]) reg_val[23:16] <= wbs_dat_i[23:16];
      if (wstrb[3]) reg_val[31:24] <= wbs_dat_i[31:24];
    end 
    else begin
      ready <= 1'b0;
    end 
  end 
end 

//------------------------------------------------------------------------------
// Logic Analyzer Signals
// la_data_out[127:32] <- 0
//            [ 31: 0] <- gpio_o[31:0]
assign la_data_out[127:32] = 96'd0;

wire [127:0] la_data_input; // [127:23] -> not in use
                            // [ 31:22] -> gpio_i[31:22]
assign la_data_input = ~la_oenb & la_data_in;

//------------------------------------------------------------------------------
// IRQ
assign user_irq = 3'b000;

//------------------------------------------------------------------------------
// IO assignment
wire [1:0]  md_boot;    // input
wire [31:0] gpio_i;     // input
wire [31:0] gpio_o;     // output
wire [31:0] gpio_en_o;  // output
wire        pwm_posa_o; // output
wire        pwm_nega_o; // output
wire        pwm_posb_o; // output
wire        pwm_negb_o; // output
wire        pwm_posc_o; // output
wire        pwm_negc_o; // output
wire        over_cur_i; // input
wire [2:0]  hall_i;     // input
wire        uart_rxd_i; // input
wire        uart_cts_i; // input
wire        uart_txd_o; // output
wire        uart_rts_o; // output
wire        qspi_sck_o; // output
wire        qspi_cs_n_o;// output
wire [3:0]  qspi_dat_o; // output
wire [3:0]  qspi_dat_oe;// output
wire [3:0]  qspi_dat_i; // input

// Input
assign md_boot           = io_in[15:14];
assign gpio_i            = {la_data_input[31:18], io_in[37:26], io_in[7], io_in[4:0]};
assign over_cur_i        = io_in[25];
assign hall_i            = io_in[24:22];
assign uart_rxd_i        = io_in[5];
assign uart_cts_i        = 1'b0;
assign qspi_dat_i        = io_in[13:10];

// Output
assign la_data_out[31:0] = gpio_o[31:0];

assign io_out[37:26]     = gpio_o[17:6];
assign io_out[25:22]     = 4'b0000;
assign io_out[21]        = pwm_negc_o;
assign io_out[20]        = pwm_posc_o;
assign io_out[19]        = pwm_negb_o;
assign io_out[18]        = pwm_posb_o;
assign io_out[17]        = pwm_nega_o;
assign io_out[16]        = pwm_posa_o;
assign io_out[15:14]     = 2'b00;
assign io_out[13:10]     = qspi_dat_o;
assign io_out[9]         = qspi_sck_o;
assign io_out[8]         = qspi_cs_n_o;
assign io_out[7]         = gpio_o[5];
assign io_out[6]         = uart_txd_o;
assign io_out[5]         = 1'b0;
assign io_out[4:0]       = gpio_o[4:0];

// Output enable (low-active)
assign io_oeb[37:26]     = ~gpio_en_o[17:6];// GPIO[17:6]
assign io_oeb[25:22]     = 4'b1111;         // OVER_CURR, HALL[2:0]
assign io_oeb[21:16]     = 6'b000000;       // PWM_{a,b,c}_{pos,neg}
assign io_oeb[15:14]     = 2'b11;           // MD_boot[1:0]
assign io_oeb[13:10]     = ~qspi_dat_oe;    // QSPI_flash_io[3:0]
assign io_oeb[9:8]       = 2'b00;           // QSPI_{sck,csb}
assign io_oeb[7]         = ~gpio_en_o[5];   // GPIO[5]
assign io_oeb[6]         = 1'b0;            // UART_tx
assign io_oeb[5]         = 1'b1;            // UART_rx
assign io_oeb[4:0]       = ~gpio_en_o[4:0]; // GPIO[4:0]

//------------------------------------------------------------------------------
// j202_soc_core
j202_soc_core j202_soc_core (
    .clk             (clk),
    .rst_n           (rst_n),
    .md_boot         (md_boot),
    //---------------------------------
    //GPIO
    .gpio_i          (gpio_i),
    .gpio_o          (gpio_o),
    .gpio_en_o       (gpio_en_o),
    //---------------------------------
    //BLDC PWM
    .pwm_posa_o      (pwm_posa_o), 
    .pwm_nega_o      (pwm_nega_o), 
    .pwm_posb_o      (pwm_posb_o), 
    .pwm_negb_o      (pwm_negb_o), 
    .pwm_posc_o      (pwm_posc_o), 
    .pwm_negc_o      (pwm_negc_o), 
    .over_cur_i      (over_cur_i),
    .hall_i          (hall_i),    
    //---------------------------------
    //UART
    .uart_rxd_i      (uart_rxd_i),
    .uart_cts_i      (uart_cts_i),
    .uart_txd_o      (uart_txd_o),
    .uart_rts_o      (uart_rts_o),
    //---------------------------------
    //QSPI
    .qspi_sck_o      (qspi_sck_o),
    .qspi_cs_n_o     (qspi_cs_n_o),
    .qspi_dat_o      (qspi_dat_o),
    .qspi_dat_oe     (qspi_dat_oe),
    .qspi_dat_i      (qspi_dat_i)
);
`endif  // J202_SOC_CORE_EMPTY
endmodule
