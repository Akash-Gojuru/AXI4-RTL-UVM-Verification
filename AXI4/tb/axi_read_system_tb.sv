`timescale 1ns/1ps

module axi_read_system_tb;

    logic ACLK;
    logic ARESETn;

    // Master control
    logic        start;
    logic [31:0] address;
    logic [31:0] data_out;
    logic        done;

    // AXI Read Address Channel
    logic [31:0] ARADDR;
    logic        ARVALID;
    logic        ARREADY;

    // AXI Read Data Channel
    logic [31:0] RDATA;
    logic [1:0]  RRESP;
    logic        RVALID;
    logic        RREADY;

    // RAM
    logic        ram_we;
    logic [7:0]  ram_addr;
    logic [31:0] ram_wdata;
    logic [31:0] ram_rdata;


    always #5 ACLK = ~ACLK;


    axi_read_master master_inst (

        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .start(start),
        .address(address),

        .data_out(data_out),
        .done(done),

        .ARADDR(ARADDR),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),

        .RDATA(RDATA),
        .RRESP(RRESP),
        .RVALID(RVALID),
        .RREADY(RREADY)

    );


    axi_read_slave slave_inst (

        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .ARADDR(ARADDR),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),

        .RDATA(RDATA),
        .RRESP(RRESP),
        .RVALID(RVALID),
        .RREADY(RREADY),

        .ram_addr(ram_addr),
        .ram_rdata(ram_rdata)

    );


    ram ram_inst (

        .ACLK(ACLK),

        .we(ram_we),
        .addr(ram_addr),
        .wdata(ram_wdata),

        .rdata(ram_rdata)

    );


    initial begin

        $dumpfile("waves/axi_read_system.vcd");
        $dumpvars(0, axi_read_system_tb);

        ACLK    = 0;
        ARESETn = 0;

        start   = 0;
        address = 0;

        ram_we    = 0;
        ram_wdata = 0;

        #20;

        ARESETn = 1;

        @(posedge ACLK);


        // Preload RAM
        ram_inst.mem[2] = 32'h1234_5678;


        // Start read
        @(negedge ACLK);

        address = 32'h0000_0008;
        start   = 1;

        @(negedge ACLK);

        start = 0;


        // Wait for master to finish
        wait(done == 1);

        $display("READ COMPLETE");


        if (data_out == 32'h1234_5678) begin
            $display("TEST PASSED");
        end
        else begin
            $display("TEST FAILED");
        end

        $display("DATA OUT = %h", data_out);
        $display("RRESP    = %b", RRESP);


        #20;

        $finish;

    end

endmodule