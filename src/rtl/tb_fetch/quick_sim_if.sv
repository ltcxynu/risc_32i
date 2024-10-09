`ifndef SIM
`define SIM
`include "../core/rv32i_defines.v"
`include "../core/pc_.v"
`include "../core/fifo_.v"
`include "../core/fetch_cache.v"
`include "../core/pc_cache_core.v"

`include "../cache/simple_ram.v"
`include "../cache/4way_4word.v"
`endif
`timescale 1ns/1ns
module quick_sim_if;
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
logic                       jump_flag_i;
logic [`InstAddrBus]        jump_addr_i;
logic [`Hold_Flag_Bus]      hold_flag_i;
logic [`InstAddrBus]        inst_addr_o;
logic [`InstBus]            inst_o;
pc_cache_core u_pc_cache_core(
    .clk                   (clk                   ),
    .rst                   (rst                   ),
    .jtag_reset_flag_i     (jtag_reset_flag_i     ),
    .jump_flag_i           (jump_flag_i           ),
    .jump_addr_i           (jump_addr_i           ),
    .hold_flag_i           (hold_flag_i           ),
    .inst_addr_o           (inst_addr_o           ),
    .inst_o                (inst_o                ),
    .o_inst_addr           (o_inst_addr           ),
    .o_inst_byte_en        (o_inst_byte_en        ),
    .o_inst_writedata      (o_inst_writedata      ),
    .o_inst_read           (o_inst_read           ),
    .o_inst_write          (o_inst_write          ),
    .i_inst_readdata       (i_inst_readdata       ),
    .i_inst_readdata_valid (i_inst_readdata_valid ),
    .i_inst_waitrequest    (i_inst_waitrequest    )
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
    $readmemh ("../../../sim/inst128.data", i_mem);
    
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
end
initial begin
    #4000
    $finish;
end
initial begin
    $dumpfile("quick_sim_if.vcd");
    $dumpvars(0, quick_sim_if);
end
task set_jmp_hold(
input                       jump_flag,
input [`InstAddrBus]        jump_addr,
input [`Hold_Flag_Bus]      hold_flag
);
    jump_flag_i <= jump_flag;
    jump_addr_i <= jump_addr;
    hold_flag_i <= hold_flag;
endtask
initial begin
    set_jmp_hold(0,`ZeroWord,0);
    #100
    @(posedge clk);
    // set_jmp_hold(1,0'h00700193,0);
    @(posedge clk);
    set_jmp_hold(0,`ZeroWord,0);
    #400
    @(posedge clk);
    set_jmp_hold(0,`ZeroWord,1);
    @(posedge clk);
    set_jmp_hold(0,`ZeroWord,0);
    #105
    @(posedge clk);
    set_jmp_hold(1,0'h00000048,0);
    @(posedge clk);
    set_jmp_hold(0,`ZeroWord,0);
    #400
    @(posedge clk);
    set_jmp_hold(0,`ZeroWord,1);
    @(posedge clk);
    set_jmp_hold(0,`ZeroWord,0);
    #115
    @(posedge clk);
    set_jmp_hold(1,0'h000000c8,0);
    @(posedge clk);
    set_jmp_hold(0,`ZeroWord,0);
    #400
    @(posedge clk);
    set_jmp_hold(0,`ZeroWord,1);
    @(posedge clk);
    set_jmp_hold(0,`ZeroWord,0);
end
endmodule