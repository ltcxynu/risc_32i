
module if_id(
    input wire clk,
    input wire rst,

    input wire [`InstBus]       inst_i,
    input wire [`InstAddrBus]   inst_addr_i,
    
    input wire [`Hold_Flag_Bus] hold_flag_i,
    
    input wire [`INT_BUS]       int_flag_i,
    
    output wire [`INT_BUS]      int_flag_o,
    output wire [`InstBus]      inst_o,
    output wire [`InstAddrBus]  inst_addr_o
);
    wire hold_en = (hold_flag_i >= `Hold_If);

    wire [`InstBus] inst;
    gen_pipe_dff #(32) inst_dff(clk,rst,hold_en,inst_i,`INST_NOP,inst);
    assign inst_o = inst;

    wire [`InstAddrBus] inst_addr;
    gen_pipe_dff #(32) inst_addr_dff(clk,rst,hold_en,inst_addr_i,`INST_NOP,inst_addr);
    assign inst_addr_o = inst_addr;

    wire [`INT_BUS] int_flag;
    gen_pipe_dff #(8) int_dff(clk,rst,hold_en,int_flag_i,`INT_NONE,int_flag);
    assign int_flag_o = int_flag;
endmodule