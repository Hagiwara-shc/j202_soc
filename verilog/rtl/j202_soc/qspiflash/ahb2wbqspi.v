
// Copyright (c) 2007 TooMuch Semiconductor Solutions Pvt Ltd.


//File name     :   ahb2wbqspi.v
//Designer      :   Manish Agarwal
//Date          :   18 May, 2007
//Description   :   AHB WISHBONE BRIDGE :- This design will connect AHB master interface with Wishbone slave.
//                  This design will perform only single read-write operation.
//Revision      :   1.0

//History       :   06-02-2018 K.Hagiwara Modified for wbqspiflash.v (OpenCores)

// Disclaimer
// This source file may be used and distributed without restriction provided that this copyright
// statement is not removed from the file and that any derivative work contains the original
// copyright notice and the associated disclaimer.
// This software is provided “as is” and without any express or implied warranties, including,
// but not limited to, the implied warranties of merchantability and fitness for a particular
// purpose. in no event shall the author or contributors be liable for any direct, indirect,
// incidental, special, exemplary, or consequential damages (including, but not limited to,
// procurement of substitute goods or services; loss of use, data, or profits; or business
// interruption) however caused and on any theory of liability, whether in contract, strict
// liability, or tort (including negligence or otherwise) arising in any way out of the use of this
// software, even if advised of the possibility of such damage.

//******************************************************************************************************

module ahb2wbqspi (
  adr_o, dat_o, stall_i, dat_i, ack_i, cyc_o,
  we_o, stb_data_o, stb_ctrl_o,
  hclk, hresetn, haddr, htrans, hwrite, hsize, hburst,
  hsel, hwdata, hrdata, hresp, hready
  );


//parameter declaration
  parameter AWIDTH = 32;
  parameter DWIDTH = 32;


//**************************************
// input ports
//**************************************

 //wishbone ports     
  input stall_i;            // stall input from wishbone slave
  input [DWIDTH-1:0]dat_i;  // data input from wishbone slave
  input ack_i;              // acknowledment from wishbone slave
  
 //AHB ports  
  input hclk;               // clock
  input hresetn;            // active low reset
  input [DWIDTH-1:0]hwdata; // data bus   
  input hwrite;             // write/read enable
  input [2:0]hburst;        // burst type
  input [2:0]hsize;         // data size
  input [1:0]htrans;        // type of transfer
  input hsel;               // slave select 
  input [AWIDTH-1:0]haddr;  // address bus  


//**************************************
// output ports
//**************************************

 //wishbone ports
  output [AWIDTH-1:0]adr_o; // address to wishbone slave 
  output [DWIDTH-1:0]dat_o; // data output for wishbone slave
  output cyc_o;             // signal to indicate valid bus cycle
  output we_o;              // write enable
  output stb_data_o;        // strobe to indicate valid data transfer cycle for data
  output stb_ctrl_o;        // strobe to indicate valid data transfer cycle for registers
    

 // AHB ports
  output [DWIDTH-1:0]hrdata; // data output for wishbone slave
  output hresp;              // response signal from slave
  output hready;             // slave ready


//**************************************
// inout ports
//**************************************


//**********************************************************************************


// datatype declaration
  reg [DWIDTH-1:0]hrdata;
  reg hready;
  reg hresp;
  reg stb_o;
  wire we_o;
  reg cyc_o;
  wire [AWIDTH-1:0]adr_o;
  reg [DWIDTH-1:0]dat_o;
  
// local memory registers
  reg [AWIDTH-1 : 0]addr_temp;
  reg hwrite_temp;                // to hold write enable signal temporarily

//*******************************************************************
// AHB WISHBONE BRIDGE logic
//*******************************************************************
            
  assign we_o  = hwrite_temp;
  assign adr_o = addr_temp;

  always @ (posedge hclk ) begin
    if (!hresetn) begin
      hresp  <= 1'b0;
      cyc_o  <= 'b0;
      stb_o  <= 'b0;
    end
    else if(hready & hsel) begin
      case (hburst)
        // single transfer
        3'b000  :   begin                     
                case (htrans)
                  // idle transfer type
                  2'b00 : begin
                        hresp <= 1'b0;     // ok response
                        cyc_o <= 'b0;
                        stb_o <= 'b0;
                      end

                  // busy transfer type
                  2'b01 : begin             
                        hresp <= 1'b0;     // ok response
                        cyc_o <= 'b1;
                        stb_o <= 'b0;
                      end
  
                  // Non-Sequential
                  2'b10 : begin
                        cyc_o <= 'b1;
                        stb_o <= 'b1;
                        addr_temp <= haddr;
                        hwrite_temp <= hwrite;  // control signal stored that was received in address phase
                      end
                endcase
              end

        default :   cyc_o <= 'b0;
      endcase
    end
    else if (!hsel & hready) begin
      cyc_o <= 'b0;           //invalid bus transfer
      stb_o <= 'b0;
    end
  end

  assign stb_data_o = stb_o & ~addr_temp[24];
  assign stb_ctrl_o = stb_o &  addr_temp[24];


// combinational logic - asynchronous read/write
  always@(hwdata or dat_i or ack_i or hresetn or stb_o ) begin
    hready = ~hresetn ? 1'b1 :
             stb_o ? ack_i : 1'b1;
    dat_o  = hwdata;
    hrdata = dat_i;
  end 
    
endmodule

