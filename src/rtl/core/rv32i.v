`ifndef SIM
`include "../core/rv32i_defines.v"
`include "../utils/gen_dff.v"
`include "../core/pc.v"
`include "../core/if_id.v"
`include "../core/id.v"
`include "../core/id_ex.v"
`include "../core/ex.v"
`include "../core/clint.v"
`include "../core/wb.v"
`include "../core/ctrl.v"
`include "../core/regs.v"
`include "../core/csr_reg.v"
`include "../cache/simple_ram.v"
`include "../cache/4way_4word.v"
`include "../core/rv32i_defines.v"

`include "../core/pc_.v"
`include "../core/fifo_.v"
`include "../core/fetch_cache.v"
`include "../core/pc_cache_core.v"
`endif
module rv32i(
    input wire clk,
    input wire rst,
    //icache
    output wire [`CacheMemAddrBus]  o_inst_addr,
    output wire [`CacheMemByteBus]  o_inst_byte_en,
    output wire [`CacheMemDataBus]  o_inst_writedata,
    output wire                     o_inst_read,
    output wire                     o_inst_write,
    input  wire [`CacheMemDataBus]  i_inst_readdata,
    input  wire                     i_inst_readdata_valid,
    input  wire                     i_inst_waitrequest,
    //dcache
    output wire  [`CacheMemAddrBus] o_data_addr,
    output wire  [`CacheMemByteBus] o_data_byte_en,
    output wire  [`CacheMemDataBus] o_data_writedata,
    output wire                     o_data_read,
    output wire                     o_data_write,
    input  wire  [`CacheMemDataBus] i_data_readdata,
    input  wire                     i_data_readdata_valid,
    input  wire                     i_data_waitrequest,
    //jtag预留
    input  wire  [`RegAddrBus]      jtag_reg_addr_i,   // jtag模块读、写寄存器的地址
    input  wire  [`RegBus]          jtag_reg_data_i,       // jtag模块写寄存器数据
    input  wire                     jtag_reg_we_i,                  // jtag模块写寄存器标志
    output wire  [`RegBus]          jtag_reg_data_o,      // jtag模块读取到的寄存器数据
    input  wire                     jtag_halt_flag_i,               // jtag暂停标志
    input  wire                     jtag_reset_flag_i,              // jtag复位PC标志
    //总线预留
    input  wire                     rib_hold_flag_i,                // 总线暂停标志
    //外部中断预留
    input  wire  [`INT_BUS]         int_i                 // 中断信号
    );
/************************val******************************/

/************************var******************************/
    //pc
    wire                    pc_jump_flag_i;
    wire[`InstAddrBus]      pc_jump_addr_i;
    wire [`Hold_Flag_Bus]   pc_hold_flag_i;
    wire [`InstAddrBus]     pc_inst_addr_o;
    wire [`InstBus]         pc_inst_o;
    wire                    pc_inst_valid_o;

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
    wire [`RegAddrBus]      ex_reg_wait_wb;
    wire [1:0]              ex_mask_wait_wb;
    wire [2:0]              ex_ifunct3_wait_wb;
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
    //clint csr
    wire [`RegBus]          clint_data_i;
    wire [`RegBus]          clint_csr_mtvec;
    wire [`RegBus]          clint_csr_mepc;
    wire [`RegBus]          clint_csr_mstatus;
    wire                    csr_global_int_en_i;
    wire                    clint_hold_flag_o;
    wire                    clint_we_o;
    wire [`MemAddrBus]      clint_waddr_o;
    wire [`MemAddrBus]      clint_raddr_o;
    wire [`RegBus]          clint_data_o;
    wire [`InstAddrBus]     clint_int_addr_o;
    wire                    clint_int_assert_o;
/**********************instance****************************/
pc_cache_core u_pc_cache_core(
    .clk                   (clk                   ),
    .rst                   (rst                   ),
    .jtag_reset_flag_i     (jtag_reset_flag_i     ),
    .jump_flag_i           (ctrl_jump_flag_o      ),
    .jump_addr_i           (ctrl_jump_addr_o      ),
    .hold_flag_i           (ctrl_hold_flag_o      ),
    .inst_addr_o           (pc_inst_addr_o        ),
    .inst_o                (pc_inst_o             ),
    .o_inst_addr           (o_inst_addr           ),
    .o_inst_byte_en        (o_inst_byte_en        ),
    .o_inst_writedata      (o_inst_writedata      ),
    .o_inst_read           (o_inst_read           ),
    .o_inst_write          (o_inst_write          ),
    .i_inst_readdata       (i_inst_readdata       ),
    .i_inst_readdata_valid (i_inst_readdata_valid ),
    .i_inst_waitrequest    (i_inst_waitrequest    )
);

if_id u_if_id(
    .clk                (clk                  ),
    .rst                (rst                  ),
    .inst_i             (pc_inst_o            ),
    .inst_addr_i        (pc_inst_addr_o       ),
    .inst_valid_i       (1'b1                 ),
    .hold_flag_i        (ctrl_hold_flag_o     ),
    .int_flag_i         (int_i                ),
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
    .clint_we_i         (clint_we_o           ),
    .clint_raddr_i      (clint_raddr_o        ),
    .clint_waddr_i      (clint_waddr_o        ),
    .clint_data_i       (clint_data_o         ),
    .clint_data_o       (clint_data_i         ),
    .clint_csr_mtvec    (clint_csr_mtvec      ),
    .clint_csr_mepc     (clint_csr_mepc       ),
    .clint_csr_mstatus  (clint_csr_mstatus    ),
    .global_int_en_o    (csr_global_int_en_i  )
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
    .hold_flag_i        (ctrl_hold_flag_o     )
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
    .reg_wait_wb        (ex_reg_wait_wb       ),
    .mask_wait_wb       (ex_mask_wait_wb      ),
    .ifunct3_wait_wb    (ex_ifunct3_wait_wb   )
);
wb u_wb(
    .clk                (clk                  ),
    .rst                (rst                  ),
    .i_p_readdata       (i_wb_readdata        ),
    .i_p_readdata_valid (i_wb_readdata_valid  ),
    .i_p_waitrequest    (i_wb_waitrequest     ),
    .reg_wait_wb        (ex_reg_wait_wb       ),
    .mask_wait_wb       (ex_mask_wait_wb      ),
    .ifunct3_wait_wb    (ex_ifunct3_wait_wb   ),
    .reg_waddr_o        (wb_reg_waddr_o       ),
    .reg_wdata_o        (wb_reg_wdata_o       ),
    .reg_we_o           (wb_reg_we_o          ),
    .wb_done            (wb_done              ),
    .ex_read_mem        (o_ex_read            )
);
cache d_cache(
    .clk                (clk                  ),
    .rst                (rst                  ),
    //intra connect
    .i_p_addr           (o_ex_addr            ),
    .i_p_byte_en        (o_ex_byte_en         ),
    .i_p_writedata      (o_ex_writedata       ),
    .i_p_read           (o_ex_read            ),
    .i_p_write          (o_ex_write           ),
    .o_p_readdata       (i_wb_readdata        ),
    .o_p_readdata_valid (i_wb_readdata_valid  ),
    .o_p_waitrequest    (i_wb_waitrequest     ),
    //inter connct
    //mem
    .o_m_addr           (o_data_addr          ),
    .o_m_byte_en        (o_data_byte_en       ),
    .o_m_writedata      (o_data_writedata     ),
    .o_m_read           (o_data_read          ),
    .o_m_write          (o_data_write         ),
    .i_m_readdata       (i_data_readdata      ),
    .i_m_readdata_valid (i_data_readdata_valid),
    .i_m_waitrequest    (i_data_waitrequest   ),
    //floating
    .cnt_r              (                     ),
    .cnt_w              (                     ),
    .cnt_hit_r          (                     ),
    .cnt_hit_w          (                     ),
    .cnt_wb_r           (                     ),
    .cnt_wb_w           (                     )
);

ctrl u_ctrl(
    .rst                (rst                  ),
    .jump_flag_i        (ex_jump_flag_o       ),
    .jump_addr_i        (ex_jump_addr_o       ),
    .hold_flag_ex_i     (ex_hold_flag_o       ),
    .wb_done            (wb_done              ),
    .hold_flag_rib_i    (rib_hold_flag_i      ),
    .jtag_halt_flag_i   (jtag_halt_flag_i     ),
    .hold_flag_clint_i  (clint_hold_flag_o    ),
    .hold_flag_o        (ctrl_hold_flag_o     ),
    .jump_flag_o        (ctrl_jump_flag_o     ),
    .jump_addr_o        (ctrl_jump_addr_o     )
);
clint u_clint(
    .clk                (clk                  ),
    .rst                (rst                  ),
    .int_flag_i         (if_id_int_flag_o     ),
    .inst_i             (id_inst_o            ),
    .inst_addr_i        (id_inst_addr_o       ),
    .jump_flag_i        (ex_jump_flag_o       ),
    .jump_addr_i        (ex_jump_addr_o       ),
    .hold_flag_i        (ctrl_hold_flag_o     ),
    .data_i             (clint_data_i         ),
    .csr_mtvec          (clint_csr_mtvec      ),
    .csr_mepc           (clint_csr_mepc       ),
    .csr_mstatus        (clint_csr_mstatus    ),
    .global_int_en_i    (csr_global_int_en_i  ),
    .hold_flag_o        (clint_hold_flag_o    ),
    .we_o               (clint_we_o           ),
    .waddr_o            (clint_waddr_o        ),
    .raddr_o            (clint_raddr_o        ),
    .data_o             (clint_data_o         ),
    .int_addr_o         (clint_int_addr_o     ),
    .int_assert_o       (clint_int_assert_o   )
);

endmodule