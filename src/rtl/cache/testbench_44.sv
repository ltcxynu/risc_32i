`timescale 1ns / 1ns  
`define SIM 1
`include "simple_ram.v"
`include "4way_4word.v"
`define READ_ENABLE  1'b1
`define READ_DISABLE 1'b0
`define WRITE_ENABLE  1'b1
`define WRITE_DISABLE 1'b0
module tb_cache;  

    // Parameters  
    logic clk;  
    logic rst;  
    logic [24:0] i_p_addr;  
    logic [3:0] i_p_byte_en;  
    logic [31:0] i_p_writedata;  
    logic i_p_read;  
    logic i_p_write;  

    // Outputs  
    logic [31:0] o_p_readdata;  
    logic o_p_readdata_valid;  
    logic o_p_waitrequest;  

    logic [25:0] o_m_addr;  
    logic [3:0] o_m_byte_en;  
    logic [127:0] o_m_writedata;  
    logic o_m_read;  
    logic o_m_write;  
    logic [127:0] i_m_readdata;  
    logic i_m_readdata_valid;  
    logic i_m_waitrequest;  

    // Counting outputs  
    logic [31:0] cnt_r;  
    logic [31:0] cnt_w;  
    logic [31:0] cnt_hit_r;  
    logic [31:0] cnt_hit_w;  
    logic [31:0] cnt_wb_r;  
    logic [31:0] cnt_wb_w;  
    logic [31:0] data_in;
    logic [24:0] addr_in;
    // Instantiate the module  
    cache #(
        .cache_index(2)
    )uut (  
        .clk(clk),  
        .rst(rst),  
        .i_p_addr(i_p_addr),  
        .i_p_byte_en(i_p_byte_en),  
        .i_p_writedata(i_p_writedata),  
        .i_p_read(i_p_read),  
        .i_p_write(i_p_write),  
        .o_p_readdata(o_p_readdata),  
        .o_p_readdata_valid(o_p_readdata_valid),  
        .o_p_waitrequest(o_p_waitrequest),  
        .o_m_addr(o_m_addr),  
        .o_m_byte_en(o_m_byte_en),  
        .o_m_writedata(o_m_writedata),  
        .o_m_read(o_m_read),  
        .o_m_write(o_m_write),  
        .i_m_readdata(i_m_readdata),  
        .i_m_readdata_valid(i_m_readdata_valid),  
        .i_m_waitrequest(i_m_waitrequest),  
        .cnt_r(cnt_r),  
        .cnt_w(cnt_w),  
        .cnt_hit_r(cnt_hit_r),  
        .cnt_hit_w(cnt_hit_w),  
        .cnt_wb_r(cnt_wb_r),  
        .cnt_wb_w(cnt_wb_w)  
    );  

    // Clock generation  
    initial begin  
        clk = 0;  
        forever #5 clk = ~clk; // 100 MHz clock  
    end  

    // Initial block for stimulus  
    /*initial begin  
        // Initialize inputs  
        rst = 1;
        #100
        rst = 0;
        data_in <= 32'h0;
        addr_in <= 25'h0;

        @(posedge clk);
        if(o_p_waitrequest) begin
            @(negedge o_p_waitrequest);
            @(posedge clk);
        end
        data_in = data_in + 32'h1;
        addr_in = {1'b0,22'd0,2'b01};
        access_memory(addr_in,data_in,4'hf,`READ_DISABLE,`WRITE_ENABLE); 

        @(posedge clk);
        if(o_p_waitrequest) begin
            @(negedge o_p_waitrequest);
            @(posedge clk);
        end
        data_in = data_in + 32'h1;
        addr_in = {1'b1,22'd10192,2'b01};
        access_memory(addr_in,data_in,4'hf,`READ_DISABLE,`WRITE_ENABLE); 

        @(posedge clk);
        if(o_p_waitrequest) begin
            @(negedge o_p_waitrequest);
            @(posedge clk);
        end
        data_in = data_in + 32'h1;
        addr_in = {1'b0,22'd70947,2'b01};
        access_memory(addr_in,data_in,4'hf,`READ_DISABLE,`WRITE_ENABLE); 

        #100
        // Final results  
        $display("Count Read: %d", cnt_r);  
        $display("Count Write: %d", cnt_w);  
        $display("Count Hit Read: %d", cnt_hit_r);  
        $display("Count Hit Write: %d", cnt_hit_w);  
        $display("Count Write Back Read: %d", cnt_wb_r);  
        $display("Count Write Back Write: %d", cnt_wb_w);  
        #50
        $finish;  
        // Finish simulation  
    end*/  
    initial begin  
        // Initialize inputs  
        rst = 1;
        #100
        rst = 0;
        data_in <= 32'h0;
        addr_in <= 25'h0;
        assert(rst == 1'b0);
        repeat(1000) begin
            repeat(4) begin
                @(posedge clk);
                if(o_p_waitrequest) begin
                    @(negedge o_p_waitrequest);
                    @(posedge clk);
                end
                access_memory(addr_in,data_in,4'hf,`READ_DISABLE,`WRITE_ENABLE); 
                data_in <= data_in + 32'h1;
                addr_in <= addr_in + {24'h0000_00,1'b1};
            end
            @(posedge clk);
            if(o_p_waitrequest) begin
                @(negedge o_p_waitrequest);
                @(posedge clk);
            end
            addr_in <= addr_in + {24'h0010_00,1'b0};
            access_memory(addr_in,32'h0,4'h0,`READ_DISABLE,`WRITE_DISABLE); 
        end
        addr_in = {1'b0,24'h0A0000};
        repeat(300) begin
            @(posedge clk);
            if(o_p_waitrequest) begin
                @(negedge o_p_waitrequest);
                @(posedge clk);
            end
            addr_in = addr_in - 25'h1;
            access_memory(addr_in,data_in,4'hf,`READ_ENABLE,`WRITE_DISABLE); 
        end
        addr_in <= 25'h0;
        repeat(300) begin
            @(posedge clk);
            if(o_p_waitrequest) begin
                @(negedge o_p_waitrequest);
                @(posedge clk);
            end
            addr_in = addr_in + 25'h1;
            access_memory(addr_in,data_in,4'hf,`READ_ENABLE,`WRITE_DISABLE); 
        end
        #100
        // Final results  
        $display("Count Read: %d", cnt_r);  
        $display("Count Write: %d", cnt_w);  
        $display("Count Hit Read: %d", cnt_hit_r);  
        $display("Count Hit Write: %d", cnt_hit_w);  
        $display("Count Write Back Read: %d", cnt_wb_r);  
        $display("Count Write Back Write: %d", cnt_wb_w);  
        #50
        $finish;  
        // Finish simulation  
    end
initial begin
    $dumpfile("this.vcd");
    $dumpvars(0, uut);
end
//VIP
logic [127:0] mem [0:63];
initial begin
    forever begin
    @(posedge clk);
    if(o_m_write) begin
        mem[o_m_addr[5:0]] <= o_m_writedata;
        i_m_waitrequest <= 0;
    end
    if(o_m_read) begin
        i_m_readdata <= mem[o_m_addr[5:0]];
        i_m_readdata_valid <= 1;
        i_m_waitrequest <= 0;
    end else begin
        i_m_waitrequest <= 0;
        i_m_readdata_valid <= 0;
    end
    end
end

//endVIP
task access_memory (  
        input logic [23:0] address,     // 24 位地址  
        input logic [31:0] data,        // 32 位数据  
        input logic [3:0] mask,         // 4 位掩码  
        input logic read_enable,         // 读信号  
        input logic write_enable         // 写信号  
    );  
    i_p_addr        <= address;
    i_p_byte_en     <= mask;
    i_p_writedata   <= data;
    i_p_read        <= read_enable;
    i_p_write       <= write_enable;
endtask  

endmodule
