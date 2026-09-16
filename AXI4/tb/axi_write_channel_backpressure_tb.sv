`timescale 1ns/1ps

module axi_write_channel_backpressure_tb;

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

    // AXI AW
    logic [31:0] AWADDR;
    logic [7:0]  AWLEN;
    logic [2:0]  AWSIZE;
    logic [1:0]  AWBURST;

    logic AWVALID_master;
    logic AWVALID_slave;

    logic AWREADY_master;
    logic AWREADY_slave;

    logic allow_aw;

    // AXI W
    logic [31:0] WDATA;
    logic [3:0]  WSTRB;
    logic        WVALID;
    logic        WLAST;
    logic        WREADY;

    // AXI B
    logic [1:0] BRESP;
    logic       BVALID_master;
    logic       BVALID_slave;

    logic       BREADY_master;
    logic       BREADY_slave;

    logic allow_b;

    // RAM
    logic        ram_we;
    logic [3:0]  ram_wstrb;
    logic [7:0]  ram_addr;
    logic [31:0] ram_wdata;
    logic [31:0] ram_rdata;


    always #5 ACLK = ~ACLK;


    // =====================================
    // AW BACKPRESSURE GATE
    // =====================================

    assign AWVALID_slave =
        AWVALID_master && allow_aw;

    assign AWREADY_master =
        AWREADY_slave && allow_aw;


    // =====================================
    // B BACKPRESSURE GATE
    // =====================================

    assign BVALID_master =
        BVALID_slave && allow_b;

    assign BREADY_slave =
        BREADY_master && allow_b;


    // =====================================
    // MASTER
    // =====================================

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
        .AWVALID(AWVALID_master),
        .AWREADY(AWREADY_master),

        .WDATA(WDATA),
        .WSTRB(WSTRB),
        .WVALID(WVALID),
        .WLAST(WLAST),
        .WREADY(WREADY),

        .BRESP(BRESP),
        .BVALID(BVALID_master),
        .BREADY(BREADY_master)

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
        .AWVALID(AWVALID_slave),
        .AWREADY(AWREADY_slave),

        .WDATA(WDATA),
        .WSTRB(WSTRB),
        .WVALID(WVALID),
        .WLAST(WLAST),
        .WREADY(WREADY),

        .BRESP(BRESP),
        .BVALID(BVALID_slave),
        .BREADY(BREADY_slave),

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
// AXI READ ASSERTIONS
// =====================================

axi_read_assertions read_assertions_inst (

    .ACLK(ACLK),
    .ARESETn(ARESETn),

    .ARADDR(ARADDR),
    .ARLEN(ARLEN),
    .ARSIZE(ARSIZE),
    .ARBURST(ARBURST),

    .ARVALID(ARVALID_master),
    .ARREADY(ARREADY_master),

    .RDATA(RDATA),
    .RRESP(RRESP),

    .RVALID(RVALID_slave),
    .RLAST(RLAST),
    .RREADY(RREADY_slave)

);
    // =====================================
    // SEND ONE DATA BEAT
    // =====================================

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


    // =====================================
    // TEST
    // =====================================

    initial begin

        $dumpfile("waves/axi_write_channel_backpressure.vcd");
        $dumpvars(0, axi_write_channel_backpressure_tb);

        ACLK = 0;
        ARESETn = 0;

        start = 0;

        start_address = 0;
        burst_length  = 0;
        transfer_size = 3'b010;

        s_data  = 0;
        s_strb  = 0;
        s_valid = 0;

        allow_aw = 1'b0;
        allow_b  = 1'b0;

        #20;

        ARESETn = 1;

        @(posedge ACLK);


        // =================================
        // START WRITE
        // AW CHANNEL IS BLOCKED
        // =================================

        @(negedge ACLK);

        start_address = 32'h0000_0060;
        burst_length  = 8'd4;
        transfer_size = 3'b010;

        start = 1'b1;

        @(negedge ACLK);

        start = 1'b0;


        $display("");
        $display("AW CHANNEL STALL STARTED");


        // Keep AW stalled for four clocks
        repeat (4) begin

            @(posedge ACLK);

            $display(
                "AW STALL: AWVALID=%b AWADDR=%h AWLEN=%0d",
                AWVALID_master,
                AWADDR,
                AWLEN
            );

        end


        @(negedge ACLK);

        allow_aw = 1'b1;

        $display("AW CHANNEL STALL RELEASED");


        // Wait for address handshake
        wait(AWVALID_master && AWREADY_master);

        @(posedge ACLK);


        // =================================
        // SEND WRITE DATA
        // =================================

        send_data(32'hAAAA_1001);
        send_data(32'hBBBB_1002);
        send_data(32'hCCCC_1003);
        send_data(32'hDDDD_1004);


        // =================================
        // B CHANNEL STALL
        // =================================

        wait(BVALID_slave == 1'b1);

        $display("");
        $display("B CHANNEL STALL STARTED");


        repeat (4) begin

            @(posedge ACLK);

            $display(
                "B STALL: BVALID=%b BRESP=%b",
                BVALID_slave,
                BRESP
            );

        end


        @(negedge ACLK);

        allow_b = 1'b1;

        $display("B CHANNEL STALL RELEASED");


        // Wait for master to finish
        wait(done == 1'b1);

        @(posedge ACLK);


        // =================================
        // CHECK RAM
        // =================================

        $display("");
        $display("==============================");
        $display("AW + B BACKPRESSURE TEST");
        $display("==============================");


        // 0x60 / 4 = 24

        if (
            ram_inst.mem[24] == 32'hAAAA_1001 &&
            ram_inst.mem[25] == 32'hBBBB_1002 &&
            ram_inst.mem[26] == 32'hCCCC_1003 &&
            ram_inst.mem[27] == 32'hDDDD_1004
        ) begin

            $display("TEST PASSED");

        end
        else begin

            $display("TEST FAILED");

        end


        $display("RAM[24] = %h", ram_inst.mem[24]);
        $display("RAM[25] = %h", ram_inst.mem[25]);
        $display("RAM[26] = %h", ram_inst.mem[26]);
        $display("RAM[27] = %h", ram_inst.mem[27]);

        $display("");
        $display("AWLEN   = %0d", AWLEN);
        $display("AWSIZE  = %b", AWSIZE);
        $display("AWBURST = %b", AWBURST);
        $display("BRESP   = %b", BRESP);


        #20;

        $finish;

    end

endmodule