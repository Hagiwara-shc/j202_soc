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

`ifndef VERBOSE 
  `define VERBOSE 0
`endif

`ifdef USE_POWER_PINS
  `define USE_POWER_PINS_WAS_DEFINED
`endif

`ifdef SIM
  `undef USE_POWER_PINS
`endif

//////////////////////////////////////////////
// SkyWater 130nm
//////////////////////////////////////////////

import cpu_pkg::*;

module memory   // TCM
(
   input logic clk,
   input       MemC memc,
   output      MemR memr
);

  parameter AW = 15;  // ceil(log2(size_in_byte))

  localparam NUM_RAM = (2**AW)/(2*1024);  // # of RAM macros (2KB)

  wire [NUM_RAM-1:0]  ram_clk;
  wire [NUM_RAM-1:0]  ram_csb0;
  wire [NUM_RAM-1:0]  ram_web0;
  wire [3:0]          ram_wmask0[NUM_RAM-1:0];
  wire [8:0]          ram_addr0[NUM_RAM-1:0];
  wire [31:0]         ram_din0[NUM_RAM-1:0];
  wire [31:0]         ram_dout0[NUM_RAM-1:0];
  wire [31:0]         ram_dout0_tmp[NUM_RAM:0];
  wire [NUM_RAM-1:0]  ram_csb1;
  wire [8:0]          ram_addr1[NUM_RAM-1:0];
  reg  [NUM_RAM-1:0]  ram_dout0_sel;

  // RAM read data select
  always @(posedge clk) begin
    ram_dout0_sel <= ~ram_csb0;
  end

  assign ram_dout0_tmp[0] = 32'd0;
  assign memr.q = ram_dout0_tmp[NUM_RAM];

  genvar i;
  for (i = 0; i < NUM_RAM; i = i + 1) begin : g_ram
    assign ram_clk[i]    = clk;
    if (NUM_RAM == 1) begin
      assign ram_csb0[i] = ~memc.sel;
    end
    else begin
      assign ram_csb0[i] = ~(memc.sel & (memc.a[AW-1:11] == i));
    end
    assign ram_web0[i]   = ~memc.wr;
    assign ram_wmask0[i] = memc.be;
    assign ram_addr0[i]  = memc.a[10:2];
    assign ram_din0[i]   = memc.d;
    assign ram_csb1[i]   = 1'b1;
    assign ram_addr1[i]  = 9'h1ff;

    assign ram_dout0_tmp[i+1] = ram_dout0_sel[i] ? ram_dout0[i] : ram_dout0_tmp[i];

    sky130_sram_2kbyte_1rw1r_32x512_8 #(.VERBOSE(`VERBOSE)) ram (
     `ifdef USE_POWER_PINS
      .vccd1  (vccd1),
      .vssd1  (vssd1),
     `endif
      .clk0   (ram_clk[i]),         // clock 0
      .csb0   (ram_csb0[i]),        // active low chip select 0
      .web0   (ram_web0[i]),        // active low write control 0
      .wmask0 (ram_wmask0[i]),      // write mask 0
      .addr0  (ram_addr0[i]),       // address 0
      .din0   (ram_din0[i]),        // write data 0
      .dout0  (ram_dout0[i]),       // read data 0
      .clk1   (ram_clk[i]),         // clock 1
      .csb1   (ram_csb1[i]),        // active low chip select 1
      .addr1  (ram_addr1[i]),       // address 1
      /* verilator lint_off PINCONNECTEMPTY */
      .dout1  ()                    // read data 1
      /* verilator lint_on PINCONNECTEMPTY */
    );
  end // g_ram
endmodule

`ifdef USE_POWER_PINS_WAS_DEFINED
  `define USE_POWER_PINS
`endif
