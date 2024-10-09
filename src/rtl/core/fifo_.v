module sync_fifo#(
    parameter                           DSIZE = 8                  ,
    parameter                           ASIZE = 7                   
)(
    input                               clk                        ,
    input                               rst_n                      ,
    input                               wr_en                      ,
    input              [DSIZE-1:0]      w_data                     ,
    input                               rd_en                      ,
    output             [DSIZE-1:0]      r_data                     ,
    output                              fifo_empty                 ,
    output                              fifo_full                   
);
localparam                              DEPTH = 1<<ASIZE           ;
reg                    [DSIZE-1:0] fifo_mem [0:DEPTH-1]                           ;
reg                    [ASIZE-1:0]      waddr,raddr                ;
reg                    [ASIZE:0]        fifo_cnt                   ;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        waddr <= 'd0;
    end else if(wr_en&~fifo_full)begin
        waddr <= waddr + 'd1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        raddr <= 'd0;
    end else if(rd_en&~fifo_empty)begin
        raddr <= raddr + 'd1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fifo_cnt <= 'd0;
    end else if(rd_en&~fifo_empty&~wr_en)begin
        fifo_cnt <= fifo_cnt - 'd1;
    end else if(wr_en&~fifo_full&~rd_en)begin
        fifo_cnt <= fifo_cnt + 'd1;
    end
end
assign fifo_full = fifo_cnt[ASIZE];
assign fifo_empty = fifo_cnt == 'd0;

always @(posedge clk)begin
    if(wr_en&~fifo_full&rst_n) begin
        fifo_mem[waddr] <= w_data;
    end
end
assign r_data = fifo_mem[raddr];
endmodule