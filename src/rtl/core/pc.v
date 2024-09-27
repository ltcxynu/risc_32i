module pc(
    input wire clk,
    input wire rst,
    //from ex->ctrl->this
    input wire jump_flag_i,
    input wire[`InstAddrBus] jump_addr_i,
    //from ctrl
    input wire [`Hold_Flag_Bus] hold_flag_i,
    //to id, risc interconncet bus
    output reg [`InstAddrBus] pc_o,
    //from jtag
    input wire jtag_reset_flag_i,
    // to mem
    output reg[`MemBus] mem_wdata_o,        // 写内存数据
    output reg[`MemAddrBus] mem_raddr_o,    // 读内存地址
    output reg[`MemAddrBus] mem_waddr_o,    // 写内存地址
    output reg mem_we_o,                   // 是否要写内存
    output reg mem_req_o,                  // 请求访问内存标志
    // from mem
    input wire[`MemBus] mem_rdata_i        // 内存输入数据

);
always@(*) begin
    mem_wdata_o <= `ZeroWord;
    mem_waddr_o <= `ZeroWord;
    mem_we_o    <= `WRITE_DISABLE;
end
always@(posedge clk) begin
    if(rst|jtag_reset_flag_i) begin
        pc_o <= `ZeroWord;
    end else if(jump_flag_i) begin
        pc_o <= jump_addr_i;
    end else if(hold_flag_i > `Hold_Pc) begin
        pc_o <= pc_o;
    end else begin
        pc_o <= pc_o + 32'd4;
    end
end
//总线其实挂的东西没那么多，需要访问外部存储的也只有if，am,wb三个阶段，其中am，wb较靠后，也无所谓了。
always@(*) begin
    mem_raddr_o <= pc_o;
    mem_req_o   <= `
end

endmodule