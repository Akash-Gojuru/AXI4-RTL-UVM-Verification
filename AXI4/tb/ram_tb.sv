`timescale 1ns/1ps

module ram_tb;

    // Testbench signals
    logic        ACLK;
    logic        we;
    logic [7:0]  addr;
    logic [31:0] wdata;

    // DUT
    ram dut (
        .ACLK (ACLK),
        .we   (we),
        .addr (addr),
        .wdata(wdata)
    );

    // Clock generation
    always #5 ACLK <= ~ACLK;

    initial begin

        // Waveform dump
        $dumpfile("waves/ram.vcd");
        $dumpvars(0, ram_tb);

        // Initial values
        ACLK = 0;
        we   = 0;
        addr = 0;
        wdata = 0;

      
        #2;

        we    = 1;
        addr  = 8'h05;
        wdata = 32'hABCD1234;

        @(posedge ACLK);
        #1;

        $display("mem[5] = %h", dut.mem[5]);

        // Check result
        if (dut.mem[5] == 32'hABCD1234)
            $display("TEST 1 PASS");
        else
            $display("TEST 1 FAIL");

        
        @(negedge ACLK);

        addr  = 8'h0A;
        wdata = 32'h12345678;

        @(posedge ACLK);
        #1;

        $display("mem[10] = %h", dut.mem[10]);

        if (dut.mem[10] == 32'h12345678)
            $display("TEST 2 PASS");
        else
            $display("TEST 2 FAIL");

        
        @(negedge ACLK);

        addr  = 8'hFF;
        wdata = 32'hDEADBEEF;

        @(posedge ACLK);
        #1;

        $display("mem[255] = %h", dut.mem[255]);

        if (dut.mem[255] == 32'hDEADBEEF)
            $display("TEST 3 PASS");
        else
            $display("TEST 3 FAIL");

        
        @(negedge ACLK);

        we    = 0;
        addr  = 8'h05;
        wdata = 32'hFFFFFFFF;

        @(posedge ACLK);
        #1;

        $display("mem[5] after we=0 = %h", dut.mem[5]);

        if (dut.mem[5] == 32'hABCD1234)
            $display("TEST 4 PASS");
        else
            $display("TEST 4 FAIL");

        // End simulation
        #10;

        $display("Simulation finished.");
        $finish;

    end

endmodule
