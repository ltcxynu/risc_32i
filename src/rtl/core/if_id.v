module if_id(
    input wire                  clk,
    input wire                  rst,

    input wire [`InstBus]       inst_i,
    input wire [`InstAddrBus]   inst_addr_i,
    input wire                  inst_valid_i,
    input wire [`Hold_Flag_Bus] hold_flag_i,

    input wire [`INT_BUS]       int_flag_i,

    output wire [`INT_BUS]      int_flag_o,
    output wire [`InstBus]      inst_o,
    output wire [`InstAddrBus]  inst_addr_o
    );
//第一级流水
//pc -> | FF | 
// |    | FF | -> 
//rom-> | FF |
wire hold_en = (hold_flag_i >= `Hold_If);
wire [`InstBus] inst;
assign inst_o = inst;
gen_pipe_dff #(
    .DW(32)
)pipe_inst(
    .clk    (clk),
    .rst    (~rst),
    .hold_en(hold_en|~inst_valid_i),
    .def_val(`INST_NOP),
    .din    (inst_i),
    .qout   (inst)
);
wire  inst_valid;
gen_pipe_dff #(
    .DW(1)
)pipe_inst_valid(
    .clk    (clk),
    .rst    (~rst),
    .hold_en(hold_en|~inst_valid_i),
    .def_val(1'b0),
    .din    (inst_valid_i),
    .qout   (inst_valid)
);
wire [`InstAddrBus] inst_addr;
assign inst_addr_o = inst_addr;
gen_pipe_dff #(
    .DW(32)
)pipe_inst_addr(
    .clk    (clk),
    .rst    (~rst),
    .hold_en(hold_en|~inst_valid_i),
    .def_val(`ZeroWord),
    .din    (inst_addr_i),
    .qout   (inst_addr)
);
wire [`INT_BUS] int_flag;
assign int_flag_o = int_flag;
gen_pipe_dff #(
    .DW(8)
)pipe_int_flag(
    .clk    (clk),
    .rst    (~rst),
    .hold_en(hold_en),
    .def_val(`INT_NONE),
    .din    (int_flag_i),
    .qout   (int_flag)
);
endmodule