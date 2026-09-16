`timescale 1ns/1ps

module axi_write_error_tb;

    logic ACLK;
    logic ARESETn;

    // AXI AW
    logic [31:0] AWADDR;
    logic [7:0]  AWLEN;
    logic [2:0]  AWSIZE;
    logic [1:0]  AWBURST;
    logic        AWVALID;
    logic        AWREADY;

    // AXI W
    logic [31:0] WDATA;
    logic [3:0]  WSTRB;
    logic        WVALID;
    logic        WLAST;
    logic        WREADY;

    // AXI B
    logic [1:0] BRESP;
    logic       BVALID;
    logic       BREADY;

    // RAM
    logic        ram_we;
    logic [3:0]  ram_wstrb;
    logic [7:0]  ram_addr;
    logic [31:0] ram_wdata;
    logic [31:0] ram_rdata;


    always #5 ACLK = ~ACLK;


    axi_write_slave slave_inst (

        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .AWADDR(AWADDR),
        .AWLEN(AWLEN),
        .AWSIZE(AWSIZE),
        .AWBURST(AWBURST),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),

        .WDATA(WDATA),
        .WSTRB(WSTRB),
        .WVALID(WVALID),
        .WLAST(WLAST),
        .WREADY(WREADY),

        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY),

        .ram_we(ram_we),
        .ram_wstrb(ram_wstrb),
        .ram_addr(ram_addr),
        .ram_wdata(ram_wdata)

    );


    ram ram_inst (

        .ACLK(ACLK),

        .we(ram_we),
        .wstrb(ram_wstrb),
        .addr(ram_addr),
        .wdata(ram_wdata),
        .rdata(ram_rdata)

    );


    // =====================================
    // SEND ADDRESS
    // =====================================

    task send_aw (
        input logic [31:0] addr,
        input logic [7:0]  len,
        input logic [2:0]  size,
        input logic [1:0]  burst
    );

        begin

            @(negedge ACLK);

            AWADDR  = addr;
            AWLEN   = len;
            AWSIZE  = size;
            AWBURST = burst;
            AWVALID = 1'b1;

            while (!(AWVALID && AWREADY))
                @(posedge ACLK);

            @(negedge ACLK);

            AWVALID = 1'b0;

        end

    endtask


    // =====================================
    // SEND DATA
    // =====================================

    task send_w (
        input logic [31:0] value,
        input logic        last
    );

        begin

            @(negedge ACLK);

            WDATA  = value;
            WSTRB  = 4'b1111;
            WLAST  = last;
            WVALID = 1'b1;

            while (!(WVALID && WREADY))
                @(posedge ACLK);

            @(negedge ACLK);

            WVALID = 1'b0;
            WLAST  = 1'b0;

        end

    endtask


    // =====================================
    // CHECK RESPONSE
    // =====================================

    task check_slverr (
        input integer test_number
    );

        begin

            BREADY = 1'b1;

            wait(BVALID == 1'b1);

            if (BRESP == 2'b10)
                $display(
                    "TEST %0d PASSED: BRESP = SLVERR",
                    test_number
                );
            else
                $display(
                    "TEST %0d FAILED: BRESP = %b",
                    test_number,
                    BRESP
                );

            @(posedge ACLK);

            @(negedge ACLK);

            BREADY = 1'b0;

        end

    endtask


    initial begin

        $dumpfile("axi_write_error.vcd");
        $dumpvars(0, axi_write_error_tb);

        ACLK    = 0;
        ARESETn = 0;

        AWADDR  = 0;
        AWLEN   = 0;
        AWSIZE  = 0;
        AWBURST = 0;
        AWVALID = 0;

        WDATA  = 0;
        WSTRB  = 0;
        WVALID = 0;
        WLAST  = 0;

        BREADY = 0;


        #20;

        ARESETn = 1;

        @(posedge ACLK);


        // =================================
        // TEST 1
        // INVALID AWSIZE
        // =================================

        $display("");
        $display("TEST 1: INVALID AWSIZE");

        send_aw(
            32'h0000_0020,
            8'd0,
            3'b011,       // 8 bytes - unsupported
            2'b01
        );

        send_w(
            32'h1111_1111,
            1'b1
        );

        check_slverr(1);


        // =================================
        // TEST 2
        // INVALID AWBURST
        // =================================

        $display("");
        $display("TEST 2: INVALID AWBURST");

        send_aw(
            32'h0000_0030,
            8'd0,
            3'b010,
            2'b10        // WRAP - currently unsupported
        );

        send_w(
            32'h2222_2222,
            1'b1
        );

        check_slverr(2);


        // =================================
        // TEST 3
        // EARLY WLAST
        //
        // AWLEN = 3 means 4 beats expected.
        // We assert WLAST on beat 2.
        // =================================

        $display("");
        $display("TEST 3: EARLY WLAST");

        send_aw(
            32'h0000_0040,
            8'd3,
            3'b010,
            2'b01
        );

        send_w(
            32'hAAAA_0001,
            1'b0
        );

        send_w(
            32'hBBBB_0002,
            1'b1       // too early
        );

        check_slverr(3);


        // =================================
        // TEST 4
        // MISSING WLAST
        //
        // AWLEN = 1 means 2 beats expected.
        // Last beat arrives with WLAST = 0.
        // =================================

        $display("");
        $display("TEST 4: MISSING WLAST");

        send_aw(
            32'h0000_0050,
            8'd1,
            3'b010,
            2'b01
        );

        send_w(
            32'hCCCC_0001,
            1'b0
        );

        send_w(
            32'hDDDD_0002,
            1'b0       // WLAST missing
        );

        check_slverr(4);


        $display("");
        $display("==============================");
        $display("WRITE ERROR TESTS COMPLETE");
        $display("==============================");

        #20;

        $finish;

    end

endmodule