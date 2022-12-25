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

module cpu_local_reg #(
   parameter CPUID = 0  // CPU ID
  )
  
  (
   input logic clk, HSEL,
   input       AhbC ahbc,
   output      AhbR ahbr
  );

   localparam ADDR_CPUID = 12'h000; // CPU ID reg.
   localparam ADDR_REG1  = 12'h004; // sample reg.

   logic [31:0]       REG1;         // sample reg.

   logic              sel;
   logic [11:0]       address;
   logic [3:0]        be;
   logic [31:0]       d;
   logic              wr;
   logic [31:0]       rdata;

   assign ahbr.HREADY = 1'b1;

   always_ff @(posedge clk) begin
      sel     <= (ahbc.HTRANS == AHB_NONSEQ) & HSEL;
      address <=  ahbc.HADDR[11:0];
      casez({ahbc.HSIZE[2:0], ahbc.HADDR[1:0]})
        5'b000_00 : be <= 4'b1000;
        5'b000_01 : be <= 4'b0100;
        5'b000_10 : be <= 4'b0010;
        5'b000_11 : be <= 4'b0001;
        5'b001_0? : be <= 4'b1100;
        5'b001_1? : be <= 4'b0011;
        5'b010_?? : be <= 4'b1111;
        default   : be <= 4'b0000;
      endcase
      wr      <= ahbc.HWRITE;
   end
   always_comb begin
      d        = ahbc.HWDATA;
   end

   // Write
   always_ff @(posedge clk)
     if(sel & wr) begin
       casez (address)
         ADDR_REG1: 
           if (be == 4'b1111) REG1 <= d;
       endcase
     end

   // Read
   always_comb
     if (sel & ~wr) begin
       casez (address)
         ADDR_CPUID: rdata = CPUID;
         ADDR_REG1 : rdata = REG1;
         default   : rdata = 32'h00000000;
       endcase
     end

   assign ahbr.HRDATA = rdata;

endmodule
