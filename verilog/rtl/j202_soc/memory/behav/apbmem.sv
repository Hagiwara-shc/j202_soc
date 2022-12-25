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

module apbmem
  (
   input                clk,
   input                psel_i,
   input                pwrite_i,
   input                penable_i,
   input        [31:0]  paddr_i,
   input        [31:0]  pwdata_i,
   input        [2:0]   pprot_i,
   input        [3:0]   pstrb_i,
   output logic [31:0]  prdata_o,
   output logic         pslverr_o,
   output logic         pready_o
  );

   parameter WAIT_CYCLES = 0;  // # of wait cycles (0..5)

   reg [16383:0][31:0] ram;  // 64KB
   
   logic              sel;
   logic [15:2]       address;
   logic [3:0]        be;
   logic [31:0]       d;
   logic              wr;
   logic              data_phase;
   logic [5:1]        wait_cyc;

   always_ff @(posedge clk) begin
      sel     <= psel_i & ~penable_i;
   end

   always_comb begin
      address  = paddr_i[15:2];
      be       = pstrb_i;
      wr       = pwrite_i;
      d        = pwdata_i;
   end

   // Write
   always @(posedge clk) //change to always
     if(sel & wr) begin
        if (be[3]) ram[address[15:2]][31:24] <= d[31:24];
        if (be[2]) ram[address[15:2]][23:16] <= d[23:16];
        if (be[1]) ram[address[15:2]][15: 8] <= d[15: 8];
        if (be[0]) ram[address[15:2]][ 7: 0] <= d[ 7: 0];
     end

   // Read
   always_comb begin
     data_phase = psel_i & ~pwrite_i & penable_i;
   end

   always_comb
     if (data_phase & pready_o)
       prdata_o = ram[address[15:2]];
     else
       prdata_o = 32'hxxxxxxxx;

   // pslverr
   assign pslverr_o = 1'b0;

   // Wait
   assign wait_cyc[1] = sel;
   always_ff @(posedge clk) begin
     wait_cyc[2] <= wait_cyc[1];
     wait_cyc[3] <= wait_cyc[2];
     wait_cyc[4] <= wait_cyc[3];
     wait_cyc[5] <= wait_cyc[4];
   end

   always_comb begin
     case (WAIT_CYCLES)
       0: pready_o = 1'b1;
       1: pready_o = ~wait_cyc[1];
       2: pready_o = ~(|wait_cyc[2:1]);
       3: pready_o = ~(|wait_cyc[3:1]);
       4: pready_o = ~(|wait_cyc[4:1]);
       5: pready_o = ~(|wait_cyc[5:1]);
       default: pready_o = ~(|wait_cyc[5:1]);
     endcase
   end

endmodule
