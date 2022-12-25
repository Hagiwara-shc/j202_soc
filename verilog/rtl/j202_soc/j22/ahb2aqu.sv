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

module ahb2aqu
  (
   input logic clk, rst,
   input       MemC [1:0] memc,
   input       AhbC ahbc,
   output      AquC aquc,
   input       AquR aqur,
   output      AhbR ahbr
   );

   Aqu_st aqu_st;
   AquC aquco;
   AquC aquc2;
   
   function AquC clrAquC;
      begin
         clrAquC.CE  = 'b0;
         clrAquC.STB = 1'b0;
         clrAquC.ADR[31:0] = {32{1'bx}};
         clrAquC.WE = 1'bx;
         clrAquC.DATA[31:0] = {32{1'bx}};
         clrAquC.SEL[3:0] = {4{1'bx}};
      end
   endfunction

   function AquC setAquC;
      input     AhbC ahbc;
      begin
         setAquC.CE[0] = (ahbc.HADDR[15:8]==8'h00)&ahbc.HSEL;
         setAquC.CE[1] = (ahbc.HADDR[15:8]==8'h01)&ahbc.HSEL;
         setAquC.CE[2] = (ahbc.HADDR[15:8]==8'h02)&ahbc.HSEL;
         setAquC.CE[3] = (ahbc.HADDR[15:8]==8'h03)&ahbc.HSEL;
         setAquC.ADR[31:0] = ahbc.HADDR[31:0];
         setAquC.WE = ahbc.HWRITE;

         setAquC.SEL[3]  = ((ahbc.HSIZE[2:0] == 3'b010)|
                            (ahbc.HSIZE[2:0] == 3'b001)&(ahbc.HADDR[1]==1'b0)|
                            (ahbc.HSIZE[2:0] == 3'b000)&(ahbc.HADDR[1:0]==2'b00));
         setAquC.SEL[2]  = ((ahbc.HSIZE[2:0] == 3'b010)|
                            (ahbc.HSIZE[2:0] == 3'b001)&(ahbc.HADDR[1]==1'b0)|
                            (ahbc.HSIZE[2:0] == 3'b000)&(ahbc.HADDR[1:0]==2'b01));
         setAquC.SEL[1]  = ((ahbc.HSIZE[2:0] == 3'b010)|
                            (ahbc.HSIZE[2:0] == 3'b001)&(ahbc.HADDR[1]==1'b1)|
                            (ahbc.HSIZE[2:0] == 3'b000)&(ahbc.HADDR[1:0]==2'b10));
         setAquC.SEL[0]  = ((ahbc.HSIZE[2:0] == 3'b010)|
                            (ahbc.HSIZE[2:0] == 3'b001)&(ahbc.HADDR[1]==1'b1)|
                            (ahbc.HSIZE[2:0] == 3'b000)&(ahbc.HADDR[1:0]==2'b11));
         setAquC.STB = 1'b1;
      end
   endfunction
   
   always_comb begin
      aquc = aquco;
      aquc.DATA[31:0] = ahbc.HWDATA[31:0];
   end
   always_ff @(posedge clk) begin
      if(rst) begin
         aqu_st <= aqu_IDLE;
         aquco  <= clrAquC();
      end else
        casez(aqu_st)
          aqu_IDLE : begin
             if((ahbc.HTRANS == AHB_NONSEQ) & ahbc.HREADY) begin
                aqu_st <= aqu_BUSY;
                aquco  <= setAquC(ahbc);
             end
          end
          aqu_BUSY : begin
             if((ahbc.HTRANS == AHB_NONSEQ) & ahbc.HREADY & ahbr.HREADY) begin
                aqu_st <= aqu_BUSY;
                aquco  <= setAquC(ahbc);
             end else if (ahbr.HREADY)begin
                aqu_st <= aqu_IDLE;
                aquco  <= clrAquC();
             end else if ((ahbc.HTRANS == AHB_NONSEQ) & ahbc.HREADY)begin
                aqu_st <= aqu_BUSY2;
                aquc2  <= setAquC(ahbc);
             end
          end
          aqu_BUSY2 : begin
             if (ahbr.HREADY)begin
                aqu_st <= aqu_BUSY;
                aquco  <= aquc2;
             end
          end
        endcase
      if (ahbc.HTRANS != AHB_NONSEQ) begin
         aquco.STB <= memc[0].sel|memc[1].sel;
         if (memc[0].sel) begin
            aquco.ADR <= memc[0].a;
            aquco.SEL <= memc[0].be;
         end else begin
            aquco.ADR <= memc[1].a;
            aquco.SEL <= memc[1].be;
         end
      end
   end

   always_comb begin
      case(aquc.CE)
        4'b0001 : ahbr.HRDATA = aqur.DATA[0];
        4'b0010 : ahbr.HRDATA = aqur.DATA[1];
        4'b0100 : ahbr.HRDATA = aqur.DATA[2];
        4'b1000 : ahbr.HRDATA = aqur.DATA[3];
        default : ahbr.HRDATA = {32{1'bx}};
      endcase
      ahbr.HREADY = 1'b1;
      ahbr.HRESP = AHB_OKAY;
   end
endmodule
