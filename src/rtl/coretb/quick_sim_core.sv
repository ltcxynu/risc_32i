`ifndef SIM
`define SIM
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
`include "../core/rv32i.v"
`include "../cache/simple_ram.v"
`include "../cache/4way_4word.v"
`include "../core/pc_.v"
`include "../core/fifo_.v"
`include "../core/fetch_cache.v"
`include "../core/pc_cache_core.v"
`endif
`timescale 1ns/1ns
module quick_sim_core;
/************wire******************/
logic clk;
logic rst;
//icache
logic [`CacheMemAddrBus]     o_inst_addr;
logic [`CacheMemByteBus]     o_inst_byte_en;
logic [`CacheMemDataBus]     o_inst_writedata;
logic                        o_inst_read;
logic                        o_inst_write;
logic [`CacheMemDataBus]     i_inst_readdata;
logic                        i_inst_readdata_valid;
logic                        i_inst_waitrequest;
//dcache
logic  [`CacheMemAddrBus]    o_data_addr;
logic  [`CacheMemByteBus]    o_data_byte_en;
logic  [`CacheMemDataBus]    o_data_writedata;
logic                        o_data_read;
logic                        o_data_write;
logic  [`CacheMemDataBus]    i_data_readdata;
logic                        i_data_readdata_valid;
logic                        i_data_waitrequest;
//jtag预留
logic  [`RegAddrBus]         jtag_reg_addr_i;   // jtag模块读、写寄存器的地址
logic  [`RegBus]             jtag_reg_data_i;       // jtag模块写寄存器数据
logic                        jtag_reg_we_i;                  // jtag模块写寄存器标志
logic  [`RegBus]             jtag_reg_data_o;      // jtag模块读取到的寄存器数据
logic                        jtag_halt_flag_i;               // jtag暂停标志
logic                        jtag_reset_flag_i;              // jtag复位PC标志
//总线预留
logic                        rib_hold_flag_i;                // 总线暂停标志
//外部中断预留
logic  [`INT_BUS]            int_i;                // 中断信号

rv32i u_rv32i(
    .clk                   (clk                   ),
    .rst                   (rst                  ),
    .o_inst_addr           (o_inst_addr           ),
    .o_inst_byte_en        (o_inst_byte_en        ),
    .o_inst_writedata      (o_inst_writedata      ),
    .o_inst_read           (o_inst_read           ),
    .o_inst_write          (o_inst_write          ),
    .i_inst_readdata       (i_inst_readdata       ),
    .i_inst_readdata_valid (i_inst_readdata_valid ),
    .i_inst_waitrequest    (i_inst_waitrequest    ),
    .o_data_addr           (o_data_addr           ),
    .o_data_byte_en        (o_data_byte_en        ),
    .o_data_writedata      (o_data_writedata      ),
    .o_data_read           (o_data_read           ),
    .o_data_write          (o_data_write          ),
    .i_data_readdata       (i_data_readdata       ),
    .i_data_readdata_valid (i_data_readdata_valid ),
    .i_data_waitrequest    (i_data_waitrequest    ),
    .jtag_reg_addr_i       (jtag_reg_addr_i       ),
    .jtag_reg_data_i       (jtag_reg_data_i       ),
    .jtag_reg_we_i         (jtag_reg_we_i         ),
    .jtag_reg_data_o       (jtag_reg_data_o       ),
    .jtag_halt_flag_i      (jtag_halt_flag_i      ),
    .jtag_reset_flag_i     (jtag_reset_flag_i     ),
    .rib_hold_flag_i       (rib_hold_flag_i       ),
    .int_i                 (int_i                 )
);
//clocking wizzard
initial begin
    clk = 0;
    forever begin
        #5 clk = ~clk;
    end
end
//reset enable:1 disable:0
initial begin
    rst = 1;
    jtag_reset_flag_i = 1;
    #30
    @(posedge clk);
    rst = 0;
    jtag_reset_flag_i = 0;
end
//VIP
integer i;
logic [127:0] i_mem [0:`RomNum];
//i 通道
initial begin
    $readmemh ("../sim/inst128.data", i_mem);
    fork 
        forever begin
            @(posedge clk);
            if(o_inst_write) begin
                i_mem[o_inst_addr[$clog2(`RomNum):2]] <= o_inst_writedata;
                i_inst_waitrequest <= 0;
            end
            if(o_inst_read) begin
                i_inst_readdata <= i_mem[o_inst_addr[$clog2(`RomNum):3]];
                i_inst_readdata_valid <= 1;
                i_inst_waitrequest <= 0;
            end else begin
                i_inst_waitrequest <= 0;
                i_inst_readdata_valid <= 0;
            end
        end

        forever begin
            @(posedge clk);
            if(o_data_write) begin
                i_mem[o_data_addr[$clog2(`RomNum):2]] <= o_data_writedata;
                i_data_waitrequest <= 0;
            end
            if(o_data_read) begin
                i_data_readdata <= i_mem[o_data_addr[$clog2(`RomNum):3]];
                i_data_readdata_valid <= 1;
                i_data_waitrequest <= 0;
            end else begin
                i_data_waitrequest <= 0;
                i_data_readdata_valid <= 0;
            end
        end
    join
end

initial begin
    $dumpfile("this.vcd");
    $dumpvars(0, quick_sim_core);
end

wire[`RegBus] x3  = u_rv32i.u_regs.regs_mem[3];
wire[`RegBus] x26 = u_rv32i.u_regs.regs_mem[26];
wire[`RegBus] x27 = u_rv32i.u_regs.regs_mem[27];
integer r;
initial begin
    wait(x26 == 32'b1)   // wait sim end, when x26 == 1
        #100
        if (x27 == 32'b1) begin
            $display("~~~~~~~~~~~~~~~~~~~ TEST_PASS ~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~ #####     ##     ####    #### ~~~~~~~~~");
            $display("~~~~~~~~~ #    #   #  #   #       #     ~~~~~~~~~");
            $display("~~~~~~~~~ #    #  #    #   ####    #### ~~~~~~~~~");
            $display("~~~~~~~~~ #####   ######       #       #~~~~~~~~~");
            $display("~~~~~~~~~ #       #    #  #    #  #    #~~~~~~~~~");
            $display("~~~~~~~~~ #       #    #   ####    #### ~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        end else begin
            $display("~~~~~~~~~~~~~~~~~~~ TEST_FAIL ~~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~~######    ##       #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#        #  #      #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#####   #    #     #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#       ######     #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#       #    #     #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#       #    #     #    ######~~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
            $display("fail testnum = %2d", x3);
            for (r = 0; r < 32; r = r + 1)
                $display("x%2d = 0x%x", r, u_rv32i.u_regs.regs_mem[r]);
        end
    $finish;
end
initial begin
    #50000
    $finish;
end
endmodule