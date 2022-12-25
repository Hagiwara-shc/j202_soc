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

//////////////////////////////////////////////////////////////////////////////////
//
//  SH Consulting
//
// Filename        : ex.v
// Description     : Exicution module.
//                   
//					
//
// Author          : Hayashi
// Created On      : 
// History (Date, Changed By)
// - August 1, 2017 : Duong modify EXU_CGT.
//
//////////////////////////////////////////////////////////////////////////////////
import cpu_pkg::*;

module ex
  (
   input       ExuOp exuop,
   input       RfuO rfuo,
   input       MauO mauo,
   input       MluO mluo,
   input logic clk, rst, stall,
   output      ExuO exuo
   );

   logic [31:0] ina, inb;
   logic        cin;
   logic        cgt_tbit;
   
   wire [32:0]  sum = {1'b0,ina} + {1'b0,inb} + cin;
   //-----------------------------------------------------------------------------
   //Duong's modification   
   assign cgt_tbit = ~(sum[32]^ina[31]^inb[31]); 
   //-----------------------------------------------------------------------------
   assign exuo.cnf = (mauo.bsy & ((exuop.EXU == EXU_TASB)|(exuop.EXU == EXU_XORB)|(exuop.EXU == EXU_TSTB)|(exuop.EXU==EXU_ANDB)|(exuop.EXU==EXU_ORB))); //TEMP//TEMP//

   always_comb
     casez (exuop.EXU)
       EXU_BT   : exuo.addr = (!rfuo.sr.t) ? rfuo.rb  : sum[31:0];
       EXU_BTS  : exuo.addr = (!rfuo.sr.t) ? rfuo.pc2 : sum[31:0]; //TEMP//TEMP//
       EXU_BF   : exuo.addr = ( rfuo.sr.t) ? rfuo.rb  : sum[31:0];
       EXU_BFS  : exuo.addr = ( rfuo.sr.t) ? rfuo.pc2 : sum[31:0]; //TEMP//TEMP//
       default  : exuo.addr = sum[31:0];
     endcase

   always_comb
     casez (exuop.EXU)
       EXU_ADD    : begin ina = rfuo.ra; inb = rfuo.rb; cin = 1'b0; end
       EXU_ADDC   : begin ina = rfuo.ra; inb = rfuo.rb; cin = rfuo.sr.t; end
       EXU_ADDV   : begin ina = rfuo.ra; inb = rfuo.rb; cin = 1'b0; end
       EXU_ADD_FC : begin ina = rfuo.ra; inb = {rfuo.rb[31:2],{2{rfuo.rb[1]}}}; cin = rfuo.rb[1]; end
       EXU_ADD_PC : begin ina = rfuo.ra; inb = {rfuo.rb[31:1],1'b1}; cin = 1'b1; end
       EXU_SUB    : begin ina = rfuo.ra; inb = ~rfuo.rb; cin = 1'b1; end
       EXU_SUBC   : begin ina = rfuo.ra; inb = ~rfuo.rb; cin = ~rfuo.sr.t; end
       EXU_SUBV   : begin ina = rfuo.ra; inb = ~rfuo.rb; cin = 1'b1; end
       EXU_DIV1   : begin
          ina = ({rfuo.ra[30:0],rfuo.sr.t});
          inb = (rfuo.sr.m == rfuo.sr.q) ? ~rfuo.rb : rfuo.rb;
          cin = (rfuo.sr.m == rfuo.sr.q) ? 1'b1     : 1'b0;
       end
       EXU_BT     : begin ina = rfuo.ra; inb = {rfuo.rb[31:1],1'b1}; cin = 1'b1; end
       EXU_BTS    : begin ina = rfuo.ra; inb = {rfuo.rb[31:1],1'b1}; cin = 1'b1; end
       EXU_BF     : begin ina = rfuo.ra; inb = {rfuo.rb[31:1],1'b1}; cin = 1'b1; end
       EXU_BFS    : begin ina = rfuo.ra; inb = {rfuo.rb[31:1],1'b1}; cin = 1'b1; end
       EXU_DT     : begin ina = rfuo.ra; inb = ~rfuo.rb; cin = 1'b1; end
       EXU_CHS    : begin ina = rfuo.ra; inb = ~rfuo.rb; cin = 1'b1; end
       EXU_CGE    : begin ina = rfuo.ra; inb = ~rfuo.rb; cin = 1'b1; end
       EXU_CHI    : begin ina = rfuo.ra; inb = ~rfuo.rb; cin = 1'b0; end
       EXU_CGT    : begin ina = rfuo.ra; inb = ~rfuo.rb; cin = 1'b0; end //Sumumu'san idea, change cin to 0
       default    : begin ina = {32{1'bx}}; inb = {32{1'bx}}; cin = 1'bx; end
     endcase

   logic [31:0] logicalo;
   always_comb
     casez (exuop.EXU)
       EXU_NOT    : logicalo = ~rfuo.rb;
       EXU_AND    : logicalo = rfuo.ra&rfuo.rb;
       EXU_ANDB   : logicalo = rfuo.ra&mauo.rslt;
       EXU_OR     : logicalo = rfuo.ra|rfuo.rb;
       EXU_ORB    : logicalo = rfuo.ra|mauo.rslt;
       EXU_XOR    : logicalo = rfuo.ra^rfuo.rb;
       EXU_XORB   : logicalo = rfuo.ra^mauo.rslt;
       EXU_Rb     : logicalo = rfuo.rb;
       EXU_MOVT   : logicalo = {{30{1'b0}},rfuo.sr.t};
       EXU_TASB   : logicalo = 32'h00000080|mauo.rslt;
       EXU_XTRCT  : logicalo = {rfuo.rb[15:0],rfuo.ra[31:16]};
       EXU_EXSW   :
         casez (EXSW_op'(rfuo.ra[3:0]))
           EXSW_EXTSB  : logicalo = {{24{rfuo.rb[ 7]}},rfuo.rb[ 7:0]};
           EXSW_EXTSW  : logicalo = {{16{rfuo.rb[15]}},rfuo.rb[15:0]};
           EXSW_EXTUB  : logicalo = {{24{1'b0}},rfuo.rb[ 7:0]};
           EXSW_EXTUW  : logicalo = {{16{1'b0}},rfuo.rb[15:0]};
           EXSW_SWAPW  : logicalo = {rfuo.rb[15:0],rfuo.rb[31:16]};
           EXSW_SWAPB  : logicalo = {rfuo.rb[31:16],rfuo.rb[7:0],rfuo.rb[15:8]};
           default     : logicalo = {32{1'bx}};
         endcase
       default    : logicalo = {32{1'bx}};
     endcase

   logic [31:0] shifto;
   always_comb
     casez (SHIFT_op'(rfuo.rb[7:0]))
       SHIFT_SHLL   : shifto = {rfuo.ra[30:0],1'b0};
       SHIFT_SHAL   : shifto = {rfuo.ra[30:0],1'b0};
       SHIFT_SHLR   : shifto = {1'b0,rfuo.ra[31:1]};
       SHIFT_SHAR   : shifto = {rfuo.ra[31],rfuo.ra[31:1]};
       SHIFT_ROTL   : shifto = {rfuo.ra[30:0],rfuo.ra[31]};
       SHIFT_ROTCL  : shifto = {rfuo.ra[30:0],rfuo.sr.t};
       SHIFT_ROTR   : shifto = {rfuo.ra[0],rfuo.ra[31:1]};
       SHIFT_ROTCR  : shifto = {rfuo.sr.t,rfuo.ra[31:1]};
       SHIFT_SHLL2  : shifto = {rfuo.ra[29:0],2'b00};
       SHIFT_SHLL8  : shifto = {rfuo.ra[23:0],8'h00};
       SHIFT_SHLL16 : shifto = {rfuo.ra[15:0],16'h0000};
       SHIFT_SHLR2  : shifto = {2'b00,rfuo.ra[31:2]};
       SHIFT_SHLR8  : shifto = {8'h00,rfuo.ra[31:8]};
       SHIFT_SHLR16 : shifto = {16'h0000,rfuo.ra[31:16]};
       default      : shifto = {32{1'bx}};
     endcase

   always_comb begin
      casez (exuop.EXU)
        EXU_ADD    ,        EXU_ADDC   ,        EXU_ADDV   ,        EXU_ADD_FC ,
        EXU_ADD_PC ,        EXU_SUB    ,        EXU_SUBC   ,        EXU_SUBV   ,
        EXU_DIV1   ,        EXU_DT                                             : exuo.rslt = sum[31:0];
        EXU_MAC                                                                : exuo.rslt = mluo.mac;
        EXU_NOT    ,        EXU_AND    ,        EXU_ANDB   ,        EXU_OR     ,
        EXU_ORB    ,        EXU_XOR    ,        EXU_XORB   ,        EXU_Rb     ,
        EXU_MOVT   ,        EXU_TASB   ,        EXU_XTRCT  ,        EXU_EXSW   : exuo.rslt = logicalo;
        EXU_SHIFT                                                              : exuo.rslt = shifto;
        default                                                                : exuo.rslt = {32{1'bx}};
      endcase
      exuo.tbit = 1'bx; exuo.qbit = 1'bx; exuo.mbit = 1'bx;
      exuo.twen = !stall;
      exuo.qwen = 1'b0;
      exuo.mwen = 1'b0;
      casez (exuop.EXU)
        EXU_CEQ    : exuo.tbit = (rfuo.ra==rfuo.rb);
        EXU_CHS    : exuo.tbit =  sum[32];
   //-----------------------------------------------------------------------------
   //Duong's modification		
        EXU_CGE    : exuo.tbit = cgt_tbit;
   //-----------------------------------------------------------------------------	
   
        EXU_CHI    : exuo.tbit =  sum[32];
   //-----------------------------------------------------------------------------
   //Duong's modification		
        EXU_CGT    : exuo.tbit = cgt_tbit;//Sumumu'san idea.
   //-----------------------------------------------------------------------------		
        EXU_CPZ    : exuo.tbit = (!rfuo.ra[31]);
        EXU_CPL    : exuo.tbit = ((!rfuo.ra[31])&(|rfuo.ra[30:0]));
        EXU_CSTR   : exuo.tbit = ((rfuo.ra[31:24]==rfuo.rb[31:24])|(rfuo.ra[23:16]==rfuo.rb[23:16])|(rfuo.ra[15:8]==rfuo.rb[15:8])|(rfuo.ra[7:0]==rfuo.rb[7:0]));
        EXU_CLRT   : exuo.tbit = 1'b0;
        EXU_SETT   : exuo.tbit = 1'b1;
        EXU_ADDC   : exuo.tbit =  sum[32];
        EXU_ADDV   : exuo.tbit =  sum[32]^sum[31]^ina[31]^inb[31];
        EXU_SUBC   : exuo.tbit = ~sum[32];
        EXU_SUBV   : exuo.tbit =  sum[32]^sum[31]^ina[31]^inb[31];
        EXU_DIV0U  : begin exuo.qbit = 1'b0;        exuo.mbit = 1'b0;        exuo.tbit = 1'b0;                         exuo.qwen = 1'b1; exuo.mwen = 1'b1; end
        EXU_DIV0S  : begin exuo.qbit = rfuo.ra[31]; exuo.mbit = rfuo.rb[31]; exuo.tbit = (rfuo.ra[31] != rfuo.rb[31]); exuo.qwen = 1'b1; exuo.mwen = 1'b1; end
        EXU_DIV1   : begin exuo.qbit = ~sum[32]^rfuo.ra[31]^rfuo.sr.q;            exuo.qwen = 1'b1;
                           exuo.tbit =  sum[32]^rfuo.ra[31]^rfuo.sr.q^rfuo.sr.m;                    end
        EXU_DT     : exuo.tbit = (rfuo.ra==rfuo.rb);
        EXU_TST    : exuo.tbit = ((rfuo.ra&rfuo.rb)=={32{1'b0}});
        EXU_TSTB   : exuo.tbit = ((rfuo.ra[7:0]&mauo.rslt[7:0])==8'h00);
        EXU_TASB   : exuo.tbit = (mauo.rslt=={32{1'b0}});
        EXU_SHIFT  :
          casez (SHIFT_op'(rfuo.rb[7:0]))
            SHIFT_SHLL  : exuo.tbit = rfuo.ra[31];
            SHIFT_SHAL  : exuo.tbit = rfuo.ra[31];
            SHIFT_SHLR  : exuo.tbit = rfuo.ra[ 0];
            SHIFT_SHAR  : exuo.tbit = rfuo.ra[ 0];
            SHIFT_ROTL  : exuo.tbit = rfuo.ra[31];
            SHIFT_ROTCL : exuo.tbit = rfuo.ra[31];
            SHIFT_ROTR  : exuo.tbit = rfuo.ra[ 0];
            SHIFT_ROTCR : exuo.tbit = rfuo.ra[ 0];
            default     : exuo.twen = 1'b0;
          endcase
        default    : exuo.twen = 1'b0;
      endcase

   end
endmodule
