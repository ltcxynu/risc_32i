
module regs(
    input wire clk,
    input wire rst,
    //from ex
    input wire we_i,
    input wire[`RegAddrBus] waddr_i,
    input wire[`RegBus] wdata_i,
    //from/to jtag
    input wire jtag_we_i,
    input wire[`RegAddrBus] jtag_addr_i,
    input wire[`RegBus] jtag_data_i,
    output reg[`RegBus] jtag_data_o,

    //from id
    input wire[`RegAddrBus] raddr1_i,
    input wire[`RegAddrBus] raddr2_i,
    output reg[`RegBus]     rdata1_o,
    output reg[`RegBus]     rdata2_o
);
reg[`RegBus] regs[0:`RegNum - 1];
//上升沿写入，优先服务ex
always @(posedge clk) begin
    if(rst == `RstDisable) begin
        if((we_i == `WriteEnable) && (waddr_i != `ZeroReg))begin
            regs[waddr_i] <= wdata_i;
        end else if((jtag_we_i == `WriteEnable) && (waddr_i != `ZeroReg))begin
            regs[jtag_addr_i] <= jtag_data_i;
        end
    end
end
//组合逻辑读出电路
always @(*) begin
    if(raddr1_i == `ZeroReg) begin
        rdata1_o = `ZeroWord;
    end else if((raddr1_i == waddr_i) && (we_i == `WriteEnable)) begin
        rdata1_o = wdata_i;       
    end else begin
        rdata1_o = regs[raddr1_i];
    end
end
always @(*) begin
    if(raddr2_i == `ZeroReg) begin
        rdata2_o = `ZeroWord;
    end else if((raddr2_i == waddr_i) && (we_i == `WriteEnable)) begin
        rdata2_o = wdata_i;       
    end else begin
        rdata2_o = regs[raddr2_i];
    end
end
//jtag读出电路
always @(*) begin
    if(jtag_addr_i == `ZeroReg) begin
        jtag_data_o = `ZeroWord;
    end else begin
        jtag_data_o = regs[jtag_addr_i];
    end
end
endmodule