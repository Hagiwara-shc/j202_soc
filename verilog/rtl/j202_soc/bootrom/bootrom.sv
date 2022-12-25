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

//////////////////////////////////////////////
// Boot ROM (on AHB-Lite)
//////////////////////////////////////////////

module bootrom
  (
   input       clk,
   input       AhbC ahbc,
   output      AhbR ahbr
  );

   parameter WAIT_CYCLES = 1;  // # of wait cycles (not in use)

   logic              sel, sel_r, sel_w;
   logic [17:2]       address, address_r, address_w;
   logic [3:0]        be, be_r, be_w;
   logic [31:0]       rd;

   always_comb begin
      sel_r     = (ahbc.HTRANS == AHB_NONSEQ) & ahbc.HREADY & ahbc.HSEL & ~ahbc.HWRITE;
      address_r = ahbc.HADDR[17:2];

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
     sel_w <= sel_r;

     if (sel_r) begin
      address_w <= address_r;
      be_w      <= be_r;
     end
   end

`ifdef BOOTROM_EARLY_READ
   always_comb begin
        sel     = sel_r;
        address = address_r;
        be      = be_r;
   end
`else
   always_comb begin
        sel     = sel_w;
        address = address_w;
        be      = be_w;
   end
`endif

   // Read
   always_comb begin
     case (address)
       `include "bootload/kzload.v"
       default: rd = 32'd0;
     endcase
   end

   // HRDATA
`ifdef BOOTROM_EARLY_READ
   always_ff @(posedge clk)
      ahbr.HRDATA <= rd;
`else
   assign ahbr.HRDATA = rd;
`endif

   // HREADY (1-wait)
   assign ahbr.HREADY = ~sel_w;

   // HRESP
   assign ahbr.HRESP = AHB_OKAY;

endmodule
