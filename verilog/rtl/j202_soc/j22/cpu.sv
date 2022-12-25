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

module cpu
   (
    input       clk, rst,
    input [1:0] md_boot,
    input       CpuMode cpumode,
    input       IntR intr,
    output      IntA inta,
    input       MemR [1:0] memr,
    output      MemC [1:0] memc,
    input       AhbR ahbr,
    output      AhbC ahbc
   );
   logic [15:0] op;
   logic [31:0] pc;
   logic        pc_hold, expr;
   logic        ifstall, ifetch, ifetchl;
   logic        stall, istall;

   RegOp regop;
   ExuOp exuop;
   MemOp memop;
   MacOp macop;
   RfuO  rfuo;
   ExuO  exuo;
   MauO  mauo;
   MluO  mluo;
   
///TEMP//TEMP//
   OpSt opst;
   wire         ifbsy = (ifetchl & ~mauo.rdy)|((opst==NOP1)&~ifetchl&~cpumode.tcm[0]);
   wire         intreq = intr.req&(intr.level>rfuo.sr.i)&~stall;
   logic        rte4;
   always_ff @(posedge clk)
     if(rst)
       rte4 <= 1'b0;
     else if(ahbr.HREADY&~stall)
       rte4 <= (opst == RTE3);

   wire         intack;
   assign inta.ack = intack & ~stall;

///TEMP//TEMP//
   always_ff @(posedge clk)
     if(rst)
       istall <= 1'b1;
     else if(ahbr.HREADY|ifetchl)
       istall  <= ifstall & ~(pc_hold&~stall) & ~exuo.cnf & ~(intreq&((opst==STPC)|(opst==STSR)|(opst==LDPC)));

   assign       stall  = istall | rfuo.cnf | exuo.cnf | mluo.bsy | ~ahbr.HREADY | mauo.bsy&(memop.MEM==MEM_IF) | ifbsy | expr | rfuo.pccnf&(memop.MEM==MEM_IF);
   wire         regcnf = ~istall &(rfuo.cnf | exuo.cnf);
   wire         rescnf = ~istall & mluo.bsy;
   wire         hldpc  = ifstall | (pc_hold&~stall) | regcnf | rescnf | mauo.bsy&(memop.MEM==MEM_IF) | ifbsy | rte4 | rst;

   id id(.*);
   rf rf(.*);
   ex ex(.*);
   ma ma(.*);
   ml ml(.*);
   
endmodule
