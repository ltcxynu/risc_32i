module pc(
    input wire clk,
    input wire rst,
    //from ex->ctrl->this
    input wire jump_flag_i,
    input wire[`InstAddrBus] jump_addr_i,
    //from ctrl
    input wire [`Hold_Flag_Bus] hold_flag_i,
    //to id, risc interconncet bus
    output reg [`InstAddrBus] pc_o,
    //from jtag
    input wire jtag_reset_flag_i
);
always@(posedge clk) begin
    if(rst|jtag_reset_flag_i) begin
        pc_o <= `ZeroWord;
    end else if(jump_flag_i) begin
        pc_o <= jump_addr_i;
    end else if(hold_flag_i > `Hold_Pc) begin
        pc_o <= pc_o;
    end else begin
        pc_o <= pc_o + 32'd4;
    end
end

endmodule