module ctrl(
    input wire rst,
    //from ex
    input wire jump_flag_i,
    input wire[`InstAddrBus] jump_addr_i,
    input wire hold_flag_ex_i,
    //from wb
    input wire wb_done,
    //from rib 总线
    input wire hold_flag_rib_i,
    // from jtag
    input wire jtag_halt_flag_i,
    // from clint
    input wire hold_flag_clint_i,
    // to all other module
    output reg[`Hold_Flag_Bus] hold_flag_o,
    // to pc_reg
    output reg jump_flag_o,
    output reg[`InstAddrBus] jump_addr_o
);

    always @ (*) begin
        jump_addr_o = jump_addr_i;
        jump_flag_o = jump_flag_i;
        // 默认不暂停
        hold_flag_o = `Hold_None;
        // 按优先级处理不同模块的请求
        if (jump_flag_i == `JumpEnable || hold_flag_ex_i == `HoldEnable || hold_flag_clint_i == `HoldEnable || ~wb_done) begin
            // 暂停整条流水线
            hold_flag_o = `Hold_Id;
        end else if (hold_flag_rib_i == `HoldEnable) begin
            // 暂停PC，即取指地址不变
            hold_flag_o = `Hold_Pc;
        end else if (jtag_halt_flag_i == `HoldEnable) begin
            // 暂停整条流水线
            hold_flag_o = `Hold_Id;
        end else begin
            hold_flag_o = `Hold_None;
        end
    end

endmodule