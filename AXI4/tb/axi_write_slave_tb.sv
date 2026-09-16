`timescale 1ns/1ps

module axi_write_slave_tb;

    // ============================================================
    // Clock and Reset
    // ============================================================
    logic ACLK;
    logic ARESETn;

    // ============================================================
    // AXI Write Address Channel
    // ============================================================
    logic [31:0] AWADDR;
    logic        AWVALID;
    logic        AWREADY;

    // ============================================================
    // AXI Write Data Channel
    // ============================================================
    logic [31:0] WDATA;
    logic        WVALID;
    logic        WREADY;

    // ============================================================
    // AXI Write Response Channel
    // ============================================================
    logic [1:0]  BRESP;
    logic        BVALID;
    logic        BREADY;

    // ============================================================
    // RAM Interface
    // ============================================================
    logic        ram_we;
    logic [7:0]  ram_addr;
    logic [31:0] ram_wdata;


    // ============================================================
    // RAM
    // ============================================================
    ram memory (
        .ACLK  (ACLK),
        .we    (ram_we),
        .addr  (ram_addr),
        .wdata (ram_wdata)
    );


    // ============================================================
    // DUT
    // ============================================================
    axi_write_slave dut (
        .ACLK       (ACLK),
        .ARESETn    (ARESETn),

        .AWADDR     (AWADDR),
        .AWVALID    (AWVALID),
        .AWREADY    (AWREADY),

        .WDATA      (WDATA),
        .WVALID     (WVALID),
        .WREADY     (WREADY),

        .BRESP      (BRESP),
        .BVALID     (BVALID),
        .BREADY     (BREADY),

        .ram_we     (ram_we),
        .ram_addr   (ram_addr),
        .ram_wdata  (ram_wdata)
    );


    // ============================================================
    // Clock Generation
    // 10 ns clock period
    // ============================================================
    initial begin
        ACLK = 1'b0;

        forever begin
            #5 ACLK = ~ACLK;
        end
    end


    // ============================================================
    // Main Test
    // ============================================================
    initial begin

        // --------------------------------------------------------
        // Create VCD
        // --------------------------------------------------------
        $dumpfile("waves/axi_write_slave.vcd");
        $dumpvars(0, axi_write_slave_tb);


        // --------------------------------------------------------
        // Initial values
        // --------------------------------------------------------
        ARESETn = 1'b0;

        AWADDR  = 32'h00000000;
        AWVALID = 1'b0;

        WDATA   = 32'h00000000;
        WVALID  = 1'b0;

        BREADY  = 1'b0;


        // ========================================================
        // RESET
        // ========================================================

        $display("========================================");
        $display("STARTING TEST");
        $display("========================================");

        // Hold reset for 20 ns
        #20;

        ARESETn = 1'b1;

        $display("[%0t] RESET RELEASED", $time);


        // Wait for a falling edge before driving signals
        @(negedge ACLK);


        // ========================================================
        // WRITE ADDRESS CHANNEL
        // ========================================================

        $display("[%0t] SENDING ADDRESS", $time);

        AWADDR  = 32'h00000008;
        AWVALID = 1'b1;


        // Wait for actual clock edge where DUT sees
        // AWVALID && AWREADY
        @(posedge ACLK);

        while (!AWREADY) begin
            @(posedge ACLK);
        end


        $display("[%0t] ADDRESS HANDSHAKE DONE", $time);


        // Deassert VALID away from sampling edge
        @(negedge ACLK);

        AWVALID = 1'b0;


        // ========================================================
        // WRITE DATA CHANNEL
        // ========================================================

        $display("[%0t] SENDING DATA", $time);

        WDATA  = 32'h12345678;
        WVALID = 1'b1;


        // Wait for WREADY
        @(posedge ACLK);

        while (!WREADY) begin
            @(posedge ACLK);
        end


        $display("[%0t] DATA HANDSHAKE DONE", $time);


        // Deassert VALID
        @(negedge ACLK);

        WVALID = 1'b0;


        // ========================================================
        // WRITE RESPONSE CHANNEL
        // ========================================================

        $display("[%0t] WAITING FOR RESPONSE", $time);

        BREADY = 1'b1;


        // Wait for BVALID
        @(posedge ACLK);

        while (!BVALID) begin
            @(posedge ACLK);
        end


        $display("[%0t] RESPONSE HANDSHAKE DONE", $time);


        // Deassert BREADY
        @(negedge ACLK);

        BREADY = 1'b0;


        // Give RAM write time to complete
        @(posedge ACLK);


        // ========================================================
        // CHECK RESULTS
        // ========================================================

        $display("----------------------------------------");
        $display("CHECKING RESULTS");
        $display("----------------------------------------");

        $display("RAM address = %0d", ram_addr);
        $display("RAM[2]      = %h", memory.mem[2]);
        $display("Expected    = 12345678");
        $display("BRESP       = %b", BRESP);


        if (memory.mem[2] == 32'h12345678) begin

            $display("========================================");
            $display("TEST PASSED");
            $display("========================================");

        end
        else begin

            $display("========================================");
            $display("TEST FAILED");
            $display("========================================");

        end


        #20;

        $finish;

    end


    // ============================================================
    // TIMEOUT
    // ============================================================
    initial begin

        #1000;

        $display("========================================");
        $display("ERROR: TESTBENCH TIMEOUT");
        $display("========================================");

        $finish;

    end


    // ============================================================
    // DEBUG SIGNALS
    // ============================================================
    always @(posedge ACLK) begin

        $display(
            "[%0t] AWVALID=%b AWREADY=%b | WVALID=%b WREADY=%b | BVALID=%b BREADY=%b",
            $time,
            AWVALID,
            AWREADY,
            WVALID,
            WREADY,
            BVALID,
            BREADY
        );

    end

endmodule
