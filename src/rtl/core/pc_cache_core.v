module pc_cache_core(
    input   wire                    clk,
    input   wire                    rst,
    input   wire                    jtag_reset_flag_i,

    input   wire                    jump_flag_i,
    input   wire[`InstAddrBus]      jump_addr_i,
    //from ctrl
    input   wire [`Hold_Flag_Bus]   hold_flag_i,
    output  reg [`InstAddrBus]      inst_addr_o,
    output  reg [`InstBus]          inst_o,
    //icache
    output wire [`CacheMemAddrBus]  o_inst_addr,
    output wire [`CacheMemByteBus]  o_inst_byte_en,
    output wire [`CacheMemDataBus]  o_inst_writedata,
    output wire                     o_inst_read,
    output wire                     o_inst_write,
    input  wire [`CacheMemDataBus]  i_inst_readdata,
    input  wire                     i_inst_readdata_valid,
    input  wire                     i_inst_waitrequest
);
//PC write to addr fifo
wire[`InstAddrBus]       pc_2_addr_fifo_wdata;
wire                     addr_fifo_full;
wire                     pc_2_addr_fifo_wen;
wire                     pc_2_addr_fifo_rstn;
//PC read from inst fifo
wire                     inst_fifo_empty;
wire [`InstBus]          pc_2_inst_fifo_rdata;
wire                     pc_2_inst_fifo_ren;
//Fetch write to inst_fifo
wire                    inst_fifo_full;
wire [`InstBus]         fetch_2_inst_fifo_wdata;
wire                    fetch_2_inst_fifo_wen;
wire                    fetch_2_inst_fifo_rstn;

//Fetch read from addr_fifo
wire [`InstAddrBus]      fetch_2_addr_fifo_rdata;
wire                     addr_fifo_empty;
wire                     fetch_2_addr_fifo_ren;
//cache
wire [`CacheAddrBus]    o_fetch_addr;                //cpu->cache addr
wire [`CacheByteBus]    o_fetch_byte_en;             //写稀疏掩码
wire [`CacheDataBus]    o_fetch_writedata;           //写数据
wire                    o_fetch_read;                //读使能
wire                    o_fetch_write;               //写使能
wire [`CacheDataBus]    i_fetch_readdata;            //读数据
wire                    i_fetch_readdata_valid;      //读数据有效
wire                    i_fetch_waitrequest;         //操作等待

pc_ u_pc_(
    .clk               (clk               ),
    .rst               (rst               ),
    .jump_flag_i       (jump_flag_i       ),
    .jump_addr_i       (jump_addr_i       ),
    .hold_flag_i       (hold_flag_i       ),
    .inst_addr_o       (inst_addr_o       ),
    .inst_o            (inst_o            ),
    .jtag_reset_flag_i (jtag_reset_flag_i ),
    .addr_fifo_w       (pc_2_addr_fifo_wdata       ),
    .addr_fifo_full    (addr_fifo_full    ),
    .addr_fifo_wen     (pc_2_addr_fifo_wen            ),
    .addr_fifo_rstn    (pc_2_addr_fifo_rstn          ),
    .inst_fifo_empty   (inst_fifo_empty        ),
    .inst_fifo_r       (pc_2_inst_fifo_rdata            ),
    .inst_fifo_ren     (pc_2_inst_fifo_ren            )
);


sync_fifo #(
    .ASIZE (4),
    .DSIZE (32)
)addr_fifo(
    .clk        (clk                    ),
    .rst_n      (~rst & pc_2_addr_fifo_rstn         ),
    .wr_en      (pc_2_addr_fifo_wen                 ),
    .rd_en      (fetch_2_addr_fifo_ren              ),
    .w_data     (pc_2_addr_fifo_wdata            ),
    .r_data     (fetch_2_addr_fifo_rdata            ),
    .fifo_full  (addr_fifo_full         ),
    .fifo_empty (addr_fifo_empty             )
);
sync_fifo #(
    .ASIZE (4),
    .DSIZE (32)
)inst_fifo(
    .clk        (clk                    ),
    .rst_n      (~rst & fetch_2_inst_fifo_rstn     ),
    .wr_en      (fetch_2_inst_fifo_wen               ),
    .rd_en      (pc_2_inst_fifo_ren                 ),
    .w_data     (fetch_2_inst_fifo_wdata                 ),
    .r_data     (pc_2_inst_fifo_rdata                 ),
    .fifo_full  (inst_fifo_full              ),
    .fifo_empty (inst_fifo_empty             )
);
fetch_cache u_fetch_cache(
    .clk                (clk                ),
    .rst                (rst                ),
    .jump_flag_i        (jump_flag_i        ),
    .jump_addr_i        (jump_addr_i        ),
    .jtag_reset_flag_i  (jtag_reset_flag_i  ),
    .o_p_addr           (o_fetch_addr            ),
    .o_p_byte_en        (o_fetch_byte_en         ),
    .o_p_writedata      (o_fetch_writedata       ),
    .o_p_read           (o_fetch_read            ),
    .o_p_write          (o_fetch_write           ),
    .i_p_readdata       (i_fetch_readdata        ),
    .i_p_readdata_valid (i_fetch_readdata_valid  ),
    .i_p_waitrequest    (i_fetch_waitrequest     ),
    .inst_fifo_full     (inst_fifo_full          ),
    .inst_fifo_r        (fetch_2_inst_fifo_wdata             ),
    .inst_fifo_wen      (fetch_2_inst_fifo_wen           ),
    .inst_fifo_rstn     (fetch_2_inst_fifo_rstn      ),
    .addr_fifo_r        (fetch_2_addr_fifo_rdata        ),
    .addr_fifo_empty    (addr_fifo_empty         ),
    .addr_fifo_ren      (fetch_2_addr_fifo_ren          )
);
cache inst_cache(
    .clk                (clk                ),
    .rst                (rst                ),
    .i_p_addr           (o_fetch_addr            ),
    .i_p_byte_en        (o_fetch_byte_en         ),
    .i_p_writedata      (o_fetch_writedata       ),
    .i_p_read           (o_fetch_read            ),
    .i_p_write          (o_fetch_write           ),
    .o_p_readdata       (i_fetch_readdata        ),
    .o_p_readdata_valid (i_fetch_readdata_valid  ),
    .o_p_waitrequest    (i_fetch_waitrequest     ),
    .o_m_addr           (o_inst_addr            ),
    .o_m_byte_en        (o_inst_byte_en         ),
    .o_m_writedata      (o_inst_writedata       ),
    .o_m_read           (o_inst_read            ),
    .o_m_write          (o_inst_write           ),
    .i_m_readdata       (i_inst_readdata        ),
    .i_m_readdata_valid (i_inst_readdata_valid  ),
    .i_m_waitrequest    (i_inst_waitrequest     )
);

endmodule