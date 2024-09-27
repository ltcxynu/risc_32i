`timescale 1ns/1ns
`define SIM 1
`include "simple_ram.v"
`include "4way_4word.v"
`define READ_ENABLE  1'b1
`define READ_DISABLE 1'b0
`define WRITE_ENABLE  1'b1
`define WRITE_DISABLE 1'b0
module tb_cache;
//val

//var
logic clk;  
logic rst;  
logic [24:0] i_p_addr;  
logic [3:0] i_p_byte_en;  
logic [31:0] i_p_writedata;  
logic i_p_read;  
logic i_p_write;  
// Outputs  
logic [31:0] o_p_readdata;  
logic o_p_readdata_valid;  
logic o_p_waitrequest;  
logic [25:0] o_m_addr;  
logic [3:0] o_m_byte_en;  
logic [127:0] o_m_writedata;  
logic o_m_read;  
logic o_m_write;  
logic [127:0] i_m_readdata;  
logic i_m_readdata_valid;  
logic i_m_waitrequest;  
// Counting outputs  
logic [31:0] cnt_r;  
logic [31:0] cnt_w;  
logic [31:0] cnt_hit_r;  
logic [31:0] cnt_hit_w;  
logic [31:0] cnt_wb_r;  
logic [31:0] cnt_wb_w;  
logic [24:0] addr_in;
//instance 
cache #(
    .cache_index(2)
)uut (  
    .clk(clk),  
    .rst(rst),  
    .i_p_addr(i_p_addr),  
    .i_p_byte_en(i_p_byte_en),  
    .i_p_writedata(i_p_writedata),  
    .i_p_read(i_p_read),  
    .i_p_write(i_p_write),  
    .o_p_readdata(o_p_readdata),  
    .o_p_readdata_valid(o_p_readdata_valid),  
    .o_p_waitrequest(o_p_waitrequest),  
    .o_m_addr(o_m_addr),  
    .o_m_byte_en(o_m_byte_en),  
    .o_m_writedata(o_m_writedata),  
    .o_m_read(o_m_read),  
    .o_m_write(o_m_write),  
    .i_m_readdata(i_m_readdata),  
    .i_m_readdata_valid(i_m_readdata_valid),  
    .i_m_waitrequest(i_m_waitrequest),  
    .cnt_r(cnt_r),  
    .cnt_w(cnt_w),  
    .cnt_hit_r(cnt_hit_r),  
    .cnt_hit_w(cnt_hit_w),  
    .cnt_wb_r(cnt_wb_r),  
    .cnt_wb_w(cnt_wb_w)  
);  
//sim body
initial begin  
    clk = 0;  
    forever #5 clk = ~clk; // 100 MHz clock  
end  

initial begin
    rst = 1;
    #100
    rst = 0;
end
logic [24:0] addr_array [$];
integer addr_idx;
initial begin
    addr_idx = 0;
    addr_in = 25'h0;
    //先等待系统初始化
    @(posedge clk);
    if(rst) begin
        @(negedge rst);
        @(posedge clk);
    end
    repeat(1000)
    begin
        //写
        access_memory(addr_in,4'h8,`READ_DISABLE,`WRITE_ENABLE);
        //把这个写的地址添加进读列表
        addr_array.push_front(addr_in);
        //随即从列表里读
        access_memory(addr_array[addr_idx],4'h2,`READ_ENABLE,`WRITE_DISABLE);
        //不从列表里读
        access_memory(addr_array[addr_idx]+8'hff,4'hf,`READ_ENABLE,`WRITE_DISABLE);
        //下一次随机化
        randomize(addr_in)with {addr_in>=0;};
        randomize(addr_idx)with{addr_idx<addr_array.size();};
    end
    $finish;
end
//VIP
integer i;
logic [127:0] mem [0:63];
initial begin
    for(i=0;i<64;i++)begin
        mem[i] = 128'h0;
    end
    forever begin
    @(posedge clk);
    if(o_m_write) begin
        mem[o_m_addr[5:0]] <= o_m_writedata;
        i_m_waitrequest <= 0;
    end
    if(o_m_read) begin
        i_m_readdata <= mem[o_m_addr[5:0]];
        i_m_readdata_valid <= 1;
        i_m_waitrequest <= 0;
    end else begin
        i_m_waitrequest <= 0;
        i_m_readdata_valid <= 0;
    end
    end
end
initial begin
    $dumpfile("this.vcd");
    $dumpvars(0, uut);
end
//function

//task
task access_memory (  
        input logic [23:0] address,     // 24 位地址  
        input logic [3:0] mask,         // 4 位掩码  
        input logic read_enable,         // 读信号  
        input logic write_enable         // 写信号  
    );  
    @(posedge clk);
    if(rst) begin
        @(negedge rst);
        @(posedge clk);
    end
    if(o_p_waitrequest) begin
        @(negedge o_p_waitrequest);
        @(posedge clk);
    end
    i_p_addr        <= address;
    i_p_byte_en     <= mask;
    if(write_enable) begin
        i_p_writedata   <= $urandom_range(32'hffff_ffff,32'h0);
    end else begin
        i_p_writedata   <= i_p_writedata;
    end
    i_p_read        <= read_enable;
    i_p_write       <= write_enable;
endtask  


endmodule