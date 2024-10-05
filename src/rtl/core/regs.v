`include "../core/rv32i_defines.v"
module regs(
    input wire clk,
    input wire rst,
    //from ex
    input wire we_i,
    input wire [`RegBus] wdata_i,
    input wire [`RegAddrBus] waddr_i,
    //from jtag
    input wire jtag_we_i,
    input wire [`RegBus] jtag_data_i,
    input wire [`RegAddrBus] jtag_addr_i,
    //to jtag
    output reg [`RegBus] jtag_data_o,
    //to/from ID 
    output reg [`RegBus] rdata1_o,
    output reg [`RegBus] rdata2_o,
    input wire [`RegAddrBus] raddr1_i,
    input wire [`RegAddrBus] raddr2_i
);
reg [`RegBus] regs_mem [0:`RegNum - 1]; //32个寄存器
always@(posedge clk) begin
    if(rst) begin
        //DO NOTHING
    end else begin
        if((we_i == `WriteEnable) && (waddr_i != `ZeroReg)) begin
            regs_mem[waddr_i] <= wdata_i;
        end else if((jtag_we_i == `WriteEnable) && (jtag_addr_i != `ZeroReg)) begin
            regs_mem[waddr_i] <= jtag_data_i;
        end
    end
end
always@(*) begin
    if(raddr1_i == `ZeroReg) begin
        rdata1_o <= `ZeroWord;
    end else if(raddr1_i == waddr_i) begin // 避免先写后读造成数据冲突
        rdata1_o <= wdata_i;
    end else begin
        rdata1_o <= regs_mem[raddr1_i];
    end
end
always@(*) begin
    if(raddr2_i == `ZeroReg) begin
        rdata2_o <= `ZeroWord;
    end else if(raddr2_i == waddr_i) begin // 避免先写后读造成数据冲突
        rdata2_o <= wdata_i;
    end else begin
        rdata2_o <= regs_mem[raddr2_i];
    end
end
always@(*) begin
    if(jtag_addr_i == `ZeroReg) begin
        jtag_data_o <= `ZeroWord;
    end else begin
        jtag_data_o <= regs_mem[jtag_addr_i];
    end
end
endmodule