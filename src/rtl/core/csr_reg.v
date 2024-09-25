module csr_reg(
    input wire clk,
    input wire rst,
    //from ex
    input wire we_i,
    input wire [`RegAddrBus] raddr_i,
    input wire [`RegAddrBus] waddr_i,
    input wire [`RegBus] data_i,
    //to ex
    output reg [`RegBus] data_o,
    //from clint
    input wire clint_we_i,
    input wire [`RegAddrBus] clint_raddr_i,
    input wire [`RegAddrBus] clint_waddr_i,
    input wire [`RegBus] clint_data_i,
    //to clint
    output reg [`RegBus] clint_data_o,
    //external clint out
    output wire [`RegBus] clint_csr_mtvec, //中断入口地址
    output wire [`RegBus] clint_csr_mepc, //中断恢复地址
    output wire [`RegBus] clint_csr_mstatus, //记录系统信息
    //global int en
    output wire global_int_en_o
);
reg [`DoubleRegBus] cycle; //定时器
reg [`RegBus] mtvec;
reg [`RegBus] mcause;//记录中断原因
reg [`RegBus] mepc;
reg [`RegBus] mie;
reg [`RegBus] mstatus;
reg [`RegBus] mscratch;

assign global_int_en_o = (mstatus[3]==1'b1)?`True:`False;
assign clint_csr_mstatus = mstatus;
assign clint_csr_mepc = mepc;
assign clint_csr_mtvec = mtvec;

always@(posedge clk) begin
    if(rst = `RstEnable) begin
        cycle <= {`ZeroWord,`ZeroWord};
    end else begin
        cycle <= cycle + 1'b1;
    end
end
always@(posedge clk) begin
    if(rst == `RstEnable) begin
        mtvec <= `ZeroWord;
        mcause <= `ZeroWord;
        mepc <= `ZeroWord;
        mscratch <= `ZeroWord;
        mie <= `ZeroWord;
        mstatus <= `ZeroWord;
    end else begin
        if(we_i == `WriteEnable) begin
            case(waddr_i[11:0])
                `CSR_MTVEC:begin
                    mtvec <= wdata_i;
                end
                `CSR_MCAUSE:begin
                    mcause <= wdata_i;
                end
                `CSR_MEPC:begin
                    mepc <= wdata_i;
                end
                `CSR_MIE:begin
                    mie <= wdata_i;
                end
                `CSR_MSTATUS:begin
                    mstatus <= wdata_i;
                end      
                `CSR_MSCRATCH:begin
                    mscratch <= wdata_i;
                end             
            endcase
        end else if(clint_we_i) begin
            case(clint_waddr_i[11:0])
                `CSR_MTVEC:begin
                    mtvec <= clint_data_i;
                end
                `CSR_MCAUSE:begin
                    mcause <= clint_data_i;
                end
                `CSR_MEPC:begin
                    mepc <= clint_data_i;
                end
                `CSR_MIE:begin
                    mie <= clint_data_i;
                end
                `CSR_MSTATUS:begin
                    mstatus <= clint_data_i;
                end      
                `CSR_MSCRATCH:begin
                    mscratch <= clint_data_i;
                end             
            endcase
        end
    end
end

always@(*) begin
    if((waddr_i[11:0] == raddr_i[11:0]) && (we_i == `WriteEnable)) begin
        data_o <= data_i;
    end else begin
        case(raddr_i[11:0])
        `CSR_CYCLE: begin
            data_o = cycle[31:0];
        end
        `CSR_CYCLEH: begin
            data_o = cycle[63:32];
        end
        `CSR_MTVEC: begin
            data_o = mtvec;
        end
        `CSR_MCAUSE: begin
            data_o = mcause;
        end
        `CSR_MIE: begin
            data_o = mie;
        end
        `CSR_MEPC: begin
            data_o = mepc;
        end
        `CSR_MSCRATCH: begin
            data_o = mscratch;
        end
        `CSR_MSTATUS: begin
            data_o = mstatus;
        end
        endcase
    end
end

always@(*) begin
    if((clint_waddr_i[11:0] == clint_raddr_i[11:0]) && (clint_we_i == `WriteEnable)) begin
        clint_data_o <= clint_data_i;
    end else begin
        case(clint_raddr_i[11:0])
        `CSR_CYCLE: begin
            clint_data_o = cycle[31:0];
        end
        `CSR_CYCLEH: begin
            clint_data_o = cycle[63:32];
        end
        `CSR_MTVEC: begin
            clint_data_o = mtvec;
        end
        `CSR_MCAUSE: begin
            clint_data_o = mcause;
        end
        `CSR_MIE: begin
            clint_data_o = mie;
        end
        `CSR_MEPC: begin
            clint_data_o = mepc;
        end
        `CSR_MSCRATCH: begin
            clint_data_o = mscratch;
        end
        `CSR_MSTATUS: begin
            clint_data_o = mstatus;
        end
        endcase
    end
end
endmodule