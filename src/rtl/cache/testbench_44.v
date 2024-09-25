`timescale 1ns / 1ps  
`define SIM
`include "simple_ram.v"
`include "4way_4word.v"

module tb_cache;  

    // Parameters  
    reg clk;  
    reg rst;  
    reg [24:0] i_p_addr;  
    reg [3:0] i_p_byte_en;  
    reg [31:0] i_p_writedata;  
    reg i_p_read;  
    reg i_p_write;  

    // Outputs  
    wire [31:0] o_p_readdata;  
    wire o_p_readdata_valid;  
    wire o_p_waitrequest;  

    wire [25:0] o_m_addr;  
    wire [3:0] o_m_byte_en;  
    wire [127:0] o_m_writedata;  
    wire o_m_read;  
    wire o_m_write;  
    reg [127:0] i_m_readdata;  
    reg i_m_readdata_valid;  
    reg i_m_waitrequest;  

    // Counting outputs  
    wire [31:0] cnt_r;  
    wire [31:0] cnt_w;  
    wire [31:0] cnt_hit_r;  
    wire [31:0] cnt_hit_w;  
    wire [31:0] cnt_wb_r;  
    wire [31:0] cnt_wb_w;  

    // Instantiate the module  
    cache uut (  
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

        integer i;  
    // Initial block for stimulus  
    initial begin  
        // Initialize inputs  
        rst = 1;  
        i_p_write = 0;  
        i_p_read = 0;  
        i_p_addr = 0;  
        i_p_writedata = 0;  
        i_p_byte_en = 4'b1111; // Enable all bytes  
        i_m_readdata_valid = 0; // Initially set to invalid  
        i_m_waitrequest = 0;  

        // Release reset  
        #10;  
        rst = 0;  

        // Random read/write operations  
        for (i = 0; i < 100; i = i + 1) begin  
            // Random address and data generation  
            i_p_addr = $urandom_range(0, 25'd255); // Random address within range  
            i_p_writedata = $urandom; // Random 32-bit data  

            // Randomly decide whether to read or write  
            if ($urandom_range(0, 1) == 0) begin  
                // Perform write operation  
                i_p_write = 1;  
                #10; // Simulate write delay  
                i_p_write = 0;  
                $display("Write Operation: Addr = %h, Data = %h", i_p_addr, i_p_writedata);  
            end else begin  
                // Perform read operation  
                i_p_read = 1;  

                // Fake memory return value for read operation (for simplicity, use same address)  
                i_m_readdata = {i_p_writedata, i_p_writedata, i_p_writedata, i_p_writedata}; // Repeat the write data as read data  
                i_m_readdata_valid = 1; // Indicating read data is valid  

                #10; // Wait for a clock cycle  
                i_p_read = 0; // End read operation  
                #10;  
                i_m_readdata_valid = 0; // Clear read data valid  
                $display("Read Operation: Addr = %h, Data = %h", i_p_addr, o_p_readdata);  
            end  

            #10; // Wait before next operation  
        end  

        // Final results  
        $display("Count Read: %d", cnt_r);  
        $display("Count Write: %d", cnt_w);  
        $display("Count Hit Read: %d", cnt_hit_r);  
        $display("Count Hit Write: %d", cnt_hit_w);  
        $display("Count Write Back Read: %d", cnt_wb_r);  
        $display("Count Write Back Write: %d", cnt_wb_w);  

        // Finish simulation  
        $finish;  
    end  

initial begin
    $dumpfile("this.vcd");
    $dumpvars(0, uut);
end

endmodule