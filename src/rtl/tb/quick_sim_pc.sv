`timescale 1ns/1ns
`define SIM 1
`include "../core/rv32i_defines.v"
`include "../core/pc.v"
`include "../core/if_id.v"
`include "../cache/simple_ram.v"
`include "../cache/4way_4word.v"

module quick_sim_pc;

localparam JMPADDR = 32'h0000_0010; 


logic clk,rst,jump_flag_i,jtag_reset_flag_i;
logic [`InstAddrBus] jump_addr_i;
logic  [`InstAddrBus] pc_o;
logic [`Hold_Flag_Bus] hold_flag_i;
logic [`CacheAddrBus]o_p_addr          ;
logic [`CacheByteBus]o_p_byte_en       ;
logic [`CacheDataBus]o_p_writedata     ;
logic o_p_read          ;
logic o_p_write         ;
logic [`CacheDataBus]i_p_readdata      ;
logic i_p_readdata_valid;
logic i_p_waitrequest   ;
logic [`InstAddrBus] inst_addr_o;
logic [`InstBus] inst_o;
logic [`InstAddrBus] if_id_inst_addr_o;
logic [`InstBus] if_id_inst_o;
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
logic inst_valid;
if_id uut_ifid(
    .clk            (clk   ),
    .rst            (rst   ),
    .inst_i         (inst_o    ),
    .inst_addr_i    (inst_addr_o   ),
    .inst_valid_i   (inst_valid  ),
    .hold_flag_i    (hold_flag_i   ),
    .int_flag_i     (    ),
    .int_flag_o     (    ),
    .inst_o         (if_id_inst_o    ),
    .inst_addr_o    (if_id_inst_addr_o   ) 
);
pc uut(
    .clk                (clk),
    .rst                (rst),
    .jump_flag_i        (jump_flag_i),
    .jump_addr_i        (jump_addr_i),
    .hold_flag_i        (hold_flag_i),
    .inst_addr_o        (inst_addr_o),
    .inst_o             (inst_o)     ,
    .inst_valid         (inst_valid),
    .jtag_reset_flag_i  (jtag_reset_flag_i),
    .o_p_addr           (o_p_addr),                //cpu->cache addr
    .o_p_byte_en        (o_p_byte_en),             //写稀疏掩码
    .o_p_writedata      (o_p_writedata),           //写数据
    .o_p_read           (o_p_read),                //读使能
    .o_p_write          (o_p_write),               //写使能
    .i_p_readdata       (i_p_readdata),            //读数据
    .i_p_readdata_valid (i_p_readdata_valid),      //读数据有效
    .i_p_waitrequest    (i_p_waitrequest)          //操作等待
);

//instance 
cache #(
    .cache_index(2)
)uut_cache (  
    .clk(clk),  
    .rst(rst),  
    .i_p_addr(o_p_addr),  
    .i_p_byte_en(o_p_byte_en),  
    .i_p_writedata(o_p_writedata),  
    .i_p_read(o_p_read),  
    .i_p_write(o_p_write),  
    .o_p_readdata(i_p_readdata),  
    .o_p_readdata_valid(i_p_readdata_valid),  
    .o_p_waitrequest(i_p_waitrequest),  
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

initial begin
{rst,jtag_reset_flag_i} <= 2'b11;
jump_flag_i <= 0;
hold_flag_i <= `Hold_None;
#10 {rst,jtag_reset_flag_i} <= 2'b10;
#10 {rst,jtag_reset_flag_i} <= 2'b01;
#10 {rst,jtag_reset_flag_i} <= 2'b00;
#130
    @(posedge clk);
    @(posedge clk);
    jump_flag_i <= 1;
    jump_addr_i <= JMPADDR;
    hold_flag_i <= `Hold_Id;
    @(posedge clk);
    jump_flag_i <= 0;
    hold_flag_i <= `Hold_None;
#1000
#200
#1000
$finish;    
end

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
//VIP
integer i;
logic [127:0] mem [`RomNum];
initial begin
    $readmemh ("inst128.data", mem);
    forever begin
    @(posedge clk);
    if(o_m_write) begin
        mem[o_m_addr[8:2]] <= o_m_writedata;
        i_m_waitrequest <= 0;
    end
    if(o_m_read) begin
        i_m_readdata <= mem[o_m_addr[9:3]];
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
    $dumpvars(0, quick_sim_pc);
end

endmodule