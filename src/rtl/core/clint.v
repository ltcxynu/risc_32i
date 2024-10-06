
/*RISCV 不支持中断嵌套，即中断触发之后会将 mstatus 的 mie 位置 0

中断处理的第一条指令地址存储在 mtvec 中，mie 寄存器（不是mstatus 寄存器中的mie位）控制哪些中断可以被触发，只有对应位置置一的中断号的中断会触发。

中断处理完成之后需要返回，从机器模式的中断返回需要调用 mret 指令，它会 将 PC 设置为 mepc，通过将 mstatus 的 MPIE 域复制到MIE 来恢复之前的中断使能设置，并将权限模式设置为 mstatus 的 MPP 域中的值。
https://www.cnblogs.com/mikewolf2002/p/11314583.html
*/
//clint (core local interruptor) 管理局部中断
module clint(
    input wire                  clk,
    input wire                  rst,
    //from core
    input wire [`INT_BUS]       int_flag_i,
    //from id
    input wire [`InstBus]       inst_i,
    input wire [`InstAddrBus]   inst_addr_i,
    //from ex
    input wire                  jump_flag_i,
    input wire [`InstAddrBus]   jump_addr_i,
    //div TODO
    //from ctrl
    input wire [`Hold_Flag_Bus] hold_flag_i,//流水线暂停标志
    //from csr_reg
    input wire [`RegBus]        data_i,
    input wire [`RegBus]        csr_mtvec,
    input wire [`RegBus]        csr_mepc,
    input wire [`RegBus]        csr_mstatus,

    input wire                  global_int_en_i,

    //to ctrl
    output wire                 hold_flag_o,
    //to csr_reg
    output reg                  we_o,
    output reg [`MemAddrBus]    waddr_o,
    output reg [`MemAddrBus]    raddr_o,
    output reg [`RegBus]        data_o,
    //to ex
    output reg [`InstAddrBus]   int_addr_o,
    output reg                  int_assert_o

);
//中断状态定义
localparam S_INT_IDLE               = 4'b0001;
localparam S_INT_SYNC_ASSERT        = 4'b0010;
localparam S_INT_ASYNC_ASSERT       = 4'b0100;
localparam S_INT_MRET               = 4'b1000;//中断结束
//写CSR状态 地址定义
localparam S_CSR_IDLE               = 5'b00001;
localparam S_CSR_MSTATUS            = 5'b00010;
localparam S_CSR_MEPC               = 5'b00100;
localparam S_CSR_MSTATUS_MRET       = 5'b01000;
localparam S_CSR_MCAUSE             = 5'b10000;
reg[3:0] int_state;
reg[4:0] csr_state;
reg[`InstAddrBus] inst_addr;
reg[31:0] cause;

assign hold_flag_o = ((int_state != S_INT_IDLE) | (csr_state != S_CSR_IDLE))? `HoldEnable : `HoldDisable;
//中断仲裁组合逻辑
always@ (*) begin
    if(rst == `RstEnable) begin
        int_state = S_INT_IDLE;
    end else begin
        if((inst_i == `INST_ECALL) || (inst_i== `INST_EBREAK)) begin
            int_state = S_INT_ASYNC_ASSERT;
        end else if((int_flag_i != `INT_NONE) && (global_int_en_i == `True)) begin
            int_state = S_INT_ASYNC_ASSERT;
        end else if(inst_i == `INST_MRET) begin
            int_state = S_INT_MRET;
        end else begin
            int_state = S_INT_IDLE;
        end
    end
end
//写CSR寄存器状态切换
always@ (posedge clk ) begin
    if(rst == `RstEnable) begin
        csr_state <= S_CSR_IDLE;
        cause <= `ZeroWord;
        inst_addr <= `ZeroWord;
    end else begin
        case(csr_state)
        S_CSR_IDLE: begin
            //同步中断
            if(int_state == S_INT_SYNC_ASSERT) begin
                csr_state <= S_CSR_MEPC;
                if(jump_flag_i == `JumpEnable) begin
                    inst_addr <= inst_addr_i - 4'h4;
                end else begin
                    inst_addr <= inst_addr_i;
                end

                case(inst_i)
                    `INST_ECALL: begin
                        cause <= 32'd11;
                    end
                    `INST_EBREAK: begin
                        cause <= 32'd3;
                    end
                    default: begin
                        cause <= 32'd10;
                    end
                endcase
            //异步中断
            end else if (int_state == S_INT_ASYNC_ASSERT) begin
                //定时器中断
                cause <= 32'h8000_0004;
                csr_state <= S_CSR_MEPC;
                if(jump_flag_i == `JumpEnable) begin
                    inst_addr <= jump_addr_i;
                end else begin
                    inst_addr <= inst_addr_i;
                end
            end else if(int_state == S_INT_MRET) begin
                csr_state <= S_CSR_MSTATUS_MRET;
            end
        end
        S_CSR_MEPC: begin
            csr_state <= S_CSR_MSTATUS;
        end
        S_CSR_MSTATUS: begin
            csr_state <= S_CSR_MCAUSE;
        end
        S_CSR_MCAUSE: begin
            csr_state <= S_CSR_IDLE;
        end
        S_CSR_MSTATUS_MRET: begin
            csr_state <= S_CSR_IDLE;
        end
        default: begin
            csr_state <= S_CSR_IDLE;
        end
        endcase
    end
end
//发出中断信号前，写CSR寄存器
always@ (posedge clk) begin
    if(rst == `RstEnable) begin
        we_o <= `WriteDisable;
        waddr_o <= `ZeroWord;
        data_o <= `ZeroWord;
    end else begin
        case (csr_state)
            S_CSR_MEPC:begin
            we_o    <= `WriteEnable;
            waddr_o <= {20'h0, `CSR_MEPC};
            data_o  <= inst_addr;//记录中断地址
            end
            S_CSR_MCAUSE:begin
            we_o    <= `WriteEnable;
            waddr_o <= {20'h0, `CSR_MCAUSE};
            data_o  <= cause;//记录中断类型
            end
            S_CSR_MSTATUS:begin
            we_o    <= `WriteEnable;
            waddr_o <= {20'h0, `CSR_MSTATUS};
            data_o  <= {csr_mstatus[31:4], 1'b0, csr_mstatus[2:0]};//关闭全局中断
            end
            S_CSR_MSTATUS_MRET:begin
            we_o    <= `WriteEnable;
            waddr_o <= {20'h0, `CSR_MSTATUS};//[7]这个位置是一个WPRI寄存器，为了拓展指令设计。
            data_o  <= {csr_mstatus[31:4], csr_mstatus[7], csr_mstatus[2:0]};//中断返回
            end
            default:begin
            we_o    <= `WriteDisable;
            waddr_o <= `ZeroWord;
            data_o  <= `ZeroWord;
            end
        endcase
    end
end
//发出中断给ex
always@ (posedge clk) begin
    if (rst == `RstEnable) begin
        int_assert_o<= `INT_DEASSERT;
        int_addr_o  <= `ZeroWord;
    end else begin
        case (csr_state)
        S_CSR_MCAUSE:begin
            int_assert_o <= `INT_ASSERT;
            int_addr_o <= csr_mtvec;
        end
        S_CSR_MSTATUS_MRET:begin
            int_assert_o <= `INT_DEASSERT;
            int_addr_o <= `ZeroWord;
        end
        endcase
    end
end
endmodule