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

import cpu_pkg::*;

module ahbmem
  (
   input       clk,
   input       AhbC ahbc,
   output      AhbR ahbr
  );

   parameter AW = 18;  // log2(size_in_byte) (not used here)

   parameter WAIT_CYCLES = 0;  // # of wait cycles (0..5)

   reg [65535:0][31:0] ram;  // 256KB
   
   logic              sel;
   logic [17:2]       address;
   logic [3:0]        be;
   logic [31:0]       d;
   logic              wr;
   logic [17:2]       raddr;
   logic              data_phase;
   logic [5:1]        wait_cyc;

   always_ff @(posedge clk) begin
      sel     <= (ahbc.HTRANS == AHB_NONSEQ) & ahbc.HREADY & ahbc.HSEL;
      address <=  ahbc.HADDR[17:2];
      casez({ahbc.HSIZE[2:0], ahbc.HADDR[1:0]})
        5'b000_00 : be <= 4'b1000;
        5'b000_01 : be <= 4'b0100;
        5'b000_10 : be <= 4'b0010;
        5'b000_11 : be <= 4'b0001;
        5'b001_0? : be <= 4'b1100;
        5'b001_1? : be <= 4'b0011;
        5'b010_?? : be <= 4'b1111;
        default   : be <= 4'b1111;
      endcase
      wr      <= ahbc.HWRITE;
   end

   always_comb begin
      d        = ahbc.HWDATA;
   end

   // Write
   always @(posedge clk) //change to always
     if(sel & wr) begin
        if (be[3]) ram[address[17:2]][31:24] <= d[31:24];
        if (be[2]) ram[address[17:2]][23:16] <= d[23:16];
        if (be[1]) ram[address[17:2]][15: 8] <= d[15: 8];
        if (be[0]) ram[address[17:2]][ 7: 0] <= d[ 7: 0];
     end

   // Read
   always_ff @(posedge clk) begin
     if (ahbc.HREADY) begin
       raddr <= ahbc.HADDR[17:2];
       data_phase <= ahbc.HSEL & ~ahbc.HWRITE;
     end
   end

   always_comb
     if (data_phase & ahbr.HREADY)
       ahbr.HRDATA = ram[raddr[17:2]];
     else
       ahbr.HRDATA = 32'hxxxxxxxx;

   // Wait
   assign wait_cyc[1] = sel;
   always_ff @(posedge clk) begin
     wait_cyc[2] <= wait_cyc[1];
     wait_cyc[3] <= wait_cyc[2];
     wait_cyc[4] <= wait_cyc[3];
     wait_cyc[5] <= wait_cyc[4];
   end

   // HREADY
   always_comb begin
     case (WAIT_CYCLES)
       0: ahbr.HREADY = 1'b1;
       1: ahbr.HREADY = ~wait_cyc[1];
       2: ahbr.HREADY = ~(|wait_cyc[2:1]);
       3: ahbr.HREADY = ~(|wait_cyc[3:1]);
       4: ahbr.HREADY = ~(|wait_cyc[4:1]);
       5: ahbr.HREADY = ~(|wait_cyc[5:1]);
       default: ahbr.HREADY = ~(|wait_cyc[5:1]);
     endcase
   end

   // HRESP
   assign ahbr.HRESP = AHB_OKAY;

endmodule
