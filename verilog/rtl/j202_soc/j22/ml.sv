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

module ml
   (
    input logic clk, rst, stall,
    input       MacOp macop,
    input       RfuO rfuo,
    input       MauO mauo,
    input       AhbR ahbr,
    output      MluO mluo
   );

   MacOp M_macop, X_macop;
   logic signed [31:0] mach, macl, machi, macli, machj, maclj;

   wire                E_long =  ((macop.MAC == MAC_MAC0L) | (macop.MAC == MAC_MAC1L) |
                                  (macop.MAC == MAC_MAC0W) | (macop.MAC == MAC_MAC1W) |
                                  (macop.MAC == MAC_MACHM) | (macop.MAC == MAC_MACLM)  );
   wire                M_long =  ((M_macop.MAC == MAC_MAC0L) | (M_macop.MAC == MAC_MAC1L) | (M_macop.MAC == MAC_MACSL) |
                                  (X_macop.MAC == MAC_MAC1L) | (X_macop.MAC == MAC_MACSL) |
                                  (M_macop.MAC == MAC_MAC0W) | (M_macop.MAC == MAC_MAC1W) | (M_macop.MAC == MAC_MACSW) |
                                  (M_macop.MAC == MAC_MACHM) | (M_macop.MAC == MAC_MACLM)  );
   wire                M_multi = ((M_macop.MAC == MAC_MAC1L) | (M_macop.MAC == MAC_MACSL) | (X_macop.MAC == MAC_MULL) |
                                  (X_macop.MAC == MAC_DMULSL) | (X_macop.MAC == MAC_DMULUL));

   wire                regcnf = (((macop.MAC == MAC_STMACH) | (macop.MAC == MAC_STMACL)) &
                                 ( (X_macop.MAC == MAC_MAC1W) | (X_macop.MAC == MAC_MACSW) |
                                   (X_macop.MAC == MAC_MAC2L) | (X_macop.MAC == MAC_MACS2)  ) );
   
   assign mluo.bsy = ( M_long & ~(E_long | (macop.MAC == MAC_NOP)) ) |
                     ( M_multi & (macop != MAC_NOP)) |
                     regcnf;

   always_ff @(posedge clk) begin
      casez(X_macop.MAC)
        MAC_MULL   : X_macop.MAC <= MAC_MULL2;
        MAC_DMULSL : X_macop.MAC <= MAC_DMULSL2;
        MAC_DMULUL : X_macop.MAC <= MAC_DMULUL2;
        MAC_MAC1L  : X_macop.MAC <= MAC_MAC2L;
        MAC_MACSL  : X_macop.MAC <= MAC_MACS2;
        default  : begin
           if(M_long)
             if(mauo.rdy)
               X_macop <= M_macop;
             else
               X_macop <= MAC_NOP;
           else if(stall | (E_long))
             X_macop <= MAC_NOP;
           else X_macop <= macop;
        end
      endcase

      if(~ahbr.HREADY) begin
      end else if(mauo.bsy) begin
      end else if(E_long) begin
         if(~mluo.bsy)
           M_macop <= macop;
         else
           M_macop <= MAC_NOP;
         if(rfuo.sr.s)
           casez(macop.MAC)
             MAC_MAC1W : M_macop.MAC <= MAC_MACSW;
             MAC_MAC1L : M_macop.MAC <= MAC_MACSL;
           endcase
      end else begin
         M_macop <= MAC_NOP;
      end
   end    

   logic signed [32:0] bufa, bufb;
   always_ff @(posedge clk) begin
      casez(macop.MAC)
        MAC_MACHE  : bufa <= {1'b0,rfuo.ra};
        MAC_MACLE  : bufa <= {1'b0,rfuo.ra};
        MAC_MULUW  : begin
           bufa <= {{17{1'b0}}, rfuo.ra[15:0]};
           bufb <= {1'b0,       rfuo.rb[31:0]}; end
        MAC_MULSW  : begin
           bufa <= {{17{rfuo.ra[15]}}, rfuo.ra[15:0]};
           bufb <= {rfuo.rb[15],       rfuo.rb[31:0]}; end
        MAC_MULL   : begin
           bufa <= {1'b0,rfuo.ra};
           bufb <= {1'b0,rfuo.rb}; end
        MAC_DMULSL : begin
           bufa <= {rfuo.ra[31],rfuo.ra};
           bufb <= {1'b0,rfuo.rb}; end
        MAC_DMULUL : begin
           bufa <= {1'b0,rfuo.ra};
           bufb <= {1'b0,rfuo.rb}; end
      endcase
      casez(M_macop.MAC)
        MAC_MACHM : bufa <= {1'b0,mauo.rslt};
        MAC_MACLM : bufa <= {1'b0,mauo.rslt};
        MAC_MAC0W : bufa <= {{17{mauo.rslt[15]}},mauo.rslt[15:0]};
        MAC_MAC1W : bufb <= {{17{mauo.rslt[15]}},mauo.rslt[15:0]};
        MAC_MACSW : bufb <= {{17{mauo.rslt[15]}},mauo.rslt[15:0]};
        MAC_MAC0L : bufa <= {mauo.rslt[31],mauo.rslt};
        MAC_MAC1L : bufb <= {1'b0,mauo.rslt};
        MAC_MACSL : bufb <= {1'b0,mauo.rslt};
      endcase
      casez(X_macop.MAC)
        MAC_MULL   : bufb <= {1'b0,    bufb[31:16],bufb[31:16]};
        MAC_DMULSL : bufb <= {bufb[31],bufb[31:16],bufb[31:16]};
        MAC_DMULUL : bufb <= {1'b0,    bufb[31:16],bufb[31:16]};
        MAC_MAC1L  : bufb <= {bufb[31],bufb[31:16],bufb[31:16]};
        MAC_MACSL  : bufb <= {bufb[31],bufb[31:16],bufb[31:16]};
      endcase
   end

   logic [63:0]       acc;
   always_comb begin
     casez(X_macop.MAC)
       MAC_MULUW  : acc = ( {64{1'b0}});
       MAC_MULSW  : acc = ( {64{1'b0}});
       MAC_MULL   : acc = ( {64{1'b0}});
       MAC_MULL2  : acc = ({{48{1'b0}},macl[31:16]});
       MAC_DMULSL : acc = ( {64{1'b0}});
       MAC_DMULSL2: acc = ({{16{1'b0}},mach[31:0],macl[31:16]});
       MAC_DMULUL : acc = ( {64{1'b0}});
       MAC_DMULUL2: acc = ({{16{1'b0}},mach[31:0],macl[31:16]});
       MAC_MAC1W  : acc = ({mach[31:0],macl[31: 0]});
       MAC_MACSW  : acc = ({{32{macl[31]}},macl[31:0]});

       MAC_MAC1L  : acc = ({mach[31:0],macl[31:0]});
       MAC_MACSL  : acc = ({mach[31:0],macl[31:0]});
       MAC_MAC2L  : acc = ({{15{1'b0}},mach[31],mach[31:0],macl[31:16]});
       MAC_MACS2  : acc = ({{15{1'b0}},mach[31],mach[31:0],macl[31:16]});
       default    : acc = ( {64{1'b0}});
     endcase
   end

   wire signed [63:0] sum = signed'(bufa[32:0]) * signed'({bufb[32],bufb[15:0]}) + signed'(acc);
   wire               v   = ~((&sum[48:31]) | ~(|sum[48:31]));
   
   always_comb
     casez(X_macop.MAC)
       MAC_CLRMAC : {machi,macli} = {{32{1'b0}} ,{32{1'b0}}};
       MAC_MACHE  : {machi,macli} = {bufa[31:0] ,macl[31:0]};
       MAC_MACLE  : {machi,macli} = {mach[31:0] ,bufa[31:0]};
       MAC_MACHM  : {machi,macli} = {bufa[31:0] ,macl[31:0]};
       MAC_MACLM  : {machi,macli} = {mach[31:0] ,bufa[31:0]};
       MAC_MULUW  : {machi,macli} = {mach[31:0] ,sum[31:0] };
       MAC_MULSW  : {machi,macli} = {mach[31:0] ,sum[31:0] };
       MAC_MULL   : {machi,macli} = {mach[31:0] ,sum[31:0] };
       MAC_MULL2  : {machi,macli} = {mach[31:0] ,sum[15:0],macl[15:0]};
       MAC_DMULSL : {machi,macli} = {            sum[63:0] };
       MAC_DMULSL2: {machi,macli} = {            sum[47:0],macl[15:0]};
       MAC_DMULUL : {machi,macli} = {            sum[63:0] };
       MAC_DMULUL2: {machi,macli} = {            sum[47:0],macl[15:0]};
       MAC_MAC1W  : {machi,macli} = {            sum[63:0] };
       MAC_MACSW  : {machi,macli} = {mach[31:0] ,sum[31:0] };
       MAC_MAC1L  : {machi,macli} = {            sum[63:0] };
       MAC_MACSL  : {machi,macli} = {            sum[63:0] };
       MAC_MAC2L  : {machi,macli} = {            sum[47:0],macl[15:0]};
       MAC_MACS2  : {machi,macli} = {            sum[47:0],macl[15:0]};
       default    : {machi,macli} = {mach[31:0] ,macl[31:0]};
     endcase

   always_comb
     casez(X_macop.MAC)
       MAC_MACSW : 
         if(v)
           if(~sum[48]) {machj,maclj} = {(machi|32'h00000001),32'h7fffffff};
           else         {machj,maclj} = {(machi|32'h00000001),32'h80000000};
         else           {machj,maclj} = { machi              ,macli};
       MAC_MACS2 : 
         if(v)
           if(~sum[48]) {machj,maclj} = {32'h00007fff        ,32'hffffffff};
           else         {machj,maclj} = {32'hffff8000        ,32'h00000000};
         else           {machj,maclj} = { machi              ,macli};
       default :        {machj,maclj} = { machi              ,macli};
     endcase

   always_ff @(posedge clk)
     {mach,macl} <= {machj,maclj};
   
   always_comb
     casez(macop.MAC)
       MAC_STMACH : mluo.mac = machi;
       MAC_STMACL : mluo.mac = macli;
       default    : mluo.mac = {32{1'bx}};
     endcase

endmodule
