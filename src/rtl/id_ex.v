`include "bus_defines.v"
`include "rv32i_defines.v"
`include "../utils/gen_dff.v"
module id_ex(
    input wire                      clk,
    input wire                      rst,
    //from id   
    input wire[`MemAddrBus]         op1_i,//
    input wire[`MemAddrBus]         op2_i,
    input wire[`MemAddrBus]         op1_jump_i,
    input wire[`MemAddrBus]         op2_jump_i,
    input wire[`InstBus]            inst_i,
    input wire[`InstAddrBus]        inst_addr_i,     
    input wire [`RegBus]            reg1_rdata_i,
    input wire [`RegBus]            reg2_rdata_i,
    input wire                      reg_we_i,
    input wire [`RegAddrBus]        reg_waddr_i,
    input wire                      csr_we_i,
    input wire [`RegBus]            csr_rdata_i,
    input wire [`MemAddrBus]        csr_waddr_i,
    //to out
    output wire[`MemAddrBus]        op1_o,//
    output wire[`MemAddrBus]        op2_o,
    output wire[`MemAddrBus]        op1_jump_o,
    output wire[`MemAddrBus]        op2_jump_o,
    output wire[`InstBus]           inst_o,
    output wire[`InstAddrBus]       inst_addr_o,     
    output wire [`RegBus]           reg1_rdata_o,
    output wire [`RegBus]           reg2_rdata_o,
    output wire                     reg_we_o,
    output wire [`RegAddrBus]       reg_waddr_o,
    output wire                     csr_we_o,
    output wire [`RegBus]           csr_rdata_o,
    output wire [`MemAddrBus]       csr_waddr_o,
    //halt
    input wire                      hold_flag_i
);
//在id 和 ex之间的流水线寄存器
wire hold_en = (hold_flag_i >= `Hold_Id);

wire[`MemAddrBus] op1;
    gen_pipe_dff #(32) op1_dff(clk,rst,hold_en,op1_i,`ZeroWord,op1);
assign op1_o = op1;

wire[`MemAddrBus] op2;
    gen_pipe_dff #(32) op2_dff(clk,rst,hold_en,op2_i,`ZeroWord,op2);
assign op2_o = op2;

wire[`MemAddrBus] op1_jump;
    gen_pipe_dff #(32) op1_jump_dff(clk,rst,hold_en,op1_jump_i,`ZeroWord,op1_jump);
assign op1_jump_o = op1_jump;

wire[`MemAddrBus] op2_jump;
    gen_pipe_dff #(32) op2_jump_dff(clk,rst,hold_en,op2_jump_i,`ZeroWord,op2_jump);
assign op2_jump_o = op2_jump;

wire[`InstBus] inst;
    gen_pipe_dff #(32) inst_dff(clk,rst,hold_en,inst_i,`INST_NOP,inst);
assign inst_o = inst;

wire[`InstAddrBus] inst_addr;
    gen_pipe_dff #(32) inst_add_dff(clk,rst,hold_en,inst_addr_i,`ZeroWord,inst_addr);
assign inst_addr_o = inst_addr;

wire[`RegBus] reg1_rdata;
    gen_pipe_dff #(32) reg1_rdata_dff(clk,rst,hold_en,reg1_rdata_i,`ZeroWord,reg1_rdata);
assign reg1_rdata_o = reg1_rdata;

wire[`RegBus] reg2_rdata;
    gen_pipe_dff #(32) reg2_rdata_dff(clk,rst,hold_en,reg2_rdata_i,`ZeroWord,reg2_rdata);
assign reg2_rdata_o = reg2_rdata;

wire reg_we;
    gen_pipe_dff #(1) reg_we_dff(clk,rst,hold_en,reg_we_i,`WriteDisable,reg_we);
assign reg_we_o = reg_we;

wire[`RegAddrBus] reg_waddr;
    gen_pipe_dff #(5) reg_waddr_dff(clk,rst,hold_en,reg_waddr_i,`ZeroReg,reg_waddr);
assign reg_waddr_o = reg_waddr;

wire csr_we;
    gen_pipe_dff #(1) csr_we_dff(clk,rst,hold_en,csr_we_i,`WriteDisable,csr_we);
assign csr_we_o = csr_we;

wire[`RegBus] csr_rdata;
    gen_pipe_dff #(32) csr_rdata_dff(clk,rst,hold_en,csr_rdata_i,`ZeroWord,csr_rdata);
assign csr_rdata_o = csr_rdata;

wire[`MemAddrBus] csr_waddr;
    gen_pipe_dff #(32) csr_waddr_dff(clk,rst,hold_en,csr_waddr_i,`ZeroWord,csr_waddr);
assign csr_waddr_o = csr_waddr;

endmodule