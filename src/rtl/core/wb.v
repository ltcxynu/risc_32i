module wb(
    input wire                 clk,
    input wire                 rst,
    input wire                 ex_read_mem,
    input wire [`CacheDataBus] i_p_readdata, 
    input wire                 i_p_readdata_valid,
    input wire                 i_p_waitrequest,
    input wire [`RegAddrBus]   reg_wait_wb,
    input wire [1:0]           mask_wait_wb,
    input wire [2:0]           ifunct3_wait_wb,
    output reg [`RegAddrBus]   reg_waddr_o,
    output reg [`RegBus]       reg_wdata_o,
    output reg [`RegAddrBus]   reg_we_o,
    output reg                 wb_done
);
reg [`RegAddrBus]   reg_wait_wb_pp1;
reg [1:0]           mask_wait_wb_pp1;
reg [2:0]           ifunct3_wait_wb_pp1;
    always@(posedge clk) begin
        if(rst) begin
            reg_wait_wb_pp1     <= `ZeroReg;
            mask_wait_wb_pp1    <= 2'b00;
            ifunct3_wait_wb_pp1 <= 3'b000;
        end else if(ex_read_mem)begin
            reg_wait_wb_pp1     <= reg_wait_wb;
            mask_wait_wb_pp1    <= mask_wait_wb;
            ifunct3_wait_wb_pp1 <= ifunct3_wait_wb;
        end
    end
//处理从mem读数据的读取结束阶段
    always@(*) begin
        if(~i_p_waitrequest & i_p_readdata_valid) begin
            reg_we_o    <= `WriteEnable;
            reg_waddr_o <= reg_wait_wb_pp1;
            wb_done     <= 1;
        case(ifunct3_wait_wb_pp1)
            `INST_LB :begin
                case (mask_wait_wb_pp1)
                    2'b00:  reg_wdata_o <= {{24{i_p_readdata[ 7]}},i_p_readdata[ 7: 0]};
                    2'b01:  reg_wdata_o <= {{24{i_p_readdata[15]}},i_p_readdata[15: 8]};
                    2'b10:  reg_wdata_o <= {{24{i_p_readdata[23]}},i_p_readdata[23:16]};
                    2'b11:  reg_wdata_o <= {{24{i_p_readdata[31]}},i_p_readdata[31:24]};
                endcase
            end
            `INST_LH :begin
                case (mask_wait_wb_pp1)
                    2'b00:  reg_wdata_o <= {{16{i_p_readdata[ 15]}},i_p_readdata[15: 0]};
                    default:reg_wdata_o <= {{16{i_p_readdata[ 31]}},i_p_readdata[31:16]};
                endcase
            end
            `INST_LW :begin
                reg_wdata_o <= i_p_readdata;
            end
            `INST_LBU:begin
                case (mask_wait_wb_pp1)
                    2'b00:  reg_wdata_o <= {{24{1'b0}},i_p_readdata[ 7: 0]};
                    2'b01:  reg_wdata_o <= {{24{1'b0}},i_p_readdata[15: 8]};
                    2'b10:  reg_wdata_o <= {{24{1'b0}},i_p_readdata[23:16]};
                    2'b11:  reg_wdata_o <= {{24{1'b0}},i_p_readdata[31:24]};
                endcase
            end
            `INST_LHU:begin
                case (mask_wait_wb_pp1)
                    2'b00:  reg_wdata_o <= {{16{1'b0}},i_p_readdata[15: 0]};
                    default:reg_wdata_o <= {{16{1'b0}},i_p_readdata[31:16]};
                endcase
            end
        endcase
        end else if(i_p_waitrequest)begin
            reg_we_o    <= `WriteDisable;
            reg_wdata_o <= `ZeroWord;
            reg_waddr_o <= `ZeroReg;
            wb_done     <= 0;
        end else begin
            reg_we_o    <= `WriteDisable;
            reg_wdata_o <= `ZeroWord;
            reg_waddr_o <= `ZeroReg;
            wb_done     <= 1;
        end
    end
endmodule