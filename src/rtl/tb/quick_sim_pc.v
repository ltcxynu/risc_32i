`timescale 1ns/1ns
`include "../core/rv32i_defines.v"
`include "../core/pc.v"
module quick_sim_pc;
reg clk,rst,jump_flag_i,jtag_reset_flag_i;
reg [`InstAddrBus] jump_addr_i;
wire [`InstAddrBus] pc_o;
reg [`Hold_Flag_Bus] hold_flag_i;
localparam JMPADDR = 32'hfefeabab; 
pc u_pc(
    .clk               (clk               ),
    .rst               (rst               ),
    .jump_flag_i       (jump_flag_i       ),
    .jump_addr_i       (jump_addr_i       ),
    .hold_flag_i       (hold_flag_i       ),
    .pc_o              (pc_o              ),
    .jtag_reset_flag_i (jtag_reset_flag_i )
);

initial begin
  clk = 0;
  repeat(100) #5 clk = ~clk;
end

initial begin
{rst,jtag_reset_flag_i} <= 2'b11;
jump_flag_i <= 0;
hold_flag_i <= `Hold_None;
#10 {rst,jtag_reset_flag_i} <= 2'b10;
#10 {rst,jtag_reset_flag_i} <= 2'b01;
#10 {rst,jtag_reset_flag_i} <= 2'b00;
#100
    jump_flag_i <= 1;
    jump_addr_i <= JMPADDR;
    @(posedge clk);
    jump_flag_i <= 0;

#100 jump_flag_i <= 0;
#100 
    hold_flag_i <= `Hold_Id;
#20
    hold_flag_i <= `Hold_None;
end

initial begin
    $dumpfile("quick_sim_pc.vcd");
    $dumpvars(0, quick_sim_pc);
end

endmodule