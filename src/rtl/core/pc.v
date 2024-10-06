module pc(
    input   wire                    clk,
    input   wire                    rst,
    //from ex->ctrl->this
    input   wire                    jump_flag_i,
    input   wire[`InstAddrBus]      jump_addr_i,
    //from ctrl
    input   wire [`Hold_Flag_Bus]   hold_flag_i,
    //to id, risc interconncet bus
    output  reg [`InstAddrBus]      inst_addr_o,
    output  reg [`InstBus]          inst_o,
    output  reg                     inst_valid_o,
    //from jtag
    input   wire                    jtag_reset_flag_i,
    // to mem
    output  wire [`CacheAddrBus]    o_p_addr,                //cpu->cache addr
    output  wire [`CacheByteBus]    o_p_byte_en,             //写稀疏掩码
    output  wire [`CacheDataBus]    o_p_writedata,           //写数据
    output  wire                    o_p_read,                //读使能
    output  wire                    o_p_write,               //写使能
    input   wire [`CacheDataBus]    i_p_readdata,            //读数据
    input   wire                    i_p_readdata_valid,      //读数据有效
    input   wire                    i_p_waitrequest          //操作等待
);
reg [`InstAddrBus] pc,pc_n;
reg jmp_under_reslove;
//关闭写通道
assign o_p_write = `WriteDisable;
assign o_p_byte_en = 4'h0;
assign o_p_writedata = `ZeroWord;
//读
always@(*) begin
    if((~o_p_read && (hold_flag_i < `Hold_Pc))) begin
        //如果没读，而且没hold。
        pc_n = pc;
    end else if(jump_flag_i) begin
        pc_n = jump_addr_i;
    end else if(i_p_waitrequest | jmp_under_reslove) begin
        pc_n = pc;
    end else if(i_p_readdata_valid)begin
        pc_n = pc + 32'd1;
    end
end
assign o_p_read  = (rst|jtag_reset_flag_i) ? `ReadDisable : ~i_p_waitrequest;
assign o_p_addr  = {2'b00,pc_n[22:0]};

always@(posedge clk) begin
    if(rst|jtag_reset_flag_i) begin
        pc          <= `ZeroWord;
    end else if(jump_flag_i) begin
        pc          <= jump_addr_i;
    end else if((hold_flag_i >= `Hold_Pc)  || (i_p_waitrequest) ) begin
        pc <= pc;
    end else if( i_p_readdata_valid )begin // 
        pc <= pc_n;
    end
end
//访问icahce
always@(posedge clk) begin
    if(rst|jtag_reset_flag_i) begin
        inst_addr_o <= `ZeroReg;
        inst_o  <= `ZeroWord;
        inst_valid_o <= 0;
        jmp_under_reslove <= 0;
    end else if(jump_flag_i) begin
        inst_addr_o <= `ZeroReg;
        inst_o  <= `ZeroWord;
        inst_valid_o <= 0;
        if(i_p_waitrequest) begin
            jmp_under_reslove <= 1;
        end else begin
            jmp_under_reslove <= 0;
        end
    end else if(i_p_readdata_valid) begin
        if(~jmp_under_reslove) begin
            inst_o <= i_p_readdata;
            inst_addr_o <= pc;
            inst_valid_o <= 1;
        end else begin
            inst_addr_o <= `ZeroReg;
            inst_o  <= `ZeroWord;
            inst_valid_o <= 0;
            jmp_under_reslove <= 0;
        end
    end else begin
        inst_addr_o <= `ZeroReg;
        inst_o  <= `ZeroWord;
        inst_valid_o <= 0;
    end
end
endmodule