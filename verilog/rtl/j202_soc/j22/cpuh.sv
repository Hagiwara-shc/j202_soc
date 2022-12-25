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

package cpu_pkg;
   typedef enum logic [2:0]
        {other_GBR, other_PC, other_PR, other_R0, other_SP, other_SR, other_VBR, other_TMP} other_reg_sel;
   typedef enum logic [1:0] {Ra_nop, Ra_Rn, Ra_imm, Ra_R0}     Ra_reg_sel;
   typedef enum logic [1:0] {Rb_nop, Rb_Rm, Rb_imm, Rb_other}  Rb_reg_sel;
   typedef enum logic [1:0] {Rs_nop, Rs_Rm, Rs_R0,  Rs_other}  Rs_reg_sel;
   typedef enum logic [3:0]
        {
         We_NOP, We_GBR, We_PC, We_PC_PR, We_PR,
         We_R0, We_SP, We_Rn, We_Rm, We_SR, We_VBR, We_TMP,
         We_GII, We_SII}   We_reg_sel;
   typedef enum logic [3:0]
        {
         Wm_NOP, Wm_GBR, Wm_PC,
         Wm_PR, Wm_R0, Wm_R15, Wm_Rn, Wm_SR, Wm_VBR}           Wm_reg_sel;
   typedef enum logic [1:0] {Ma_ALU, Ma_Ra, Ma_Rb, Ma_LD}      Ma_reg_sel;
   typedef enum logic [5:0]
        {
         EXU_ADD, EXU_ADDC, EXU_ADDV, EXU_ADD_FC, EXU_ADD_PC,
         EXU_SUB, EXU_SUBC, EXU_SUBV,
         EXU_DIV0U, EXU_DIV0S, EXU_DIV1,
         EXU_NOT, EXU_AND, EXU_ANDB, EXU_OR, EXU_ORB, EXU_XOR, EXU_XORB,
         EXU_BF, EXU_BFS, EXU_BT, EXU_BTS,
         EXU_CSTR, EXU_CEQ, EXU_CHS, EXU_CGE, EXU_CHI, EXU_CGT, EXU_CPZ, EXU_CPL,
         EXU_Rb, EXU_MAC,
         EXU_MOVT, EXU_SETT, EXU_CLRT, EXU_DT,
         EXU_TASB,  EXU_TST, EXU_TSTB,
         EXU_XTRCT, EXU_EXSW, EXU_SHIFT} EXU_op;
   typedef enum logic [7:0]
        {
         SHIFT_SHLL = 8'h00, SHIFT_SHAL  = 8'h20, SHIFT_SHLR = 8'h01, SHIFT_SHAR  = 8'h21,
         SHIFT_ROTL = 8'h04, SHIFT_ROTCL = 8'h24, SHIFT_ROTR = 8'h05, SHIFT_ROTCR = 8'h25,
         SHIFT_SHLL2 = 8'h08, SHIFT_SHLL8 = 8'h18, SHIFT_SHLL16 = 8'h28,
         SHIFT_SHLR2 = 8'h09, SHIFT_SHLR8 = 8'h19, SHIFT_SHLR16 = 8'h29} SHIFT_op;
   typedef enum logic [3:0]
        {
         EXSW_EXTUB = 4'hc, EXSW_EXTUW = 4'hd, EXSW_EXTSB = 4'he, EXSW_EXTSW = 4'hf,
         EXSW_SWAPB = 4'h8, EXSW_SWAPW = 4'h9} EXSW_op;
   typedef enum logic [3:0]
        {
         MEM_NOP, MEM_IF, MEM_TRP, MEM_LDB, MEM_LDW, MEM_LDL,
         MEM_STALUB, MEM_STMAC, MEM_STB, MEM_STW, MEM_STL,
         MEM_LDB_LOCK, MEM_STALUB_LOCK} MEM_op;
   typedef enum logic [1:0] {MEM_TCM0, MEM_TCM1, MEM_AHB, MEM_NON} MEM_area;
   typedef enum logic [4:0]
        {
         MAC_NOP, MAC_CLRMAC, MAC_STMACH, MAC_STMACL,
         MAC_MACHE, MAC_MACLE, MAC_MACHM, MAC_MACLM,
         MAC_MULL, MAC_MULUW, MAC_MULSW, MAC_DMULSL, MAC_DMULUL,
         MAC_MAC0L, MAC_MAC1L, MAC_MACSL, MAC_MAC0W, MAC_MAC1W, MAC_MACSW,
         MAC_MULL2, MAC_DMULSL2, MAC_DMULUL2, MAC_MAC2L, MAC_MACS2} MAC_op;
   typedef enum logic [4:0]
        {
         Run, DS, MACL, MACW, TASB, TSTB, ANDB, XORB, ORB,
         RTE2, RTE3,
         NOP1, NOP2, NOP3, LDPCR, LDSRR, STSR, STPC, LDPC, multi} OpSt;
   typedef struct packed {
      logic [15:0] inst;
      logic        v;
   } IBuf;
   typedef struct packed {
      logic [1:0] tcm;
   } CpuMode;
   typedef struct  packed {
      logic [3:0]  Rn;
      logic [3:0]  Rm;
      logic [12:0] imm;
      other_reg_sel other;
      Ra_reg_sel Ra;
      Rb_reg_sel Rb;
      Rs_reg_sel Rs;
      We_reg_sel We;
      Wm_reg_sel Wm;
      logic [3:0]  M_Rn; // M stage
      Wm_reg_sel M_Wm;  // M stage
   } RegOp;
   typedef struct  packed {
      EXU_op EXU;
   } ExuOp;
   typedef struct  packed {
      MEM_op MEM;
      Ma_reg_sel Ma;
   } MemOp;
   typedef struct  packed {
      MAC_op MAC;
   } MacOp;
   typedef struct  packed {
      logic        m, q;
      logic [3:0]  i;
      logic        s, t;
   } Reg_sr;
   typedef struct  packed {
      logic [31:0] ra;
      logic [31:0] rb;
      logic [31:0] rs;
      Reg_sr sr;
      logic        cnf;
      logic        pccnf;
      logic [31:0] pc2;
   } RfuO;
   typedef struct  packed {
      logic [31:0] rslt;
      logic [31:0] addr;
      logic        tbit;
      logic        twen;
      logic        qbit;
      logic        qwen;
      logic        mbit;
      logic        mwen;
      logic        cnf;
   } ExuO;
   typedef struct  packed {
      logic [31:0] rslt;
      logic [31:0] op;
      logic        bsy;
      logic        rdy;
   } MauO;
   typedef struct  packed {
      logic [31:0] mac;
      logic        bsy;
   } MluO;
   typedef struct  packed {
      logic [17:0] a;
      logic [31:0] d;
      logic        sel;
      logic        wr;
      logic [3:0]  be;
      logic        bsy; //TEMP//TEMP//
   } MemC;
   typedef struct  packed {
      logic [31:0] q;
   } MemR;
   typedef struct  packed {
      logic        req;  //TEMP//TEMP// = (level != 0)
      logic [4:0]  level; // 16 : nmi // 17 : address error
      logic [7:0]  vec;
   } IntR;
   typedef struct  packed {
      logic        ack;
   } IntA;

   typedef enum    logic [1:0] {AHB_IDLE = 2'b00, AHB_BUSY = 2'b01,
                                AHB_NONSEQ = 2'b10, AHB_SEQ = 2'b11} HTRANS_T;
   typedef enum    logic [2:0] {AHB_SINGLE = 3'b000, AHB_INCR   = 3'b001,
                                AHB_WRAP4  = 3'b010, AHB_INCR4  = 3'b011,
                                AHB_WRAP8  = 3'b100, AHB_INCR8  = 3'b101,
                                AHB_WRAP16 = 3'b110, AHB_INCR16 = 3'b111} HBURST_T;
   typedef struct  packed {
      logic        HSEL;
      logic [31:0] HADDR;
      logic [2:0]  HSIZE;
      logic        HWRITE;
      logic [31:0] HWDATA;
      HTRANS_T     HTRANS;
      HBURST_T     HBURST;
      logic        HMASTLOCK;
      logic        HREADY;
      logic [3:0]  HPROT;
   } AhbC;
   typedef enum    logic  {AHB_OKAY = 1'b0, AHB_ERROR = 1'b1} HRESP_T;
   typedef struct  packed {
      logic        HREADY;
      HRESP_T      HRESP;
      logic [31:0] HRDATA;
   } AhbR;

// for Aquarius peri
   typedef enum logic [1:0] {aqu_IDLE, aqu_BUSY, aqu_BUSY2} Aqu_st;
   typedef struct  packed {
      logic [3:0]  CE;
      logic        WE;
      logic [3:0]  SEL;
      logic [31:0] DATA;
      logic [31:0] ADR;
      logic        STB;
   } AquC;
   typedef struct  packed {
      logic [3:0]       ACK;
      logic [3:0][31:0] DATA;
   } AquR;

/* for Avalon NOT USE
   typedef enum logic [1:0] {avl_IDLE, avl_BUSY, avl_BUSY2} Avl_st;
   typedef struct  packed {
      logic        chipselect;
      logic [17:2] address;
      logic        read_n;
      logic        write_n;
      logic [31:0] writedata;

   } AvlC;
   typedef struct  packed {
      logic [31:0] readdata;
      logic        waitrequest;
   } AvlR;
*/
endpackage
