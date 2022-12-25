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

module id
   (
    output             RegOp regop,
    output             ExuOp exuop,
    output             MemOp memop,
    output             MacOp macop,
    output logic       pc_hold, expr,
    output logic       ifstall, ifetch, ifetchl,
    output             OpSt opst,
    input logic        clk, rst, stall, istall, rte4, intreq,
    input logic        regcnf, rescnf,
    input logic [31:0] pc,
    input              IntR intr,
    output logic       intack,
    input              AhbR ahbr,
    input              RfuO rfuo,
    input              ExuO exuo,
    input              MauO mauo
   );

   logic [15:0]        op;
   IBuf opn, op2;

   always_ff @(posedge clk)
     if (ahbr.HREADY & ~mauo.bsy)
       ifetchl <= ifetch;

   wire op2u = ( (~stall & pc_hold & (memop.MEM != MEM_IF) &
                  ~((opst==LDPC)|(opst==LDPCR)|(opst==LDSRR)|
                    (opst==NOP3)|(opst==NOP2)|(opst==NOP1))) |
                 ((regcnf | rescnf) & (ifetchl&~mauo.bsy&ahbr.HREADY | op2.v)) );

   always_ff @(posedge clk) begin
      if(ahbr.HREADY)
        if(op2u)begin
           op2.inst <= op;
           op2.v    <= 1'b1;
        end else
          op2.v    <= 1'b0;
   end

   wire                pair_fetch = (pc[1] == 1'b0) & ifetchl & ~(intreq&~stall);

   always_ff @(posedge clk) begin
      if(pair_fetch & (memop.MEM != MEM_IF) & ahbr.HREADY & ~mauo.bsy) begin // TEMP BR
         opn.inst <= mauo.op[15:0];
         opn.v    <= 1'b1;
      end
      else if ((~stall & ~op2.v)|(opst==LDPC)|(opst==LDPCR)|(opst==RTE3))
        opn.v <= 1'b0;
   end

   always_comb
      if(rst|~ahbr.HREADY&~ifetchl|intreq&(opst==Run)&~stall)
        ifstall = 1'b1;
      else if(stall)
        ifstall = mauo.bsy&~(op2.v|opn.v);
      else if (intreq)
        ifstall = 1'b1;
      else if(pair_fetch | op2u)
        ifstall = 1'b0;
      else if((memop.MEM == MEM_NOP)|(memop.MEM == MEM_IF))
        ifstall = mauo.bsy;
      else
        ifstall = 1'b1;

   always_comb   //~istall && ~op2.v && ~opn.v
      if(rst|~ahbr.HREADY)
        ifetch = 1'b0;
      else if((opst==LDPC)|(opst==LDPCR)|(opst==LDSRR)|(opst==NOP3)|(opst==NOP2))
        ifetch = 1'b0;
      else if(rfuo.pccnf&(memop.MEM == MEM_IF))
        ifetch = 1'b0;
      else if (ifstall)     // istall pre
        ifetch = 1'b0;
      else if((memop.MEM == MEM_IF))
        ifetch = 1'b1;
      else if(op2u)                               // op2.v pre
        ifetch = 1'b0;
      else if(pair_fetch & (memop.MEM != MEM_IF)) // opn.v pre
        ifetch = 1'b0;
      else if((op2.v|stall)&opn.v)                // opn.v hold 1
        ifetch = 1'b0;
      else
        ifetch = 1'b1;

   always_comb
     if (op2.v)
       op = op2.inst;
     else if (opn.v)
       op = opn.inst;
     else if (~ifetchl)
       op = ({16{1'bx}});
     else if (pc[1] == 1'b0)
       op = mauo.op[31:16];
     else
       op = mauo.op[15:0];

   idec idec(.*);

endmodule
