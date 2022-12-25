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

module rf
   (
    input               RegOp regop,
    input               ExuO exuo,
    input               MauO mauo,
    input logic         hldpc,
    input logic         clk, rst, stall,
    input               IntR intr,
    input               IntA inta,
    output              RfuO rfuo,
    output logic [31:0] pc
   );

   logic [15:0][31:0] gpr;
   logic [31:0]       gbr;
   logic [31:0]       vbr;
   logic [31:0]       pr;
   logic [31:0]       tmp;
   logic [31:0]       npc;
   wire [31:0]        pc2 = pc + 2;
   logic [31:0]       other;

   always_comb begin
      casez (regop.other)
        other_PC  : other = pc;
        other_R0  : other = gpr[0];
        other_SP  : other = gpr[15];
        other_SR  : other = {{22{1'b0}},
                             rfuo.sr.m, rfuo.sr.q,
                             rfuo.sr.i,
                             2'b00,
                             rfuo.sr.s, rfuo.sr.t};
        other_PR  : other = pr;
        other_GBR : other = gbr;
        other_VBR : other = vbr;
        other_TMP : other = tmp;
        default   : other = {32{1'bx}};
      endcase
   end
   always_comb begin
      casez (regop.Ra)
        Ra_imm  : rfuo.ra = {{19{regop.imm[12]}},regop.imm};
        Ra_Rn   : rfuo.ra = gpr[regop.Rn];
        Ra_R0   : rfuo.ra = gpr[0];
        Ra_nop  :
          if(intr.req)
            rfuo.ra = {{22{1'b0}},intr.vec[7:0],2'b00}|{{19{regop.imm[12]}},regop.imm}; //TEMP//TEMP//
          else // exception
            rfuo.ra = tmp;
        default : rfuo.ra = {32{1'bx}};
      endcase
   end
   always_comb begin
      casez (regop.Rb)
        Rb_imm   : rfuo.rb = {{19{regop.imm[12]}},regop.imm};
        Rb_Rm    : rfuo.rb = gpr[regop.Rm];
        Rb_other : rfuo.rb = other;
        default  : rfuo.rb = {32{1'bx}};
      endcase
   end
   always_comb begin
      casez (regop.Rs)
        Rs_R0    : rfuo.rs = gpr[0];
        Rs_Rm    : rfuo.rs = gpr[regop.Rm];
        Rs_other : rfuo.rs = other;
        default  : rfuo.rs = {32{1'bx}};
      endcase
   end
   always_comb begin //TEMP//TEMP// SP(R15) cnf must be added
      casez (regop.M_Wm)
        Wm_R0    : rfuo.cnf =   (regop.Ra == Ra_R0)
                             || (regop.Ra == Ra_Rn) && (regop.Rn == 4'h0)
                             || (regop.Rb == Rb_Rm) && (regop.Rm == 4'h0)
                             || (regop.Rb == Rb_other) && (regop.other == other_R0)
                             || (regop.Rs == Rs_R0)
                             || (regop.Rs == Rs_Rm) && (regop.Rm == 4'h0)
                             || (regop.Rs == Rs_other) && (regop.other == other_R0)
                             || (regop.We == We_R0) & ~mauo.rdy //WAW
                             || (regop.We == We_Rn) && (regop.Rn == 4'h0) & ~mauo.rdy //WAW
                             || (regop.We == We_Rm) && (regop.Rm == 4'h0) & ~mauo.rdy; //WAW
        Wm_Rn    : rfuo.cnf =   (regop.Ra == Ra_R0) && (regop.M_Rn == 4'h0)
                             || (regop.Ra == Ra_Rn) && (regop.M_Rn == regop.Rn)
                             || (regop.Rb == Rb_Rm) && (regop.M_Rn == regop.Rm)
                             || (regop.Rb == Rb_other) && (regop.other == other_R0) && (regop.M_Rn == 4'h0)
                             || (regop.Rs == Rs_R0) && (regop.M_Rn == 4'h0)
                             || (regop.Rs == Rs_Rm) && (regop.M_Rn == regop.Rm)
                             || (regop.Rs == Rs_other) && (regop.other == other_R0) && (regop.M_Rn == 4'h0)
                             || (regop.We == We_R0) && (regop.M_Rn == 4'h0) & ~mauo.rdy //WAW
                             || (regop.We == We_Rm) && (regop.M_Rn == regop.Rm) & ~mauo.rdy //WAW
                             || (regop.We == We_Rn) && (regop.M_Rn == regop.Rn) & ~mauo.rdy; //WAW
        Wm_PR    : rfuo.cnf =   (regop.Rb == Rb_other) && (regop.other == other_PR)
                             || (regop.Rs == Rs_other) && (regop.other == other_PR);
        Wm_SR    : rfuo.cnf =   (regop.Rb == Rb_other) && (regop.other == other_SR)
                             || (regop.Rs == Rs_other) && (regop.other == other_SR);
        Wm_PC    : rfuo.cnf =   (regop.Rb == Rb_other) && (regop.other == other_PC);
        default  : rfuo.cnf = 1'b0;
      endcase
      rfuo.pccnf = (regop.M_Wm==Wm_PC) & (regop.Rb == Rb_other) & (regop.other == other_PC);
   end

   always_comb begin
      rfuo.pc2 = pc2;
      if (regop.M_Wm==Wm_PC)
        if(mauo.rdy)
          npc = mauo.rslt;
        else
          npc = pc;
      else if (!stall && (regop.We==We_PC || regop.We==We_PC_PR || regop.We==We_GII || regop.We==We_SII))
        npc = exuo.addr;
      else if (!hldpc)
        npc = pc2;
      else
        npc = pc;
   end

   always_ff @(posedge clk) begin
      if(rst) begin
         rfuo.sr.i <= 4'hf;
         vbr <= {32{1'b0}};
         tmp <= {32{1'b0}};
         pc  <= {32{1'b0}};
      end else
         pc  <= npc;
      
      if(mauo.rdy)
        casez (regop.M_Wm)
          Wm_Rn  : gpr[regop.M_Rn] <= mauo.rslt;
          Wm_R0  : gpr[0]  <= mauo.rslt;
          Wm_R15 : gpr[15] <= mauo.rslt;
          Wm_GBR : gbr     <= mauo.rslt;
          Wm_VBR : vbr     <= mauo.rslt;
          Wm_PR  : pr      <= mauo.rslt;
          Wm_SR  : begin
             rfuo.sr.m <= mauo.rslt[9];
             rfuo.sr.q <= mauo.rslt[8];
             rfuo.sr.i <= mauo.rslt[7:4];
             rfuo.sr.s <= mauo.rslt[1];
             rfuo.sr.t <= mauo.rslt[0];
          end
        endcase

      if (~stall) begin
         casez (regop.We)
           We_Rn  : gpr[regop.Rn] <= exuo.rslt;
           We_Rm  : gpr[regop.Rm] <= exuo.rslt;
           We_R0  : gpr[0] <= exuo.rslt;
           We_SP  : gpr[15]<= exuo.rslt;
           We_GBR : gbr <= exuo.rslt;
           We_VBR : vbr <= exuo.rslt;
           We_PC_PR : pr <= pc2;
           We_PR  : pr  <= exuo.rslt;
           We_SR  : begin
              rfuo.sr.m <= exuo.rslt[9];
              rfuo.sr.q <= exuo.rslt[8];
              rfuo.sr.i <= exuo.rslt[7:4];
              rfuo.sr.s <= exuo.rslt[1];
              rfuo.sr.t <= exuo.rslt[0];
           end
           We_GII : tmp <= 32'h00000010;
           We_SII : tmp <= 32'h00000018;
           We_TMP : tmp <= exuo.rslt;
         endcase
         
         if (exuo.twen)
           rfuo.sr.t <= exuo.tbit;
         if (exuo.qwen)
           rfuo.sr.q <= exuo.qbit;
         if (exuo.mwen)
           rfuo.sr.m <= exuo.mbit;
      end
      if (inta.ack)//TEMP//TEMP//
        rfuo.sr.i <= intr.level[3:0]|{4{intr.level[4]}};
   end
endmodule
