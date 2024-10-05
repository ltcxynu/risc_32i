`timescale 1ns/1ns
`define SIM 1
`include "../core/rv32i_defines.v"
`include "../core/pc.v"
`include "../core/id.v"
`include "../core/if_id.v"
`include "../core/id_ex.v"
`include "../core/regs.v"
`include "../core/csr_reg.v"
`include "../core/ex.v"
`include "../cache/simple_ram.v"
`include "../cache/4way_4word.v"

module quick_sim_pc;

localparam JMPADDR = 32'h0000_0010; 


logic   clk,
        rst,
        jump_flag_i,
        jtag_reset_flag_i,
        ex_jump_flag_o;
logic [`InstAddrBus]    jump_addr_i,
                        ex_jump_addr_o;
logic [`Hold_Flag_Bus] hold_flag_i;
//Cache
logic [`CacheAddrBus]o_p_addr          ;
logic [`CacheByteBus]o_p_byte_en       ;
logic [`CacheDataBus]o_p_writedata     ;
logic o_p_read          ;
logic o_p_write         ;
logic [`CacheDataBus]i_p_readdata      ;
logic i_p_readdata_valid;
logic i_p_waitrequest   ;
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
//rv32i
logic [`InstAddrBus]inst_addr_o,
                    if_id_inst_addr_o,
                    id_inst_addr_o,
                    id_ex_inst_addr_o;
logic [`InstBus]    inst_o,
                    if_id_inst_o,
                    id_inst_o,
                    id_ex_inst_o;
logic inst_valid;
logic [`RegBus]     reg1_rdata_i,
                    reg1_rdata_o,
                    reg2_rdata_i,
                    reg2_rdata_o,
                    csr_rdata_o,
                    csr_rdata_i,
                    id_ex_reg1_rdata_o,
                    id_ex_reg2_rdata_o,
                    id_ex_csr_rdata_o,
                    ex_reg_wdata_o,
                    ex_csr_wdata_o
                    ;
logic [`RegBus]     op1_o,
                    op2_o,
                    op1_jump_o,
                    op2_jump_o,
                    id_ex_op1_o,
                    id_ex_op2_o,
                    id_ex_op1_jump_o,
                    id_ex_op2_jump_o
                    ;
logic [`RegAddrBus] reg1_raddr_o,
                    reg2_raddr_o,
                    csr_raddr_o,
                    ex_reg_waddr_o,
                    ex_csr_waddr_o;
logic               ex_reg_we_o,
                    ex_csr_we_o;
regs regs_uut(
    .clk            (clk),
    .rst            (rst),
    .we_i           (ex_reg_we_o),
    .wdata_i        (ex_reg_wdata_o),
    .waddr_i        (ex_reg_waddr_o),
    .jtag_we_i      (),
    .jtag_data_i    (),
    .jtag_addr_i    (),
    .jtag_data_o    (),
    .rdata1_o       (reg1_rdata_i),
    .rdata2_o       (reg2_rdata_i),
    .raddr1_i       (reg1_raddr_o),
    .raddr2_i       (reg2_raddr_o) 
);
csr_reg csr_reg_uut(
    .clk              (clk),
    .rst              (rst),
    .we_i             (ex_csr_we_o),
    .raddr_i          (csr_raddr_o),
    .waddr_i          (ex_csr_waddr_o),
    .data_i           (ex_csr_wdata_o),
    .data_o           (csr_rdata_i),
    .clint_we_i       (),
    .clint_raddr_i    (),
    .clint_waddr_i    (),
    .clint_data_i     (),
    .clint_data_o     (),
    .clint_csr_mtvec  (),
    .clint_csr_mepc   (),
    .clint_csr_mstatus(),
    .global_int_en_o  ()     
);
ex ex_uut(
    .op1_i          (id_ex_op1_o),
    .op2_i          (id_ex_op2_o),
    .op1_jump_i     (id_ex_op1_jump_o),
    .op2_jump_i     (id_ex_op2_jump_o),
    .inst_i         (id_ex_inst_o),
    .inst_addr_i    (id_ex_inst_addr_o),
    .reg1_rdata_i   (id_ex_reg1_rdata_o),
    .reg2_rdata_i   (id_ex_reg2_rdata_o),
    .csr_rdata_i    (id_ex_csr_rdata_o),
    .reg_wdata_o    (ex_reg_wdata_o),
    .reg_we_o       (ex_reg_we_o),
    .reg_waddr_o    (ex_reg_waddr_o),
    .csr_wdata_o    (ex_csr_wdata_o),
    .csr_we_o       (ex_csr_we_o),
    .csr_waddr_o    (ex_csr_waddr_o),
    .jump_flag_o    (ex_jump_flag_o),
    .jump_addr_o    (ex_jump_addr_o) 
);
id_ex id_ex_uut(
.clk                (clk   ),
.rst                (rst   ),
// from id
.op1_i              (op1_o),
.op2_i              (op2_o),
.op1_jump_i         (op1_jump_o),
.op2_jump_i         (op2_jump_o),
.inst_i             (id_inst_o),
.inst_addr_i        (id_inst_addr_o),
.reg1_rdata_i       (reg1_rdata_o),
.reg2_rdata_i       (reg2_rdata_o),
.csr_rdata_i        (csr_rdata_o),
.op1_o              (id_ex_op1_o),
.op2_o              (id_ex_op2_o),
.op1_jump_o         (id_ex_op1_jump_o),
.op2_jump_o         (id_ex_op2_jump_o),
.inst_o             (id_ex_inst_o),
.inst_addr_o        (id_ex_inst_addr_o),
.reg1_rdata_o       (id_ex_reg1_rdata_o),
.reg2_rdata_o       (id_ex_reg2_rdata_o),
.csr_rdata_o        (id_ex_csr_rdata_o),
.hold_flag_i        (hold_flag_i) 
);
id uut_id(
    .rst(rst),

    .inst_i(if_id_inst_o),
    .inst_addr_i(if_id_inst_addr_o),

    .reg1_rdata_i(reg1_rdata_i),
    .reg2_rdata_i(reg2_rdata_i),

    .csr_rdata_i(csr_rdata_i),

    .reg1_raddr_o(reg1_raddr_o),
    .reg2_raddr_o(reg2_raddr_o),

    .csr_raddr_o(csr_raddr_o),

    .op1_o(op1_o),
    .op2_o(op2_o),
    .op1_jump_o(op1_jump_o),
    .op2_jump_o(op2_jump_o),
    .inst_o(id_inst_o),
    .inst_addr_o(id_inst_addr_o),
    .reg1_rdata_o(reg1_rdata_o),
    .reg2_rdata_o(reg2_rdata_o),
    .csr_rdata_o(csr_rdata_o)
);
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
    .jump_flag_i        (jump_flag_i),//这三个暂时用的虚拟的，后续要接入真实的
    .jump_addr_i        (jump_addr_i),//这三个暂时用的虚拟的，后续要接入真实的
    .hold_flag_i        (hold_flag_i),//这三个暂时用的虚拟的，后续要接入真实的
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