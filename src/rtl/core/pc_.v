module pc_(
    input   wire                    clk,
    input   wire                    rst,
    //from ex->ctrl->this
    input   wire                    jump_flag_i,
    input   wire[`InstAddrBus]      jump_addr_i,
    //from ctrl
    input   wire [`Hold_Flag_Bus]   hold_flag_i,
    //to id, risc interconncet bus
    output  wire [`InstAddrBus]     inst_addr_o,
    output  wire [`InstBus]         inst_o,
    //from jtag
    input   wire                    jtag_reset_flag_i,
    // write to addr fifo
    output  reg [`InstAddrBus]      addr_fifo_w,
    input  wire                     addr_fifo_full,
    output reg                      addr_fifo_wen,
    output reg                      addr_fifo_rstn,
    // get inst from fifo
    input  wire                     inst_fifo_empty,
    input  wire [`InstBus]          inst_fifo_r,
    output reg                      inst_fifo_ren
);
reg [`InstAddrBus]      inst_addr_pp1,inst_addr_pp2;
reg                     inst_wait_proc;
reg [`InstBus]          inst_pp1,inst_pp2;
assign inst_addr_o  = (~hold_en)? inst_addr_pp1 :`ZeroWord;
assign inst_o       = (~hold_en)? inst_pp1      :`INST_NOP;
reg [`InstAddrBus]      jump_where;
wire hold_en = hold_flag_i >= `Hold_Pc;
reg  hold_en_pp1;
wire hold_en_posedge = hold_en & ~hold_en_pp1;
reg  jump_regs;
wire jump_posedge = jump_flag_i & ~jump_regs;
wire jump_negedge = ~jump_flag_i & jump_regs;
reg  read_en_wait;
always @(posedge clk ) begin
    if(rst|jtag_reset_flag_i) begin
        jump_regs <= 1'b0;
    end else begin
        jump_regs <= jump_flag_i;
    end
end
//没事干就往fifo里写目标地址，当hold时，依旧写，当jump时，清空已写的fifo，并重定向地址。
reg [`InstAddrBus] addr_fifo_w_pp1;
always @(posedge clk) begin
    if(rst|jtag_reset_flag_i) begin
        addr_fifo_w <= `ZeroWord - 'd4;
        addr_fifo_rstn <= 1;
        jump_where <= `ZeroWord;
    end else if(jump_posedge) begin
        addr_fifo_w <= jump_where;
        addr_fifo_rstn <= 0;
        jump_where <= jump_addr_i;
    end else if(jump_negedge) begin
        addr_fifo_w <= jump_where;
        addr_fifo_rstn <= 1;
        jump_where <= `ZeroWord;
    end else if(addr_fifo_wen) begin
        addr_fifo_w <= addr_fifo_w + 'd4;
        addr_fifo_rstn <= 1;
        jump_where <= `ZeroWord;
    end else begin
        addr_fifo_w <= addr_fifo_w;
        addr_fifo_rstn <= 1;
        jump_where <= `ZeroWord;
    end
end
assign addr_fifo_wen = ~addr_fifo_full;
reg [`InstAddrBus] inst_addr;
reg inst_fifo_ren_pp1,inst_fifo_ren_pp2;
always @(*) begin
    if(rst|jtag_reset_flag_i|hold_en|jump_flag_i) begin
        inst_fifo_ren = 0;
    end else if(~inst_fifo_empty && ~read_en_wait) begin
        inst_fifo_ren = 1;
    end else begin
        inst_fifo_ren = 0;
    end
end
always @(posedge clk) begin
    if(rst) begin
        inst_fifo_ren_pp1 <= 0;
        inst_fifo_ren_pp2 <= 0;
        hold_en_pp1       <= 0;
    end else begin
        inst_fifo_ren_pp1 <= inst_fifo_ren;
        inst_fifo_ren_pp2 <= inst_fifo_ren_pp1;
        hold_en_pp1       <= hold_en;
    end
end
always @(posedge clk) begin
    if(rst|jtag_reset_flag_i) begin
        inst_addr <= `ZeroWord;
        inst_addr_pp1 <= `ZeroWord;
        inst_addr_pp2 <= `ZeroWord;
        inst_pp1 <= `INST_NOP;
        inst_pp2 <= `INST_NOP;
        inst_wait_proc <= 1'b0;
        read_en_wait   <= 1'b0;
    end else if(jump_posedge) begin
        inst_addr <= inst_addr;
        inst_addr_pp1 <= `ZeroWord;
        inst_addr_pp2 <= `ZeroWord;
        inst_pp1 <= `INST_NOP;
        inst_pp2 <= `INST_NOP;
    end else if(jump_negedge) begin
        inst_addr <= jump_where;
        inst_addr_pp1 <= `ZeroWord;
        inst_addr_pp2 <= `ZeroWord;
        inst_pp1 <= `INST_NOP;
        inst_pp2 <= `INST_NOP;
    end else if(hold_en) begin
        if(inst_fifo_ren_pp2 && ~inst_fifo_ren_pp1 && inst_wait_proc) begin
            inst_addr <= inst_addr;
            inst_addr_pp1 <= inst_addr_pp2;
            inst_addr_pp2 <= inst_addr_pp2;
            inst_pp1 <= inst_pp1;
            inst_pp2 <= inst_pp2;
            inst_wait_proc <= 1'b0;
            read_en_wait   <= 1'b1;
        end else if(inst_fifo_ren_pp2 && ~inst_fifo_ren_pp1 && ~inst_wait_proc) begin
            inst_addr <= inst_addr;
            inst_addr_pp1 <= inst_addr_pp2;
            inst_addr_pp2 <= inst_addr_pp2;
            inst_pp1 <= inst_pp2;
            inst_pp2 <= inst_pp2;
        end else if(~inst_fifo_ren_pp2 && inst_fifo_ren_pp1) begin
            inst_addr <= inst_addr;
            inst_addr_pp1 <= inst_addr_pp1;
            inst_addr_pp2 <= inst_addr_pp1;
            inst_pp1 <= inst_pp1;
            inst_pp2 <= inst_pp1;
        end else if(inst_fifo_ren_pp2 && inst_fifo_ren_pp1) begin
            inst_addr <= inst_addr_pp1;
            inst_addr_pp1 <= inst_addr_pp2;
            inst_addr_pp2 <= inst_addr_pp2;
            inst_pp1 <= inst_pp2;
            inst_pp2 <= inst_pp1;
            inst_wait_proc <= 1'b1;
        end else begin
            inst_addr <= inst_addr;
            inst_addr_pp1 <= inst_addr_pp1;
            inst_addr_pp2 <= inst_addr_pp2;
            inst_pp1 <= inst_pp1;
            inst_pp2 <= inst_pp1;
        end
    end else if(inst_fifo_ren) begin
        inst_addr <= inst_addr + 'd4;
        inst_addr_pp1 <= inst_addr;
        inst_addr_pp2 <= inst_addr_pp1;
        inst_pp1 <= inst_fifo_r;
        inst_pp2 <= inst_pp1;
    end else if(read_en_wait)begin
        inst_addr <= inst_addr + 'd4;
        inst_addr_pp1 <= inst_addr;
        inst_addr_pp2 <= inst_addr_pp1;
        inst_pp1 <= inst_pp2;
        inst_pp2 <= inst_pp2;
        read_en_wait <= 1'b0;
    end else begin
        inst_addr <= inst_addr;
        inst_addr_pp1 <= inst_addr_pp1;
        inst_addr_pp2 <= inst_addr_pp1;
        inst_pp1 <= `INST_NOP;
        inst_pp2 <= inst_pp1;
    end
end
endmodule