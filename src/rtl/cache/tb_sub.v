`timescale 1ns/1ns
`define SIM 1
`include "sub.v"
module tb_sub();
//时钟
logic clk,rst;
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

//data
logic  [14:0]addr; // i read addr
logic  ce;   
logic  we;
wire  [39:0]d;
logic  [7:0] di;
logic  [7:0] di2;
wire  [25:0] sum_traction;
logic  refresh;
assign d = {di,di,di,di,di};
initial begin
    rst = 0;
    #100
    rst = 1;
end
initial begin
    addr = 15'd0;
    ce = 0;
    we = 0;
    di = 8'd0;
    di2 = 8'd255;
    refresh = 0;
    repeat(4) begin
        @(posedge clk);
        if(~rst) begin
            @(posedge rst);
            @(posedge clk);
        end
        addr <= 15'd0;
        ce   <= 1;
        we   <= 1;
        refresh <= 0;
        di <= di2;
        di2 <= di;
        repeat(19000) begin
            @(posedge clk);
            if(~rst) begin
                @(posedge rst);
                @(posedge clk);
            end
            addr <= addr + 'd1;
            ce   <= 1;
            we   <= 1;
            if(addr == 18000) begin
                refresh <= 1;
                $display("sub is %d",sum_traction); 
            // end else if(addr == 18000)begin
            end else begin
                refresh <= 0;
            end
        end
    end
    $finish();
end

proc_subtraction ps(
.clk_200M       (clk),
.rst_200M       (rst),
.i_rec_addr     (addr),
.i_rec_ce       (ce), 
.i_rec_we       (we),
.i_rec_d        (d),
.sum_traction   (sum_traction),
.refresh        (refresh)
);
initial begin
    $dumpfile("sub.vcd");
    $dumpvars(0, ps);
end
// `ifdef SIM
// integer i;
//   for(i = 0; i < 5000; i=i+1)begin
//     ps.tmp_val_mem.ram <= 'd0;
//   end
// `endif
endmodule
