`timescale 1ns/1ps

module axi_write_burst_tb;


    // =====================================
    // CLOCK / RESET
    // =====================================

    logic ACLK;

    logic ARESETn;


    // =====================================
    // MASTER CONTROL
    // =====================================

    logic start;

    logic [31:0] start_address;

    logic [7:0] burst_length;

    logic [3:0] write_strobe;


    logic [31:0] data0;
    logic [31:0] data1;
    logic [31:0] data2;
    logic [31:0] data3;


    logic done;


    // =====================================
    // AXI WRITE ADDRESS
    // =====================================

    logic [31:0] AWADDR;

    logic [7:0] AWLEN;

    logic [2:0] AWSIZE;

    logic [1:0] AWBURST;

    logic AWVALID;

    logic AWREADY;


    // =====================================
    // AXI WRITE DATA
    // =====================================

    logic [31:0] WDATA;

    logic [3:0] WSTRB;

    logic WVALID;

    logic WLAST;

    logic WREADY;


    // =====================================
    // AXI WRITE RESPONSE
    // =====================================

    logic [1:0] BRESP;

    logic BVALID;

    logic BREADY;


    // =====================================
    // RAM
    // =====================================

    logic ram_we;

    logic [3:0] ram_wstrb;

    logic [7:0] ram_addr;

    logic [31:0] ram_wdata;

    logic [31:0] ram_rdata;


    // =====================================
    // CLOCK
    // =====================================

    always #5 ACLK = ~ACLK;


    // =====================================
    // MASTER
    // =====================================

    axi_write_burst_master master_inst (

        .ACLK(ACLK),

        .ARESETn(ARESETn),


        .start(start),

        .start_address(start_address),

        .burst_length(burst_length),

        .write_strobe(write_strobe),


        .data0(data0),

        .data1(data1),

        .data2(data2),

        .data3(data3),


        .done(done),


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

        .BREADY(BREADY)

    );


    // =====================================
    // SLAVE
    // =====================================

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


    // =====================================
    // RAM
    // =====================================

    ram ram_inst (

        .ACLK(ACLK),

        .we(ram_we),

        .wstrb(ram_wstrb),

        .addr(ram_addr),

        .wdata(ram_wdata),

        .rdata(ram_rdata)

    );


    // =====================================
    // TEST
    // =====================================

    initial begin


        $dumpfile("waves/axi_write_burst.vcd");

        $dumpvars(0, axi_write_burst_tb);


        // ---------------------------------
        // INITIAL VALUES
        // ---------------------------------

        ACLK = 0;

        ARESETn = 0;


        start = 0;

        start_address = 0;

        burst_length = 0;

        write_strobe = 4'b0000;


        data0 = 0;

        data1 = 0;

        data2 = 0;

        data3 = 0;


        // ---------------------------------
        // RESET
        // ---------------------------------

        #20;

        ARESETn = 1;


        @(posedge ACLK);


        // =================================
        // TEST 1
        // 4-BEAT FULL-WORD BURST
        // =================================

        $display("");
        $display("==============================");
        $display("TEST 1: FULL 4-BEAT BURST");
        $display("==============================");


        @(negedge ACLK);


        start_address = 32'h0000_0008;

        burst_length = 8'd4;


        write_strobe = 4'b1111;


        data0 = 32'h1111_1111;

        data1 = 32'h2222_2222;

        data2 = 32'h3333_3333;

        data3 = 32'h4444_4444;


        start = 1;


        @(negedge ACLK);


        start = 0;


        wait(done == 1);


        // Allow final RAM write to complete
        @(posedge ACLK);


        if (

            ram_inst.mem[2] == 32'h1111_1111 &&

            ram_inst.mem[3] == 32'h2222_2222 &&

            ram_inst.mem[4] == 32'h3333_3333 &&

            ram_inst.mem[5] == 32'h4444_4444

        ) begin

            $display("TEST 1 PASSED");

        end

        else begin

            $display("TEST 1 FAILED");

        end


        $display("RAM[2] = %h", ram_inst.mem[2]);

        $display("RAM[3] = %h", ram_inst.mem[3]);

        $display("RAM[4] = %h", ram_inst.mem[4]);

        $display("RAM[5] = %h", ram_inst.mem[5]);


        $display("AWLEN   = %0d", AWLEN);

        $display("AWSIZE  = %b", AWSIZE);

        $display("AWBURST = %b", AWBURST);

        $display("BRESP   = %b", BRESP);


        // =================================
        // TEST 2
        // WSTRB PARTIAL WRITE
        // =================================

        $display("");
        $display("==============================");
        $display("TEST 2: WSTRB PARTIAL WRITE");
        $display("==============================");


        // Initial value
        ram_inst.mem[10] = 32'hAAAA_AAAA;


        @(negedge ACLK);


        // Byte address 40 = RAM[10]
        start_address = 32'h0000_0028;


        // One beat
        burst_length = 8'd1;


        // Write only bottom two bytes
        write_strobe = 4'b0011;


        data0 = 32'h1234_5678;

        data1 = 0;

        data2 = 0;

        data3 = 0;


        start = 1;


        @(negedge ACLK);


        start = 0;


        wait(done == 1);


        @(posedge ACLK);


        if (ram_inst.mem[10] == 32'hAAAA_5678) begin

            $display("TEST 2 PASSED");

        end

        else begin

            $display("TEST 2 FAILED");

        end


        $display(
            "RAM[10] = %h",
            ram_inst.mem[10]
        );


        $display(
            "EXPECTED = AAAA5678"
        );


        $display(
            "WSTRB = %b",
            WSTRB
        );


        $display(
            "BRESP = %b",
            BRESP
        );


        // =================================
        // FINAL
        // =================================

        #20;


        $display("");
        $display("==============================");
        $display("SIMULATION COMPLETE");
        $display("==============================");


        $finish;


    end


endmodule