`ifndef SIM
`include "rv32i_defines.v"
`include "csr_reg.v"
`include "regs.v"
`include "pc.v"
`include "id.v"
`include "if_id.v"
`endif
module rv32i(
    input wire clk,
    input wire rst,
    //icache
    output wire o_inst_addr,
    output wire o_inst_byte_en,
    output wire o_inst_writedata,
    output wire o_inst_read,
    output wire o_inst_write,
    input  wire i_inst_readdata,
    input  wire i_inst_readdata_valid,
    input  wire i_inst_waitrequest,
    //dcache
    output wire o_data_addr,
    output wire o_data_byte_en,
    output wire o_data_writedata,
    output wire o_data_read,
    output wire o_data_write,
    input  wire i_data_readdata,
    input  wire i_data_readdata_valid,
    input  wire i_data_waitrequest,
    //jtag预留
    input wire[`RegAddrBus] jtag_reg_addr_i,   // jtag模块读、写寄存器的地址
    input wire[`RegBus] jtag_reg_data_i,       // jtag模块写寄存器数据
    input wire jtag_reg_we_i,                  // jtag模块写寄存器标志
    output wire[`RegBus] jtag_reg_data_o,      // jtag模块读取到的寄存器数据
    input wire jtag_halt_flag_i,               // jtag暂停标志
    input wire jtag_reset_flag_i,              // jtag复位PC标志
    //总线预留
    input wire rib_hold_flag_i,                // 总线暂停标志
    //外部中断预留
    input wire[`INT_BUS] int_i                 // 中断信号
    );
/************************val******************************/

/************************var******************************/
    //pc
    wire                    clk;
    wire                    rst;
    wire                    pc_jump_flag_i;
    wire[`InstAddrBus]      pc_jump_addr_i;
    wire [`Hold_Flag_Bus]   pc_hold_flag_i;
    wire [`InstAddrBus]     pc_inst_addr_o;
    wire [`InstBus]         pc_inst_o;
    wire                    pc_inst_valid_o;

    //pc->cache
    wire [`CacheAddrBus]    o_pc_addr;                //cpu->cache addr
    wire [`CacheByteBus]    o_pc_byte_en;             //写稀疏掩码
    wire [`CacheDataBus]    o_pc_writedata;           //写数据
    wire                    o_pc_read;                //读使能
    wire                    o_pc_write;               //写使能
    wire [`CacheDataBus]    i_pc_readdata;            //读数据
    wire                    i_pc_readdata_valid;      //读数据有效
    wire                    i_pc_waitrequest;         //操作等待

    //if_id
    wire [`INT_BUS]         if_id_int_flag_o;
    wire [`InstBus]         if_id_inst_o;
    wire [`InstAddrBus]     if_id_inst_addr_o;

    //id
    wire [`RegAddrBus]      id_reg1_raddr_o;
    wire [`RegAddrBus]      id_reg2_raddr_o;
    wire [`MemAddrBus]      id_csr_raddr_o;
    wire [`RegBus]          id_op1_o;
    wire [`RegBus]          id_op2_o;
    wire [`RegBus]          id_op1_jump_o;
    wire [`RegBus]          id_op2_jump_o;
    wire [`InstBus]         id_inst_o;
    wire [`InstAddrBus]     id_inst_addr_o;
    wire [`RegBus]          id_reg1_rdata_o;
    wire [`RegBus]          id_reg2_rdata_o;
    wire [`RegBus]          id_csr_rdata_o;
    //regs
    wire                    regs_we_i;
    wire [`RegBus]          regs_wdata_i;
    wire [`RegAddrBus]      regs_waddr_i;
    wire [`RegBus]          regs_rdata1_o;
    wire [`RegBus]          regs_rdata2_o;
    //csr_regs
    wire                    global_int_en_o;
    wire [`RegBus]          csr_rdata_o;
    //id_ex
    wire [`RegBus]          id_ex_op1_o;
    wire [`RegBus]          id_ex_op2_o;
    wire [`RegBus]          id_ex_op1_jump_o;
    wire [`RegBus]          id_ex_op2_jump_o;
    wire [`InstBus]         id_ex_inst_o;
    wire [`InstAddrBus]     id_ex_inst_addr_o;
    wire [`RegBus]          id_ex_reg1_rdata_o;
    wire [`RegBus]          id_ex_reg2_rdata_o;
    wire [`RegBus]          id_ex_csr_rdata_o;
    //ex
    wire [`RegBus]          ex_reg_wdata_o;
    wire                    ex_reg_we_o;
    wire [`RegAddrBus]      ex_reg_waddr_o;
    wire [`RegBus]          ex_csr_wdata_o;
    wire                    ex_csr_we_o;
    wire [`MemAddrBus]      ex_csr_waddr_o;
    wire                    ex_jump_flag_o;
    wire [`InstAddrBus]     ex_jump_addr_o;
    wire [`InstBus]         ex_inst_o;
    wire [`InstAddrBus]     ex_inst_addr_o;
    wire                    ex_hold_flag_o;
    wire [`CacheAddrBus]    o_p_addr;
    wire [`CacheByteBus]    o_p_byte_en;
    wire [`CacheDataBus]    o_p_writedata
    wire                    o_p_read;
    wire                    o_p_write;
    wire [`RegAddrBus]      ex_reg_wait_wb;
    //ex-> cache
    wire [`CacheAddrBus]    o_ex_addr;                //cpu->cache addr
    wire [`CacheByteBus]    o_ex_byte_en;             //写稀疏掩码
    wire [`CacheDataBus]    o_ex_writedata;           //写数据
    wire                    o_ex_read;                //读使能
    wire                    o_ex_write;               //写使能
    wire [`CacheDataBus]    i_wb_readdata;            //读数据
    wire                    i_wb_readdata_valid;      //读数据有效
    wire                    i_wb_waitrequest;         //操作等待
    //wb
    wire [`RegAddrBus]      wb_reg_waddr_o;
    wire [`RegBus]          wb_reg_wdata_o;
    wire [`RegAddrBus]      wb_reg_we_o;
    wire                    wb_done;
    //ctrl
    wire [`Hold_Flag_Bus]   ctrl_hold_flag_o;
    wire                    ctrl_jump_flag_o;
    wire [`InstAddrBus]     ctrl_jump_addr_o;
/**********************instance****************************/
pc u_pc(
    .clk                (clk                  ),
    .rst                (rst                  ),
    //intra connect  
    .jump_flag_i        (ctrl_jump_flag_o     ),
    .jump_addr_i        (ctrl_jump_addr_o     ),
    .hold_flag_i        (ctrl_hold_flag_o     ),
    .inst_addr_o        (pc_inst_addr_o       ),
    .inst_o             (pc_inst_o            ),
    .inst_valid         (pc_inst_valid_o      ),
    //inter connect
    //jtag
    .jtag_reset_flag_i  (jtag_reset_flag_i    ),
    //cache  
    .o_p_addr           (o_pc_addr            ),
    .o_p_byte_en        (o_pc_byte_en         ),
    .o_p_writedata      (o_pc_writedata       ),
    .o_p_read           (o_pc_read            ),
    .o_p_write          (o_pc_write           ),
    .i_p_readdata       (i_pc_readdata        ),
    .i_p_readdata_valid (i_pc_readdata_valid  ),
    .i_p_waitrequest    (i_pc_waitrequest     )
);
cache u_icache(
    .clk                (clk                  ),
    .rst                (rst                  ),
    //intra connect  
    .i_p_addr           (o_pc_addr            ),
    .i_p_byte_en        (o_pc_byte_en         ),
    .i_p_writedata      (o_pc_writedata       ),
    .i_p_read           (o_pc_read            ),
    .i_p_write          (o_pc_write           ),
    .o_p_readdata       (i_pc_readdata        ),
    .o_p_readdata_valid (i_pc_readdata_valid  ),
    .o_p_waitrequest    (i_pc_waitrequest     ),
    //inter connect
    //mem
    .o_m_addr           (o_inst_addr          ),
    .o_m_byte_en        (o_inst_byte_en       ),
    .o_m_writedata      (o_inst_writedata     ),
    .o_m_read           (o_inst_read          ),
    .o_m_write          (o_inst_write         ),
    .i_m_readdata       (i_inst_readdata      ),
    .i_m_readdata_valid (i_inst_readdata_valid),
    .i_m_waitrequest    (i_inst_waitrequest   ),
    //floating
    .cnt_r              (                     ),
    .cnt_w              (                     ),
    .cnt_hit_r          (                     ),
    .cnt_hit_w          (                     ),
    .cnt_wb_r           (                     ),
    .cnt_wb_w           (                     )
);
if_id u_if_id(
    .clk                (clk                  ),
    .rst                (rst                  ),
    .inst_i             (pc_inst_o            ),
    .inst_addr_i        (pc_inst_addr_o       ),
    .inst_valid_i       (pc_inst_valid_o      ),
    .hold_flag_i        (                     ),
    .int_flag_i         (                     ),
    .int_flag_o         (if_id_int_flag_o     ),
    .inst_o             (if_id_inst_o         ),
    .inst_addr_o        (if_id_inst_addr_o    )
    );
id u_id(
    .rst                (rst                  ),
    .inst_i             (if_id_inst_o         ),
    .inst_addr_i        (if_id_inst_addr_o    ),
    .reg1_rdata_i       (regs_rdata1_o        ),
    .reg2_rdata_i       (regs_rdata2_o        ),
    .reg1_raddr_o       (id_reg1_raddr_o      ),
    .reg2_raddr_o       (id_reg2_raddr_o      ),
    .csr_raddr_o        (id_csr_raddr_o       ),
    .op1_o              (id_op1_o             ),
    .op2_o              (id_op2_o             ),
    .op1_jump_o         (id_op1_jump_o        ),
    .op2_jump_o         (id_op2_jump_o        ),
    .inst_o             (id_inst_o            ),
    .inst_addr_o        (id_inst_addr_o       ),
    .reg1_rdata_o       (id_reg1_rdata_o      ),
    .reg2_rdata_o       (id_reg2_rdata_o      ),
    .csr_rdata_o        (id_csr_rdata_o       )
);
//ex 和 wb 不会同时工作，这样写问题不大。
assign regs_we_i    = ex_reg_we_o    | wb_reg_we_o;
assign regs_wdata_i = ex_reg_wdata_o | wb_reg_wdata_o;
assign regs_waddr_i = ex_reg_waddr_o | wb_reg_waddr_o;
regs u_regs(
    .clk                (clk                  ),
    .rst                (rst                  ),
    .we_i               (regs_we_i            ),
    .wdata_i            (regs_wdata_i         ),
    .waddr_i            (regs_waddr_i         ),
    .jtag_we_i          (jtag_reg_we_i        ),
    .jtag_data_i        (jtag_reg_data_i      ),
    .jtag_addr_i        (jtag_reg_addr_i      ),
    .jtag_data_o        (jtag_reg_data_o      ),
    .rdata1_o           (regs_rdata1_o        ),
    .rdata2_o           (regs_rdata2_o        ),
    .raddr1_i           (id_reg1_raddr_o      ),
    .raddr2_i           (id_reg2_raddr_o      )
);
csr_reg u_csr_reg(
    .clk                (clk                  ),
    .rst                (rst                  ),
    .we_i               (                     ),
    .raddr_i            (id_csr_raddr_o       ),
    .data_o             (csr_rdata_o          ),
    .waddr_i            (ex_csr_waddr_o       ),
    .data_i             (ex_csr_wdata_o       ),
    .clint_we_i         (                     ),
    .clint_raddr_i      (                     ),
    .clint_waddr_i      (                     ),
    .clint_data_i       (                     ),
    .clint_data_o       (                     ),
    .clint_csr_mtvec    (                     ),
    .clint_csr_mepc     (                     ),
    .clint_csr_mstatus  (                     ),
    .global_int_en_o    (global_int_en_o      )
);
id_ex u_id_ex(
    .clk                (clk                  ),
    .rst                (rst                  ),
    .op1_i              (id_op1_o             ),
    .op2_i              (id_op2_o             ),
    .op1_jump_i         (id_op1_jump_o        ),
    .op2_jump_i         (id_op2_jump_o        ),
    .inst_i             (id_inst_o            ),
    .inst_addr_i        (id_inst_addr_o       ),
    .reg1_rdata_i       (id_reg1_rdata_o      ),
    .reg2_rdata_i       (id_reg2_rdata_o      ),
    .csr_rdata_i        (id_csr_rdata_o       ),

    .op1_o              (id_ex_op1_o          ),
    .op2_o              (id_ex_op2_o          ),
    .op1_jump_o         (id_ex_op1_jump_o     ),
    .op2_jump_o         (id_ex_op2_jump_o     ),
    .inst_o             (id_ex_inst_o         ),
    .inst_addr_o        (id_ex_inst_addr_o    ),
    .reg1_rdata_o       (id_ex_reg1_rdata_o   ),
    .reg2_rdata_o       (id_ex_reg2_rdata_o   ),
    .csr_rdata_o        (id_ex_csr_rdata_o    ),
    .hold_flag_i        (                     )
);
ex u_ex(
    .op1_i              (id_ex_op1_o          ),
    .op2_i              (id_ex_op2_o          ),
    .op1_jump_i         (id_ex_op1_jump_o     ),
    .op2_jump_i         (id_ex_op2_jump_o     ),
    .inst_i             (id_ex_inst_o         ),
    .inst_addr_i        (id_ex_inst_addr_o    ),
    .reg1_rdata_i       (id_ex_reg1_rdata_o   ),
    .reg2_rdata_i       (id_ex_reg2_rdata_o   ),
    .csr_rdata_i        (id_ex_csr_rdata_o    ),

    .reg_wdata_o        (ex_reg_wdata_o       ),
    .reg_we_o           (ex_reg_we_o          ),
    .reg_waddr_o        (ex_reg_waddr_o       ),
    .csr_wdata_o        (ex_csr_wdata_o       ),
    .csr_we_o           (ex_csr_we_o          ),
    .csr_waddr_o        (ex_csr_waddr_o       ),
    .jump_flag_o        (ex_jump_flag_o       ),
    .jump_addr_o        (ex_jump_addr_o       ),
    .inst_o             (ex_inst_o            ),
    .inst_addr_o        (ex_inst_addr_o       ),
    .hold_flag_o        (ex_hold_flag_o       ),
    .o_p_addr           (o_ex_addr            ),
    .o_p_byte_en        (o_ex_byte_en         ),
    .o_p_writedata      (o_ex_writedata       ),
    .o_p_read           (o_ex_read            ),
    .o_p_write          (o_ex_write           ),
    .reg_wait_wb        (ex_reg_wait_wb       )
);
wb u_wb(
    .i_p_readdata       (i_wb_readdata        ),
    .i_p_readdata_valid (i_wb_readdata_valid  ),
    .i_p_waitrequest    (i_wb_waitrequest     ),
    .reg_wait_wb        (ex_reg_wait_wb       ),
    .reg_waddr_o        (wb_reg_waddr_o       ),
    .reg_wdata_o        (wb_reg_wdata_o       ),
    .reg_we_o           (wb_reg_we_o          ),
    .wb_done            (wb_done              )
);
cache d_cache(
    .clk                (clk                ),
    .rst                (rst                ),
    .i_p_addr           (o_ex_addr           ),
    .i_p_byte_en        (o_ex_byte_en        ),
    .i_p_writedata      (o_ex_writedata      ),
    .i_p_read           (o_ex_read           ),
    .i_p_write          (o_ex_write          ),
    .o_p_readdata       (i_wb_readdata       ),
    .o_p_readdata_valid (i_wb_readdata_valid ),
    .o_p_waitrequest    (i_wb_waitrequest    ),
    .o_m_addr           (o_data_addr           ),
    .o_m_byte_en        (o_data_byte_en        ),
    .o_m_writedata      (o_data_writedata      ),
    .o_m_read           (o_data_read           ),
    .o_m_write          (o_data_write          ),
    .i_m_readdata       (i_data_readdata       ),
    .i_m_readdata_valid (i_data_readdata_valid ),
    .i_m_waitrequest    (i_data_waitrequest    ),
    .cnt_r              (cnt_r              ),
    .cnt_w              (cnt_w              ),
    .cnt_hit_r          (cnt_hit_r          ),
    .cnt_hit_w          (cnt_hit_w          ),
    .cnt_wb_r           (cnt_wb_r           ),
    .cnt_wb_w           (cnt_wb_w           )
);

ctrl u_ctrl(
    .rst                (rst                  ),
    .jump_flag_i        (ex_jump_flag_o       ),
    .jump_addr_i        (ex_jump_addr_o       ),
    .hold_flag_ex_i     (ex_hold_flag_o       ),
    .wb_done            (wb_done              ),
    .hold_flag_rib_i    (rib_hold_flag_i      ),
    .jtag_halt_flag_i   (jtag_halt_flag_i     ),
    .hold_flag_clint_i  (    ),
    .hold_flag_o        (ctrl_hold_flag_o     ),
    .jump_flag_o        (ctrl_jump_flag_o     ),
    .jump_addr_o        (ctrl_jump_addr_o     )
);

endmodule