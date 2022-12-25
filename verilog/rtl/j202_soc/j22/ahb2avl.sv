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

module ahb2avl
  (
   input logic clk, rst,
   input       AhbC ahbc,
   output      AvlC avlc,
   input       AvlR avlr,
   output      AhbR ahbr,
   input       HREADY
   );

   Avl_st avl_st;
   AvlC avlc2;
   
   function AvlC setAvlC;
      input     AhbC ahbc;
      begin
         setAvlC.chipselect = 1'b1;
         setAvlC.address[17:2] = ahbc.HADDR[17:2];
         setAvlC.read_n = ahbc.HWRITE;
         setAvlC.write_n = ~ahbc.HWRITE;
         setAvlC.writedata = ahbc.HWDATA;
      end
   endfunction
   
   always_ff @(posedge clk)
     if(rst) begin
        avl_st <= avl_IDLE;
        avlc.chipselect <= 1'b0;
     end else
       casez(avl_st)
         avl_IDLE : begin
            if((ahbc.HTRANS == AHB_NONSEQ) & HREADY) begin
               avl_st <= avl_BUSY;
               avlc <= setAvlC(ahbc);
            end
         end
         avl_BUSY : begin
            if((ahbc.HTRANS == AHB_NONSEQ) & HREADY & ahbr.HREADY) begin
               avl_st <= avl_BUSY;
               avlc <= setAvlC(ahbc);
            end else if (ahbr.HREADY)begin
               avl_st <= avl_IDLE;
               avlc.chipselect <= 1'b0;
            end else if ((ahbc.HTRANS == AHB_NONSEQ) & HREADY)begin
               avl_st <= avl_BUSY2;
               avlc2 <= setAvlC(ahbc);
            end
         end
         avl_BUSY2 : begin
            if (ahbr.HREADY)begin
               avl_st <= avl_BUSY;
               avlc <= avlc2;
            end
         end
       endcase   

   always_comb begin
      ahbr.HRDATA =  avlr.readdata;
      ahbr.HREADY = ~avlr.waitrequest | ~avlc.chipselect;
   end
endmodule
