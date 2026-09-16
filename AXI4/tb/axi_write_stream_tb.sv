`timescale 1ns/1ps

module axi_write_stream_tb;

    logic ACLK;
    logic ARESETn;

    // Master control
    logic        start;
    logic [31:0] start_address;
    logic [7:0]  burst_length;
    logic [2:0]  transfer_size;
    logic        done;

    // Input stream
    logic [31:0] s_data;
    logic [3:0]  s_strb;
    logic        s_valid;
    logic        s_ready;

    // AXI write address
    logic [31:0] AWADDR;
    logic [7:0]  AWLEN;
    logic [2:0]  AWSIZE;
    logic [1:0]  AWBURST;
    logic        AWVALID;
    logic        AWREADY;

    // AXI write data
    logic [31:0] WDATA;
    logic [3:0]  WSTRB;
    logic        WVALID;
    logic        WLAST;
    logic        WREADY;

    // AXI write response
    logic [1:0] BRESP;
    logic       BVALID;
    logic       BREADY;

    // RAM
    logic        ram_we;
    logic [3:0]  ram_wstrb;
    logic [7:0]  ram_addr;
    logic [31:0] ram_wdata;
    logic [31:0] ram_rdata;


    // Clock
    always #5 ACLK = ~ACLK;


    // Master
    axi_write_master master_inst (

        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .start(start),
        .start_address(start_address),
        .burst_length(burst_length),
        .transfer_size(transfer_size),
        .done(done),

        .s_data(s_data),
        .s_strb(s_strb),
        .s_valid(s_valid),
        .s_ready(s_ready),

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


    // Slave
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


    // RAM
    ram ram_inst (

        .ACLK(ACLK),

        .we(ram_we),
        .wstrb(ram_wstrb),
        .addr(ram_addr),
        .wdata(ram_wdata),
        .rdata(ram_rdata)

    );


    // Send one stream beat
    task send_data (
        input logic [31:0] value
    );

        begin

            @(negedge ACLK);

            s_data  = value;
            s_strb  = 4'b1111;
            s_valid = 1'b1;

            while (!(s_valid && s_ready)) begin
                @(posedge ACLK);
            end

            @(negedge ACLK);

            s_valid = 1'b0;

        end

    endtask


    initial begin

        $dumpfile("axi_write_stream.vcd");
        $dumpvars(0, axi_write_stream_tb);

        ACLK = 0;
        ARESETn = 0;

        start = 0;
        start_address = 0;
        burst_length = 0;
        transfer_size = 3'b010;

        s_data = 0;
        s_strb = 0;
        s_valid = 0;

        #20;

        ARESETn = 1;

        @(posedge ACLK);

        // 8-beat burst
        @(negedge ACLK);

        start_address = 32'h0000_0020;
        burst_length  = 8'd8;
        transfer_size = 3'b010;

        start = 1;

        @(negedge ACLK);

        start = 0;


        send_data(32'h1111_1111);
        send_data(32'h2222_2222);
        send_data(32'h3333_3333);
        send_data(32'h4444_4444);
        send_data(32'h5555_5555);
        send_data(32'h6666_6666);
        send_data(32'h7777_7777);
        send_data(32'h8888_8888);


        wait(done == 1);

        @(posedge ACLK);


        $display("");
        $display("==============================");
        $display("AXI WRITE STREAM TEST");
        $display("==============================");


        if (
            ram_inst.mem[8]  == 32'h1111_1111 &&
            ram_inst.mem[9]  == 32'h2222_2222 &&
            ram_inst.mem[10] == 32'h3333_3333 &&
            ram_inst.mem[11] == 32'h4444_4444 &&
            ram_inst.mem[12] == 32'h5555_5555 &&
            ram_inst.mem[13] == 32'h6666_6666 &&
            ram_inst.mem[14] == 32'h7777_7777 &&
            ram_inst.mem[15] == 32'h8888_8888
        ) begin

            $display("TEST PASSED");

        end
        else begin

            $display("TEST FAILED");

        end


        $display("RAM[8]  = %h", ram_inst.mem[8]);
        $display("RAM[9]  = %h", ram_inst.mem[9]);
        $display("RAM[10] = %h", ram_inst.mem[10]);
        $display("RAM[11] = %h", ram_inst.mem[11]);
        $display("RAM[12] = %h", ram_inst.mem[12]);
        $display("RAM[13] = %h", ram_inst.mem[13]);
        $display("RAM[14] = %h", ram_inst.mem[14]);
        $display("RAM[15] = %h", ram_inst.mem[15]);

        $display("");
        $display("AWLEN   = %0d", AWLEN);
        $display("AWSIZE  = %b", AWSIZE);
        $display("AWBURST = %b", AWBURST);
        $display("BRESP   = %b", BRESP);


        #20;

        $finish;

    end

endmodule