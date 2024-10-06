module wb(
    input wire [`CacheDataBus] i_p_readdata, 
    input wire                 i_p_readdata_valid,
    input wire                 i_p_waitrequest,
    input wire [`RegAddrBus]   reg_wait_wb,
    output reg [`RegAddrBus]   reg_waddr_o,
    output reg [`RegBus]       reg_wdata_o,
    output reg [`RegAddrBus]   reg_we_o,
    output reg                 wb_done
);
//处理从mem读数据的读取结束阶段
    always@(*) begin
        if(~i_p_waitrequest & i_p_readdata_valid) begin
            reg_we_o    <= `WriteEnable;
            reg_wdata_o <= i_p_readdata;
            reg_waddr_o <= reg_wait_wb;
            wb_done     <= 1;
        end else begin
            reg_we_o    <= `WriteDisable;
            reg_wdata_o <= `ZeroWord;
            reg_waddr_o <= `ZeroReg;
            wb_done     <= 0;
        end
    end
endmodule