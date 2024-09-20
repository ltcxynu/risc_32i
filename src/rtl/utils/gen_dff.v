module gen_pipe_dff #(
    parameter DW = 32
)(
    input   wire            clk, 
    input   wire            rst,
    input   wire            hold_en,
    input   wire[DW-1:0]    din,
    input   wire[DW-1:0]    default_val,
    output  wire[DW-1:0]    qout
);
            reg [DW-1:0]    qout_r;
always@(posedge clk) begin
    if(!rst|hold_en) begin
        qout_r <= default_val;
    end else begin
        qout_r <= din;
    end
end

assign qout = qout_r;
endmodule