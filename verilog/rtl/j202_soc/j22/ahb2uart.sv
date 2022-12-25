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

module ahb2uart
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
   
   logic [31:0] rxdata;
   logic        ready;

   function AvlC setAvlC;
      input     AhbC ahbc;
      begin
         if((ahbc.HADDR[3]==1'b0) & (ahbc.HWRITE | (ahbc.HADDR[2]==1'b1) | ~ready))
           setAvlC.chipselect = 1'b1;
         else
           setAvlC.chipselect = 1'b0;
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
 
   always_ff @(posedge clk) begin
      if(avlc.chipselect & ~avlc.read_n & ahbr.HREADY & (avlc.address[2]==1'b0)) begin
         rxdata <= avlr.readdata;
         ready  <= avlr.readdata[15];
      end
      if((ahbc.HTRANS == AHB_NONSEQ) & ahbr.HREADY & ~ahbc.HWRITE & (ahbc.HADDR[3:2] == 2'b10))
        ready  <= 1'b0;
      if(rst)
        ready  <= 1'b0;
   end


   always_comb begin
      if(avlc.chipselect)
        ahbr.HRDATA =  avlr.readdata;
      else
        ahbr.HRDATA =  rxdata;
      ahbr.HREADY = ~avlr.waitrequest | ~avlc.chipselect;
   end
endmodule
