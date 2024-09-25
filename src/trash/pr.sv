module test;
initial begin
    $display("A");
    #10 $display("B");
 fork
    $display("C");
    #50    $display("D");
    begin
    #30 $display("E");
    #10 $display("F");
    end
 join_any
    $display("G");
end
endmodule