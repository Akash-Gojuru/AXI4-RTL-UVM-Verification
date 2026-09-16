`timescale 1ns/1ps

module axi_read_stream_tb;

    logic ACLK;
    logic ARESETn;

    // Master control
    logic        start;
    logic [31:0] start_address;
    logic [7:0]  burst_length;
    logic [2:0]  transfer_size;
    logic        done;

    // Output stream
    logic [31:0] m_data;
    logic        m_valid;
    logic        m_last;
    logic        m_ready;

    // AXI read address
    logic [31:0] ARADDR;
    logic [7:0]  ARLEN;
    logic [2:0]  ARSIZE;
    logic [1:0]  ARBURST;
    logic        ARVALID;
    logic        ARREADY;

    // AXI read data
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

    integer count;

    logic [31:0] received [0:7];


    // Clock
    always #5 ACLK = ~ACLK;


    // Master
    axi_read_master master_inst (

        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .start(start),
        .start_address(start_address),
        .burst_length(burst_length),
        .transfer_size(transfer_size),
        .done(done),

        .m_data(m_data),
        .m_valid(m_valid),
        .m_last(m_last),
        .m_ready(m_ready),

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


    // Slave
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


    // RAM
    ram ram_inst (

        .ACLK(ACLK),

        .we(ram_we),
        .wstrb(ram_wstrb),
        .addr(ram_addr),
        .wdata(ram_wdata),
        .rdata(ram_rdata)

    );


    // Capture stream output
    always @(posedge ACLK) begin

        if (m_valid && m_ready) begin

            received[count] <= m_data;

            count <= count + 1;

        end

    end


    initial begin

        $dumpfile("axi_read_stream.vcd");
        $dumpvars(0, axi_read_stream_tb);

        ACLK = 0;
        ARESETn = 0;

        start = 0;
        start_address = 0;
        burst_length = 0;
        transfer_size = 3'b010;

        m_ready = 1'b1;

        ram_we = 1'b0;
        ram_wstrb = 4'b0000;
        ram_wdata = 32'b0;

        count = 0;


        #20;

        ARESETn = 1;

        @(posedge ACLK);


        // Preload RAM
        ram_inst.mem[8]  = 32'h1111_1111;
        ram_inst.mem[9]  = 32'h2222_2222;
        ram_inst.mem[10] = 32'h3333_3333;
        ram_inst.mem[11] = 32'h4444_4444;

        ram_inst.mem[12] = 32'h5555_5555;
        ram_inst.mem[13] = 32'h6666_6666;
        ram_inst.mem[14] = 32'h7777_7777;
        ram_inst.mem[15] = 32'h8888_8888;


        // Start 8-beat read
        @(negedge ACLK);

        start_address = 32'h0000_0020;
        burst_length  = 8'd8;
        transfer_size = 3'b010;

        start = 1'b1;

        @(negedge ACLK);

        start = 1'b0;


        wait(done == 1'b1);

        @(posedge ACLK);


        $display("");
        $display("==============================");
        $display("AXI READ STREAM TEST");
        $display("==============================");


        if (
            received[0] == 32'h1111_1111 &&
            received[1] == 32'h2222_2222 &&
            received[2] == 32'h3333_3333 &&
            received[3] == 32'h4444_4444 &&
            received[4] == 32'h5555_5555 &&
            received[5] == 32'h6666_6666 &&
            received[6] == 32'h7777_7777 &&
            received[7] == 32'h8888_8888
        ) begin

            $display("TEST PASSED");

        end
        else begin

            $display("TEST FAILED");

        end


        $display("DATA[0] = %h", received[0]);
        $display("DATA[1] = %h", received[1]);
        $display("DATA[2] = %h", received[2]);
        $display("DATA[3] = %h", received[3]);
        $display("DATA[4] = %h", received[4]);
        $display("DATA[5] = %h", received[5]);
        $display("DATA[6] = %h", received[6]);
        $display("DATA[7] = %h", received[7]);

        $display("");
        $display("ARLEN   = %0d", ARLEN);
        $display("ARSIZE  = %b", ARSIZE);
        $display("ARBURST = %b", ARBURST);
        $display("RRESP   = %b", RRESP);
        $display("BEATS   = %0d", count);


        if (count == 8)
            $display("BEAT COUNT PASSED");
        else
            $display("BEAT COUNT FAILED");


        #20;

        $finish;

    end

endmodule