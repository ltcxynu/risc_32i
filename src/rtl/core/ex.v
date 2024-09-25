`ifndef SIM
`include "rv32i_defines.v"
`endif

module ex(
    //from id_ex
    input wire [`RegBus]        op1_i,
    input wire [`RegBus]        op2_i,
    input wire [`RegBus]        op1_jump_i,
    input wire [`RegBus]        op2_jump_i,
    input wire [`InstBus]       inst_i,
    input wire [`InstAddrBus]   inst_addr_i,
    input wire [`RegBus]        reg1_rdata_i,
    input wire [`RegBus]        reg2_rdata_i,
    input wire [`RegBus]        csr_rdata_i,
    //from / to mem ,这里考虑cache设计？halt？
    // write back regs
);

endmodule