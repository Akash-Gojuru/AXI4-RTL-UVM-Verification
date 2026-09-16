`timescale 1ns/1ps

module axi_read_burst_tb;

    logic ACLK;
    logic ARESETn;

    logic        start;
    logic [31:0] start_address;
    logic [7:0]  burst_length;
    logic        done;

    logic [31:0] data0;
    logic [31:0] data1;
    logic [31:0] data2;
    logic [31:0] data3;

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
    logic [7:0]  ram_addr;
    logic [31:0] ram_wdata;
    logic [31:0] ram_rdata;


    always #5 ACLK = ~ACLK;


    axi_read_burst_master master_inst (

        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .start(start),
        .start_address(start_address),
        .burst_length(burst_length),

        .data0(data0),
        .data1(data1),
        .data2(data2),
        .data3(data3),

        .done(done),

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
        .RREADY(RREADY)

    );


    axi_read_burst_slave slave_inst (

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
        .addr(ram_addr),
        .wdata(ram_wdata),
        .rdata(ram_rdata)

    );


    initial begin

        $dumpfile("waves/axi_read_burst.vcd");
        $dumpvars(0, axi_read_burst_tb);

        ACLK    = 0;
        ARESETn = 0;

        start         = 0;
        start_address = 0;
        burst_length  = 0;

        ram_we    = 0;
        ram_wdata = 0;

        #20;
        ARESETn = 1;

        @(posedge ACLK);

        // Preload RAM
        ram_inst.mem[2] = 32'h1111_1111;
        ram_inst.mem[3] = 32'h2222_2222;
        ram_inst.mem[4] = 32'h3333_3333;
        ram_inst.mem[5] = 32'h4444_4444;

        @(negedge ACLK);

        start_address = 32'h0000_0008;
        burst_length  = 8'd4;

        start = 1;

        @(negedge ACLK);

        start = 0;


        wait(done == 1);

        $display("BURST READ COMPLETE");


        if (
            data0 == 32'h1111_1111 &&
            data1 == 32'h2222_2222 &&
            data2 == 32'h3333_3333 &&
            data3 == 32'h4444_4444
        ) begin

            $display("TEST PASSED");

        end
        else begin

            $display("TEST FAILED");

        end


        $display("DATA0 = %h", data0);
        $display("DATA1 = %h", data1);
        $display("DATA2 = %h", data2);
        $display("DATA3 = %h", data3);

        $display("ARLEN   = %d", ARLEN);
        $display("ARSIZE  = %b", ARSIZE);
        $display("ARBURST = %b", ARBURST);
        $display("RRESP   = %b", RRESP);


        #20;
        $finish;

    end

endmodule