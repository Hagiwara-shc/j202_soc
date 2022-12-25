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

module ahbmem
(
   input       clk,
   input       AhbC ahbc,
   output      AhbR ahbr
);

  parameter AW = 15;          // ceil(log2(size_in_byte))
  parameter WAIT_CYCLES = 1;  // # of wait cycles (not in use)

  localparam NUM_RAM = (2**AW)/(2*1024);  // # of RAM macros (2KB)

  logic              sel, sel_r, sel_w;
  logic [17:2]       address, address_r, address_w;
  logic [3:0]        be, be_r, be_w;
  logic              wr, wr_r, wr_w;
  logic [31:0]       wd;
  logic [31:0]       rd;

  // RAM signals
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

  always_comb begin
     sel_r     = (ahbc.HTRANS == AHB_NONSEQ) & ahbc.HREADY & ahbc.HSEL;
     wr_r      = ahbc.HWRITE;
     address_r = ahbc.HADDR[17:2];
     wd        = ahbc.HWDATA;

     casez({ahbc.HSIZE[2:0], ahbc.HADDR[1:0]})
       5'b000_00 : be_r = 4'b1000;
       5'b000_01 : be_r = 4'b0100;
       5'b000_10 : be_r = 4'b0010;
       5'b000_11 : be_r = 4'b0001;
       5'b001_0? : be_r = 4'b1100;
       5'b001_1? : be_r = 4'b0011;
       5'b010_?? : be_r = 4'b1111;
       default   : be_r = 4'b1111;
     endcase
  end

  always_ff @(posedge clk) begin
     sel_w     <= sel_r;
     wr_w      <= wr_r;
     address_w <= address_r;
     be_w      <= be_r;
  end

`ifdef AHBMEM_EARLY_READ
   always_comb begin
      if (sel_r & ~wr_r) begin  // Read
        sel     = sel_r;
        wr      = wr_r;
        address = address_r;
        be      = be_r;
      end
      else begin                // Write / Nop
        sel     = sel_w;
        wr      = wr_w;
        address = address_w;
        be      = be_w;
      end
   end
`else
   always_comb begin
        sel     = sel_w;
        wr      = wr_w;
        address = address_w;
        be      = be_w;
   end
`endif

  // HRDATA
`ifdef AHBMEM_EARLY_READ
  always_ff @(posedge clk) begin
     ahbr.HRDATA <= ram_dout0_tmp[NUM_RAM];
  end
`else
  assign ahbr.HRDATA = ram_dout0_tmp[NUM_RAM];
`endif

  // HREADY (1-wait)
  assign ahbr.HREADY = ~sel_w;

  // HRESP
  assign ahbr.HRESP = AHB_OKAY;

  // RAM read data select
  always @(posedge clk) begin
    ram_dout0_sel <= ~ram_csb0;
  end 

  assign ram_dout0_tmp[0] = 32'd0;

  // RAM macros
  genvar i;
  for (i = 0; i < NUM_RAM; i = i + 1) begin : g_ram
    assign ram_clk[i]    = clk;
    if (NUM_RAM == 1) begin
      assign ram_csb0[i] = ~sel;
    end 
    else begin
      assign ram_csb0[i] = ~(sel & (address[AW-1:11] == i));
    end
    assign ram_web0[i]   = ~wr;
    assign ram_wmask0[i] = be;
    assign ram_addr0[i]  = address[10:2];
    assign ram_din0[i]   = wd;
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
