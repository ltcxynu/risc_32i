`ifndef SIM
`include "rv32i_defines.v"
`include "../utils/gen_dff.v"
`endif
//第二级流水
//pc -> | FF |     |  id  |    | FF |      
// |    | FF | ->  |  ram | -> | FF | 
//rom-> | FF |     |  csr |    | FF |      
module id_ex(
// from id
input wire [`RegBus]        op1_i,
input wire [`RegBus]        op2_i,
input wire [`RegBus]        op1_jump_i,
input wire [`RegBus]        op2_jump_i,
input wire [`InstBus]       inst_i,
input wire [`InstAddrBus]   inst_addr_i,
input wire [`RegBus]        reg1_rdata_i,
input wire [`RegBus]        reg2_rdata_i,
input wire [`RegBus]        csr_rdata_i,
// to ex
output wire [`RegBus]        op1_o,
output wire [`RegBus]        op2_o,
output wire [`RegBus]        op1_jump_o,
output wire [`RegBus]        op2_jump_o,
output wire [`InstBus]       inst_o,
output wire [`InstAddrBus]   inst_addr_o,
output wire [`RegBus]        reg1_rdata_o,
output wire [`RegBus]        reg2_rdata_o,
output wire [`RegBus]        csr_rdata_o,
// halt
input wire [`Hold_Flag_Bus] hold_flag_i
);
wire hold_en = (hold_flag_i >= `Hold_Id);

wire [`InstBus] op1;
assign op1_o = op1;
gen_pipe_dff #(
    .DW(32)
)pipe_op1(
    .clk    (clk),
    .rst    (rst),
    .hold_en(HoldEnable),
    .def_val(`ZeroWord),
    .din    (op1_i),
    .qout   (op1)
);

wire [`InstBus] op2;
assign op2_o = op2;
gen_pipe_dff #(
    .DW(32)
)pipe_op2(
    .clk    (clk),
    .rst    (rst),
    .hold_en(HoldEnable),
    .def_val(`ZeroWord),
    .din    (op2_i),
    .qout   (op2)
);

wire [`InstBus] op1_jump;
assign op1_jump_o = op1_jump;
gen_pipe_dff #(
    .DW(32)
)pipe_op1_jump(
    .clk    (clk),
    .rst    (rst),
    .hold_en(HoldEnable),
    .def_val(`ZeroWord),
    .din    (op1_jump_i),
    .qout   (op1_jump)
);

wire [`InstBus] op2_jump;
assign op2_jump_o = op2_jump;
gen_pipe_dff #(
    .DW(32)
)pipe_op2_jump(
    .clk    (clk),
    .rst    (rst),
    .hold_en(HoldEnable),
    .def_val(`ZeroWord),
    .din    (op2_jump_i),
    .qout   (op2_jump)
);

wire [`InstBus] inst;
assign inst_o = inst;
gen_pipe_dff #(
    .DW(32)
)pipe_inst(
    .clk    (clk),
    .rst    (rst),
    .hold_en(HoldEnable),
    .def_val(`INST_NOP),
    .din    (inst_i),
    .qout   (inst)
);

wire [`InstAddrBus] inst_addr;
assign inst_addr_o = inst_addr;
gen_pipe_dff #(
    .DW(32)
)pipe_inst_addr(
    .clk    (clk),
    .rst    (rst),
    .hold_en(HoldEnable),
    .def_val(`ZeroWord),
    .din    (inst_addr_i),
    .qout   (inst_addr)
);

wire [`InstAddrBus] reg1_rdata;
assign reg1_raddr_o = reg1_rdata;
gen_pipe_dff #(
    .DW(32)
)pipe_reg1_rdata(
    .clk    (clk),
    .rst    (rst),
    .hold_en(HoldEnable),
    .def_val(`ZeroWord),
    .din    (reg1_rdata_i),
    .qout   (reg1_rdata)
);

wire [`InstAddrBus] reg2_rdata;
assign reg2_raddr_o = reg2_rdata;
gen_pipe_dff #(
    .DW(32)
)pipe_reg2_rdata(
    .clk    (clk),
    .rst    (rst),
    .hold_en(HoldEnable),
    .def_val(`ZeroWord),
    .din    (reg2_rdata_i),
    .qout   (reg2_rdata)
);

wire [`InstAddrBus] csr_rdata;
assign csr_rdata_o = csr_rdata;
gen_pipe_dff #(
    .DW(32)
)pipe_csr_rdata(
    .clk    (clk),
    .rst    (rst),
    .hold_en(HoldEnable),
    .def_val(`ZeroWord),
    .din    (csr_rdata_i),
    .qout   (csr_rdata)
);
endmodule