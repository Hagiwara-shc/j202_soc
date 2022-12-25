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

module memory
  (
   input logic clk,
   input       MemC memc,
   output      MemR memr
  );

   parameter AW = 18;  // log2(size_in_byte) (not used here)

   reg [65535:0][31:0] ram; // 256KB
   
   logic              sel;
   logic [17:2]       address;
   logic [3:0]        be;
   logic [31:0]       d;
   logic              wr;

   always_ff @(posedge clk) begin
      if(~memc.bsy)begin
         sel     <= memc.sel;
         address <= memc.a[17:2];
         be      <= memc.be;
         d       <= memc.d;
         wr      <= memc.wr;
      end
   end

   always @(posedge clk)//change to always
     if(sel & wr) begin
        if (be[3]) ram[address[17:2]][31:24] <= d[31:24];
        if (be[2]) ram[address[17:2]][23:16] <= d[23:16];
        if (be[1]) ram[address[17:2]][15: 8] <= d[15: 8];
        if (be[0]) ram[address[17:2]][ 7: 0] <= d[ 7: 0];
     end

   always_comb
     if (sel & ~wr)
       memr.q = ram[address[17:2]];

endmodule // memory
