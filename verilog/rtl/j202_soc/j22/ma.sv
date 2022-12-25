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

module ma
   (
    input       clk, rst, stall,
    input [1:0] md_boot,
    input       CpuMode cpumode,
    input       MemOp memop,
    input       RfuO rfuo,
    input       ExuO exuo,
    input       MluO mluo,
    input       ifetch, ifetchl,
    output      MauO mauo,
    input       MemR [1:0] memr,
    output      MemC [1:0] memc,
    input       AhbR ahbr,
    output      AhbC ahbc
   );

   localparam MD_BOOT_TCM0 = 2'b01;

   logic [31:0]         address;
   logic [31:0]         rdata;
   logic [1:0]          M_address;
   logic                lock;
   logic [31:18]        tcm0_base, tcm1_base;
   MemC memci;
   MEM_op M_MEM;
   MEM_area area, M_area;

   // Address map of TCMs
   assign tcm0_base = (md_boot == MD_BOOT_TCM0) ? 20'h0000/4: 20'hfff8/4;
   assign tcm1_base = 20'hfffc/4;

   wire   E_hrdy   = ahbr.HREADY;//TEMP//TEMP// if tcm has hready
   wire   M_hrdy   = ahbr.HREADY;

   assign mauo.bsy = (~E_hrdy)&(M_MEM!=MEM_IF);
   assign mauo.rdy = (M_MEM != MEM_NOP) & M_hrdy;

   always_ff @(posedge clk) begin
      if(rst) begin
            M_MEM <= MEM_NOP;
            M_area <= MEM_NON;
      end else if(~M_hrdy) begin
      end else if(mauo.bsy) begin
      end else begin
         M_area <= area;
         M_address <= address[1:0];
         if(ifetch)
           M_MEM <= MEM_IF;
         else
           M_MEM <= memop.MEM;
      end
   end

   always_comb
     if(stall&~(mauo.bsy&(memop.MEM==MEM_IF)) | (memop.MEM == MEM_NOP))
       address = rfuo.pc2 & 32'hfffffffd;
     else
       case(memop.Ma)
         Ma_Ra   : address = rfuo.ra;
         Ma_Rb   : address = rfuo.rb;
         Ma_ALU  : address = exuo.addr;
         Ma_LD   : address = rdata;
         default : address = {32{1'bx}};
       endcase
   
   always_comb begin
      memci.d = {32{1'bx}};
      memci.be = 4'b1111;  //TEMP//TEMP//
      case(memop.MEM)
        MEM_STALUB, MEM_STALUB_LOCK :
          case(address[1:0])
            2'b00 : begin memci.d[31:24] = exuo.rslt[7:0]; memci.be = 4'b1000; end
            2'b01 : begin memci.d[23:16] = exuo.rslt[7:0]; memci.be = 4'b0100; end
            2'b10 : begin memci.d[15: 8] = exuo.rslt[7:0]; memci.be = 4'b0010; end
            2'b11 : begin memci.d[ 7: 0] = exuo.rslt[7:0]; memci.be = 4'b0001; end
          endcase
        MEM_STB :
          case(address[1:0])
            2'b00 : begin memci.d[31:24] = rfuo.rs[7:0]; memci.be = 4'b1000; end
            2'b01 : begin memci.d[23:16] = rfuo.rs[7:0]; memci.be = 4'b0100; end
            2'b10 : begin memci.d[15: 8] = rfuo.rs[7:0]; memci.be = 4'b0010; end
            2'b11 : begin memci.d[ 7: 0] = rfuo.rs[7:0]; memci.be = 4'b0001; end
          endcase
        MEM_STW :
          case(address[1])
            1'b0 : begin memci.d[31:16] = rfuo.rs[15:0]; memci.be = 4'b1100; end
            1'b1 : begin memci.d[15: 0] = rfuo.rs[15:0]; memci.be = 4'b0011; end
          endcase
        MEM_STMAC :
          begin memci.d = mluo.mac; memci.be = 4'b1111; end
        MEM_STL :
          begin memci.d = rfuo.rs; memci.be = 4'b1111; end
        MEM_LDB, MEM_LDB_LOCK :
          case(address[1:0])
            2'b00 : memci.be = 4'b1000;
            2'b01 : memci.be = 4'b0100;
            2'b10 : memci.be = 4'b0010;
            2'b11 : memci.be = 4'b0001;
          endcase
        MEM_LDW :
          case(address[1])
            1'b0 : memci.be = 4'b1100;
            1'b1 : memci.be = 4'b0011;
          endcase
        MEM_IF :
          case(address[1])
            1'b0 : memci.be = 4'b1111;
            1'b1 : memci.be = 4'b0011;
          endcase
      endcase
      memci.a = address[17:0];
      memci.wr = ((memop.MEM == MEM_STALUB) | (memop.MEM == MEM_STB) |
                  (memop.MEM == MEM_STW)    | (memop.MEM == MEM_STL) |
                  (memop.MEM == MEM_STMAC)  | (memop.MEM == MEM_STALUB_LOCK)) & ~stall;
      lock = ((memop.MEM == MEM_STALUB_LOCK) | (memop.MEM == MEM_LDB_LOCK)) & ~stall;
   end

   always_comb begin
      if((((memop.MEM == MEM_NOP)|(memop.MEM == MEM_IF)) & ~ifetch)) begin
         area = MEM_NON;
         memc[0] = '{default:0};
         memc[1] = '{default:0};
      end else if((address[31:18] == tcm0_base) & cpumode.tcm[0]) begin
         area = MEM_TCM0;
         memc[0] = memci;
         memc[0].sel = ~stall | ifetch;
         memc[1] = '{default:0};
      end else if((address[31:18] == tcm1_base) & cpumode.tcm[1]) begin
         area = MEM_TCM1;
         memc[1] = memci;
         memc[1].sel = ~stall | ifetch;
         memc[0] = '{default:0};
      end else begin
         area = MEM_AHB;
         memc[0] = '{default:0};
         memc[1] = '{default:0};
      end
      memc[0].bsy = 1'b0; //TEMP//TEMP//
      memc[1].bsy = 1'b0; //TEMP//TEMP//
   end

//////////////////////////////TEMP//////////TEMP//////////TEMP
   always_comb begin
      ahbc.HBURST = AHB_SINGLE;
      ahbc.HMASTLOCK = lock;
      ahbc.HPROT[3:0] = 4'b0011;
      ahbc.HADDR[31:0] = address;
      case(memop.MEM)
        MEM_STALUB, MEM_STALUB_LOCK : ahbc.HSIZE[2:0] = 3'b000;
        MEM_STB    : ahbc.HSIZE[2:0] = 3'b000;
        MEM_STW    : ahbc.HSIZE[2:0] = 3'b001;
        MEM_STMAC  : ahbc.HSIZE[2:0] = 3'b010;
        MEM_STL    : ahbc.HSIZE[2:0] = 3'b010;
        MEM_LDB, MEM_LDB_LOCK       : ahbc.HSIZE[2:0] = 3'b000;
        MEM_LDW    : ahbc.HSIZE[2:0] = 3'b001;
        MEM_LDL    : ahbc.HSIZE[2:0] = 3'b010;
        MEM_NOP    : ahbc.HSIZE[2:0] = 3'b010;
        MEM_IF     : 
          begin
            if(address[1])
              ahbc.HSIZE[2:0] = 3'b001;
            else
              ahbc.HSIZE[2:0] = 3'b010;
            ahbc.HPROT[0] = 1'b0;
          end
        default : ahbc.HSIZE[2:0] = 3'bxxx;
      endcase
      ahbc.HWRITE = memci.wr & (area == MEM_AHB);
      if (ahbr.HREADY & (area == MEM_AHB))
        ahbc.HTRANS = AHB_NONSEQ;
      else
        ahbc.HTRANS = AHB_IDLE;
   end
   always_ff @(posedge clk) begin
      if(memci.wr)
        ahbc.HWDATA[31:0] = memci.d;
   end

   always_comb
     if(M_area == MEM_TCM0)
       rdata = memr[0].q;
     else if(M_area == MEM_TCM1)
       rdata = memr[1].q;
     else if(M_area == MEM_AHB)
       rdata = ahbr.HRDATA;
     else
       rdata = {32{1'bx}};

   assign mauo.op = rdata;

   always_comb
     case(M_MEM)
       MEM_LDB, MEM_LDB_LOCK :
         case(M_address[1:0])
           2'b00 : mauo.rslt = {{24{rdata[31]}},rdata[31:24]};
           2'b01 : mauo.rslt = {{24{rdata[23]}},rdata[23:16]};
           2'b10 : mauo.rslt = {{24{rdata[15]}},rdata[15: 8]};
           2'b11 : mauo.rslt = {{24{rdata[ 7]}},rdata[ 7: 0]};
         endcase
       MEM_LDW :
         case(M_address[1])
           1'b0 : mauo.rslt = {{16{rdata[31]}},rdata[31:16]};
           1'b1 : mauo.rslt = {{16{rdata[15]}},rdata[15: 0]};
         endcase
       MEM_LDL :
         mauo.rslt = rdata[31:0];
       default :
         mauo.rslt = {32{1'bx}};
     endcase

endmodule
