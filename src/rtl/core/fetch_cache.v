module fetch_cache(
    input   wire                    clk,
    input   wire                    rst,
    //from ex->ctrl->this
    input   wire                    jump_flag_i,
    input   wire[`InstAddrBus]      jump_addr_i,
    //from jtag
    input   wire                    jtag_reset_flag_i,
    // to mem
    output  reg  [`CacheAddrBus]    o_p_addr,                //cpu->cache addr
    output  wire [`CacheByteBus]    o_p_byte_en,             //写稀疏掩码
    output  wire [`CacheDataBus]    o_p_writedata,           //写数据
    output  reg                     o_p_read,                //读使能
    output  wire                    o_p_write,               //写使能
    input   wire [`CacheDataBus]    i_p_readdata,            //读数据
    input   wire                    i_p_readdata_valid,      //读数据有效
    input   wire                    i_p_waitrequest,         //操作等待
    input   wire                    flush,
    //inst fifo
    input   wire                    inst_fifo_full,
    output  reg  [`InstBus]         inst_fifo_r,
    output  reg                     inst_fifo_wen,
    output  reg                     inst_fifo_rstn,

    //addr fifo
    input  wire [`InstAddrBus]      addr_fifo_r,
    input  wire                     addr_fifo_empty,
    output reg                      addr_fifo_ren

);
reg  [1:0] jump_regs;
wire jump_posedge = jump_flag_i & jump_regs[1];
wire jump_negedge = jump_regs == 2'b10;
always @(posedge clk ) begin
    if(rst|jtag_reset_flag_i) begin
        jump_regs <= 2'b00;
    end else begin
        jump_regs <= {jump_regs[0],jump_flag_i};
    end
end

//关闭写通道
assign o_p_write = `WriteDisable;
assign o_p_byte_en = 4'h0;
assign o_p_writedata = `ZeroWord;
//每次发出一个请求(地址) 到cache
always @(*) begin
    if( ~addr_fifo_empty && ~inst_fifo_full && ~i_p_waitrequest && ~jump_flag_i && ~flush) begin
        o_p_addr <= {4'b0,addr_fifo_r[22:2]};
        o_p_read <= 1;
        addr_fifo_ren      <= 1;
    end else begin
        o_p_addr <= {4'b0,addr_fifo_r[22:2]};
        o_p_read <= 0;
        addr_fifo_ren      <= 0;
    end
end
reg jmp_under_reslove;
always @(posedge clk) begin
    if(jump_flag_i | rst) begin
        inst_fifo_r <= `INST_NOP;
        inst_fifo_wen    <= 0;
        inst_fifo_rstn <= 0;
        if(i_p_waitrequest) begin
            jmp_under_reslove <= 1;
        end else begin
            jmp_under_reslove <= 0;
        end
    end else if(i_p_readdata_valid) begin
        if(jmp_under_reslove) begin
            jmp_under_reslove <= 0;
            inst_fifo_r <= i_p_readdata;
            inst_fifo_wen    <= 0;
            inst_fifo_rstn <= 1;
        end else begin
            inst_fifo_r <= i_p_readdata;
            inst_fifo_wen    <= 1;
            inst_fifo_rstn <= 1;
        end
    end else begin
        inst_fifo_r <= i_p_readdata;
        inst_fifo_wen    <= 0;
        inst_fifo_rstn <= 1;
    end
end
endmodule