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

module idec
   (
    output             RegOp regop,
    output             ExuOp exuop,
    output             MemOp memop,
    output             MacOp macop,
    output logic       pc_hold, expr,
    output             OpSt opst,
    input logic        clk, rst, stall, rte4, intreq,
    input logic [15:0] op,
    input              IntR intr,
    output logic       intack,
    input              RfuO rfuo,
    input              MauO mauo
   );

   // synopsys translate_off
   string              mnem;
   // synopsys translate_on

   assign              expr = ((opst == DS)&((memop.MEM==MEM_IF)|(memop.MEM==MEM_TRP)|(regop.We==We_SP)|(regop.We==We_GII))); //slot illegal

   always_ff @(posedge clk) begin
      if (rst) begin
         opst <= LDPCR;
         pc_hold <= 1'b1;
         memop.MEM <= MEM_NOP;
         macop.MAC <= MAC_NOP;
         intack <= 1'b0;
      end else if(stall) begin
      end else if(pc_hold) begin
         regop.We <= We_NOP;
         regop.Wm <= Wm_NOP;
         pc_hold <= 1'b0;
         memop.MEM <= MEM_NOP;
         macop.MAC <= MAC_NOP;
         opst <= Run;
         casez(opst)
`include "multi"
         endcase
         if((opst == NOP3)|(opst == LDSRR)&(intr.vec!=8'h00)) //exception or
           intack <= 1'b1;                                  //MRST not PRST
         else
           intack <= 1'b0;
      end else begin
         regop.We <= We_NOP;
         regop.Wm <= Wm_NOP;
         pc_hold <= 1'b0;
         memop.MEM <= MEM_NOP;
         macop.MAC <= MAC_NOP;
         intack <= 1'b0;
         opst <= Run;
         casez(op)
`include "first"
           default : begin
              // synopsys translate_off
              mnem = "illegal instruction";
              // synopsys translate_on
              pc_hold <= 1'b1;
              opst <= STSR;
              regop.imm <= -2;
              regop.other <= other_PC;
              regop.Ra <= Ra_imm;
              regop.Rb <= Rb_other;
              regop.Rs <= Rs_nop;
              regop.We <= We_GII;
              exuop.EXU <= EXU_ADD;
              regop.Wm <= Wm_NOP;
              memop.MEM <= MEM_NOP;
              macop.MAC <= MAC_NOP;
           end
         endcase
      end
//      if(intreq&~rte4&(opst==Run))begin //TEMP//TEMP// delay slot?
      if(intreq&(opst==Run))begin
         if(intr.vec == 8'h02)
           opst <= LDPCR;
         else
           opst <= STSR;
         pc_hold <= 1'b1;
      end
      if(~stall&(memop.MEM == MEM_IF)&~((exuop.EXU==EXU_BT)|(exuop.EXU==EXU_BF)|intreq)) begin
         opst <= DS; // delay slot
      end
      if((opst == DS)&((memop.MEM==MEM_IF)|(memop.MEM==MEM_TRP)|(regop.We==We_SP)|(regop.We==We_GII))) begin //slot illegal
         // synopsys translate_off
         mnem = "illegal instruction";
         // synopsys translate_on
         pc_hold <= 1'b1;
         opst <= STSR;
         regop.imm <= -2;
         regop.other <= other_PC;
         regop.Ra <= Ra_imm;
         regop.Rb <= Rb_other;
         regop.Rs <= Rs_nop;
         regop.We <= We_SII;
         exuop.EXU <= EXU_ADD;
         regop.Wm <= Wm_NOP;
         memop.MEM <= MEM_NOP;
         macop.MAC <= MAC_NOP;
      end 
      if (rst|expr) begin
         regop.M_Wm <= Wm_NOP;
      end else if(mauo.bsy) begin
      end else if(~stall|(regop.M_Wm!=MEM_NOP)) begin
         regop.M_Rn <= regop.Rn;
         if(stall)
           regop.M_Wm <= Wm_NOP;
         else
           regop.M_Wm <= regop.Wm;
      end
   end
endmodule
