`timescale 1ns/1ps

module axi_write_system_tb;

    // Clock and reset
    logic ACLK;
    logic ARESETn;

    // Control to master
    logic        start;
    logic [31:0] address;
    logic [31:0] data;
    logic        done;

    // AXI Write Address Channel
    logic [31:0] AWADDR;
    logic        AWVALID;
    logic        AWREADY;

    // AXI Write Data Channel
    logic [31:0] WDATA;
    logic        WVALID;
    logic        WREADY;

    // AXI Write Response Channel
    logic [1:0]  BRESP;
    logic        BVALID;
    logic        BREADY;

    // RAM interface
    logic        ram_we;
    logic [7:0]  ram_addr;
    logic [31:0] ram_wdata;


    // Clock
    always #5 ACLK = ~ACLK;


    // -------------------------
    // AXI WRITE MASTER
    // -------------------------
    axi_write_master master_inst (

        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .start(start),
        .address(address),
        .data(data),
        .done(done),

        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),

        .WDATA(WDATA),
        .WVALID(WVALID),
        .WREADY(WREADY),

        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY)

    );


    // -------------------------
    // AXI WRITE SLAVE
    // -------------------------
    axi_write_slave slave_inst (

        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),

        .WDATA(WDATA),
        .WVALID(WVALID),
        .WREADY(WREADY),

        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY),

        .ram_we(ram_we),
        .ram_addr(ram_addr),
        .ram_wdata(ram_wdata)

    );


    // -------------------------
    // RAM
    // -------------------------
    ram ram_inst (

        .ACLK(ACLK),

        .we(ram_we),
        .addr(ram_addr),
        .wdata(ram_wdata)

    );


    // -------------------------
    // TEST
    // -------------------------
    initial begin

        $dumpfile("waves/axi_write_system.vcd");
        $dumpvars(0, axi_write_system_tb);

        // Initial values
        ACLK    = 0;
        ARESETn = 0;

        start   = 0;
        address = 0;
        data    = 0;


        // -------------------------
        // RESET
        // -------------------------
        #20;

        ARESETn = 1;

        @(posedge ACLK);


        // -------------------------
        // START WRITE
        // -------------------------
        @(negedge ACLK);

        address = 32'h0000_0008;
        data    = 32'h1234_5678;
        start   = 1;

        @(negedge ACLK);

        start = 0;


        // -------------------------
        // WAIT FOR MASTER
        // -------------------------
        wait(done == 1);

        $display("WRITE COMPLETE");


        // Give RAM time to update
        @(posedge ACLK);


        // -------------------------
        // CHECK RAM
        // -------------------------
        if (ram_inst.mem[2] == 32'h1234_5678) begin
            $display("TEST PASSED");
        end
        else begin
            $display("TEST FAILED");
        end

        $display("RAM[2] = %h", ram_inst.mem[2]);
        $display("BRESP  = %b", BRESP);


        #20;

        $finish;

    end

endmodule