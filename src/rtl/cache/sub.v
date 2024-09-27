`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/06/2023 10:58:21 PM
// Design Name: 
// Module Name: proc_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module proc_subtraction(
input         clk_200M,
input         rst_200M,
//data
input  [14:0]i_rec_addr, // i read addr
input  i_rec_ce,   
input  i_rec_we,
input  [39:0]i_rec_d,
output reg [25:0] sum_traction,
input  refresh
);
(* MARK_DEBUG="true" *)wire [14:0]get_addr;
(* MARK_DEBUG="true" *)wire work_enable;
assign work_enable = i_rec_ce&i_rec_we;
(* MARK_DEBUG="true" *)reg ce_tmp1;
reg ce_tmp2;
(* MARK_DEBUG="true" *)reg we_tmp1;
reg we_tmp2;
(* MARK_DEBUG="true" *)reg init;
reg [14:0]set_addr_buf_1;
reg [14:0]set_addr_buf_2;
(* MARK_DEBUG="true" *)reg [39:0] data_buf_1;
reg [39:0] data_buf_2;
assign get_addr = i_rec_addr;
always@(posedge clk_200M or negedge rst_200M) begin
  if(!rst_200M)begin

    set_addr_buf_2<='d0;
    set_addr_buf_1<='d0;
    data_buf_2<='d0;
    data_buf_1<='d0;
    ce_tmp1<='d0;
    ce_tmp1<='d0;
    we_tmp1<='d0;
    we_tmp2<='d0;
    init <='d0;
  end else begin
    if(work_enable)begin
      set_addr_buf_1<=i_rec_addr;
      data_buf_1 <= i_rec_d;
      ce_tmp1<=i_rec_ce;
      ce_tmp2<=ce_tmp1;
      set_addr_buf_2<=set_addr_buf_1;
      data_buf_2 <= data_buf_1;
      we_tmp1<=i_rec_we;
      we_tmp2<=we_tmp1;
      if(set_addr_buf_1 == 15'd17999)begin
        init<='d1;
      end
    end
  end
end
(* MARK_DEBUG="true" *)wire [39:0] get_data;
wire [7:0] add1;
wire [7:0] add2;
wire [7:0] add3;
wire [7:0] add4;
wire [7:0] add5;
assign add1 = ((data_buf_1[39-:8]>get_data[39-:8])?(data_buf_1[39-:8]-get_data[39-:8]):(get_data[39-:8]-data_buf_1[39-:8]));
assign add2 = ((data_buf_1[31-:8]>get_data[31-:8])?(data_buf_1[31-:8]-get_data[31-:8]):(get_data[31-:8]-data_buf_1[31-:8]));
assign add3 = ((data_buf_1[23-:8]>get_data[23-:8])?(data_buf_1[23-:8]-get_data[23-:8]):(get_data[23-:8]-data_buf_1[23-:8]));
assign add4 = ((data_buf_1[15-:8]>get_data[15-:8])?(data_buf_1[15-:8]-get_data[15-:8]):(get_data[15-:8]-data_buf_1[15-:8]));
assign add5 = ((data_buf_1[7-:8 ]>get_data[7-:8 ])?(data_buf_1[7-:8 ]-get_data[7-:8 ]):(get_data[7-:8 ]-data_buf_1[7-:8 ]));
wire [8:0] add12;
wire [8:0] add34;
wire [9:0] add1234;
wire [10:0] add12345;
assign add12 = add1 + add2;
assign add34 = add3 + add4;
assign add1234 = add12 + add34;
assign add12345= add1234+add5;
always @(posedge clk_200M or negedge rst_200M) begin
  if(!rst_200M)begin
    sum_traction <= 'd0;
  end else begin
    if(get_addr>17999||get_addr==0)begin
        sum_traction<=24'h0;
    end else if(we_tmp1&ce_tmp1)begin
        sum_traction <= sum_traction + add12345;
    end
       
  end
end
sum_io_empty_ram#(
    .DWIDTH(40),
    .MEM_SIZE(18000)
    ) tmp_val_mem(
  .addr0(get_addr), 
  .ce0(i_rec_ce),   
  .q0(get_data),    
  .addr1(set_addr_buf_2), 
  .ce1(ce_tmp2), 
  .d1(data_buf_2),  
  .we1({5{we_tmp2}}),
  .clk(clk_200M)  
  );
endmodule

// ==============================================================
// Vivado(TM) HLS - High-Level Synthesis from C, C++ and SystemC v2019.2 (64-bit)
// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// ==============================================================
`timescale 1 ns / 1 ps
module sum_io_empty_ram (addr0, ce0, q0, addr1, ce1, d1, we1,  clk);

parameter DWIDTH = 400;
parameter AWIDTH = 15;
parameter MEM_SIZE = 5000;
parameter COL_WIDTH = 8;
parameter NUM_COL = (DWIDTH/COL_WIDTH);

input[AWIDTH-1:0] addr0;
input ce0;
output reg[DWIDTH-1:0] q0;
input[AWIDTH-1:0] addr1;
input ce1;
input[DWIDTH-1:0] d1;
input [NUM_COL-1:0] we1;
input clk;

(* ram_style = "hls_ultra", cascade_height = 1 *)reg [DWIDTH-1:0] ram[0:MEM_SIZE-1];


genvar i;

always @(posedge clk) begin
    if (ce0) begin
        q0 <= ram[addr0];
    end
end


generate
    for (i=0;i<NUM_COL;i=i+1) begin
        always @(posedge clk) begin
            if (ce1) begin
                if (we1[i])
                    ram[addr1][i*COL_WIDTH +: COL_WIDTH] <= d1[i*COL_WIDTH +: COL_WIDTH]; 
            end
        end
    end
endgenerate


endmodule

`timescale 1 ns / 1 ps
module sum_io_empty(
    reset,
    clk,
    address0,
    ce0,
    q0,
    address1,
    ce1,
    we1,
    d1);

parameter DataWidth = 32'd400;
parameter AddressRange = 32'd5000;
parameter AddressWidth = 32'd15;
input reset;
input clk;
input[AddressWidth - 1:0] address0;
input ce0;
output[DataWidth - 1:0] q0;
input[AddressWidth - 1:0] address1;
input ce1;
input[DataWidth/8 - 1:0] we1;
input[DataWidth - 1:0] d1;



sum_io_empty_ram sum_io_empty_ram_U(
    .clk( clk ),
    .addr0( address0 ),
    .ce0( ce0 ),
    .q0( q0 ),
    .addr1( address1 ),
    .ce1( ce1 ),
    .we1( we1 ),
    .d1( d1 ));

endmodule

