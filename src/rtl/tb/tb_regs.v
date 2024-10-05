`timescale 1ns/1ns
`include "../core/regs.v"
module tb_regs;
logic clk,rst,ex_reg_we_o;
logic [31:0]ex_reg_wdata_o,
            reg1_rdata_i,
            reg2_rdata_i;
logic [4:0] ex_reg_waddr_o,
            reg1_raddr_o,
            reg2_raddr_o;
regs regs_uut(
    .clk            (clk),
    .rst            (rst),
    .we_i           (ex_reg_we_o),
    .wdata_i        (ex_reg_wdata_o),
    .waddr_i        (ex_reg_waddr_o),
    .rdata1_o       (),
    .rdata2_o       (),
    .raddr1_i       (reg1_raddr_o),
    .raddr2_i       (reg2_raddr_o) 
);
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end
initial begin
    rst = 1;
    #100
    rst = 0;
    #10
    @(posedge clk);
    ex_reg_we_o = 1;
    ex_reg_wdata_o = 32'h0fff1000;
    ex_reg_waddr_o = 5'd1;
    @(posedge clk);
    ex_reg_we_o = 0;
    ex_reg_wdata_o = 32'h0;
    ex_reg_waddr_o = 5'd0;
    reg1_raddr_o = 5'd1;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    $finish;
end
initial begin
    $dumpfile("this.vcd");
    $dumpvars(0, tb_regs);
end

endmodule