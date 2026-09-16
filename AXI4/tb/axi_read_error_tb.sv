`timescale 1ns/1ps

module axi_read_error_tb;

    logic ACLK;
    logic ARESETn;

    // AXI AR
    logic [31:0] ARADDR;
    logic [7:0]  ARLEN;
    logic [2:0]  ARSIZE;
    logic [1:0]  ARBURST;
    logic        ARVALID;
    logic        ARREADY;

    // AXI R
    logic [31:0] RDATA;
    logic [1:0]  RRESP;
    logic        RVALID;
    logic        RLAST;
    logic        RREADY;

    // RAM
    logic        ram_we;
    logic [3:0]  ram_wstrb;
    logic [7:0]  ram_addr;
    logic [31:0] ram_wdata;
    logic [31:0] ram_rdata;


    always #5 ACLK = ~ACLK;


    axi_read_slave slave_inst (

        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .ARADDR(ARADDR),
        .ARLEN(ARLEN),
        .ARSIZE(ARSIZE),
        .ARBURST(ARBURST),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),

        .RDATA(RDATA),
        .RRESP(RRESP),
        .RVALID(RVALID),
        .RLAST(RLAST),
        .RREADY(RREADY),

        .ram_addr(ram_addr),
        .ram_rdata(ram_rdata)

    );


    ram ram_inst (

        .ACLK(ACLK),

        .we(ram_we),
        .wstrb(ram_wstrb),

        .addr(ram_addr),
        .wdata(ram_wdata),

        .rdata(ram_rdata)

    );


    task send_ar (
        input logic [31:0] addr,
        input logic [7:0]  len,
        input logic [2:0]  size,
        input logic [1:0]  burst
    );

        begin

            @(negedge ACLK);

            ARADDR  = addr;
            ARLEN   = len;
            ARSIZE  = size;
            ARBURST = burst;
            ARVALID = 1'b1;

            while (!(ARVALID && ARREADY))
                @(posedge ACLK);

            @(negedge ACLK);

            ARVALID = 1'b0;

        end

    endtask


    task check_read_slverr (
    input integer test_number
);

    begin

        RREADY = 1'b1;

        // Wait for response
        while (!RVALID) begin
            @(posedge ACLK);
        end


        if (RRESP == 2'b10)
            $display(
                "TEST %0d PASSED: RRESP = SLVERR",
                test_number
            );
        else
            $display(
                "TEST %0d FAILED: RRESP = %b",
                test_number,
                RRESP
            );


        // RVALID && RREADY handshake
        @(posedge ACLK);


        @(negedge ACLK);

        RREADY = 1'b0;


        // Slave should return ARREADY
        while (!ARREADY) begin
            @(posedge ACLK);
        end

    end

endtask

    initial begin

        $dumpfile("axi_read_error.vcd");
        $dumpvars(0, axi_read_error_tb);

        ACLK    = 0;
        ARESETn = 0;

        ARADDR  = 0;
        ARLEN   = 0;
        ARSIZE  = 0;
        ARBURST = 0;
        ARVALID = 0;

        RREADY = 0;

        ram_we    = 0;
        ram_wstrb = 0;
        ram_wdata = 0;


        #20;

        ARESETn = 1;

        @(posedge ACLK);


        // Preload some data
        ram_inst.mem[8] = 32'h1234_5678;


        // =================================
        // TEST 1
        // INVALID ARSIZE
        // =================================

        $display("");
        $display("TEST 1: INVALID ARSIZE");

        send_ar(
            32'h0000_0020,
            8'd0,
            3'b011,       // 8-byte transfer unsupported
            2'b01
        );

        check_read_slverr(1);


        // =================================
        // TEST 2
        // INVALID ARBURST
        // =================================

        $display("");
        $display("TEST 2: INVALID ARBURST");

        send_ar(
            32'h0000_0020,
            8'd0,
            3'b010,
            2'b10        // WRAP unsupported
        );

        check_read_slverr(2);


        $display("");
        $display("==============================");
        $display("READ ERROR TESTS COMPLETE");
        $display("==============================");


        #20;

        $finish;

    end

endmodule