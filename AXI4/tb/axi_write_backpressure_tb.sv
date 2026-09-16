`timescale 1ns/1ps

module axi_write_backpressure_tb;

    // =====================================
    // CLOCK / RESET
    // =====================================

    logic ACLK;
    logic ARESETn;


    // =====================================
    // MASTER CONTROL
    // =====================================

    logic        start;
    logic [31:0] start_address;
    logic [7:0]  burst_length;
    logic [2:0]  transfer_size;
    logic        done;


    // =====================================
    // INPUT STREAM
    // =====================================

    logic [31:0] s_data;
    logic [3:0]  s_strb;
    logic        s_valid;
    logic        s_ready;


    // =====================================
    // AXI WRITE ADDRESS CHANNEL
    // =====================================

    logic [31:0] AWADDR;
    logic [7:0]  AWLEN;
    logic [2:0]  AWSIZE;
    logic [1:0]  AWBURST;
    logic        AWVALID;
    logic        AWREADY;


    // =====================================
    // AXI WRITE DATA CHANNEL
    // =====================================

    logic [31:0] WDATA;
    logic [3:0]  WSTRB;
    logic        WLAST;

    // Separate handshake signals
    // so testbench can insert a stall.
    logic WVALID_master;
    logic WVALID_slave;

    logic WREADY_master;
    logic WREADY_slave;

    logic allow_write;


    // =====================================
    // AXI WRITE RESPONSE CHANNEL
    // =====================================

    logic [1:0] BRESP;
    logic       BVALID;
    logic       BREADY;


    // =====================================
    // RAM INTERFACE
    // =====================================

    logic        ram_we;
    logic [3:0]  ram_wstrb;
    logic [7:0]  ram_addr;
    logic [31:0] ram_wdata;
    logic [31:0] ram_rdata;


    // =====================================
    // CLOCK
    // =====================================

    always #5 ACLK = ~ACLK;


    // =====================================
    // BACKPRESSURE GATE
    // =====================================

    // Normal:
    // allow_write = 1
    //
    // master and slave communicate normally.
    //
    // Stall:
    // allow_write = 0
    //
    // master sees READY = 0
    // slave sees VALID = 0
    //
    // Therefore neither side thinks a
    // handshake happened.

    assign WVALID_slave =
        WVALID_master && allow_write;

    assign WREADY_master =
        WREADY_slave && allow_write;


    // =====================================
    // AXI WRITE MASTER
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
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),

        .WDATA(WDATA),
        .WSTRB(WSTRB),
        .WVALID(WVALID_master),
        .WLAST(WLAST),
        .WREADY(WREADY_master),

        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY)

    );


    // =====================================
    // AXI WRITE SLAVE
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
        .WVALID(WVALID_slave),
        .WLAST(WLAST),
        .WREADY(WREADY_slave),

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
    // SEND ONE STREAM DATA BEAT
    // =====================================

    task send_data (input logic [31:0] value);

        begin

            @(negedge ACLK);

            s_data  = value;
            s_strb  = 4'b1111;
            s_valid = 1'b1;


            // Wait until write master accepts
            // this input stream beat.
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

        $dumpfile("axi_write_backpressure.vcd");
        $dumpvars(0, axi_write_backpressure_tb);


        // ---------------------------------
        // INITIAL VALUES
        // ---------------------------------

        ACLK = 0;

        ARESETn = 0;

        start = 0;

        start_address = 0;

        burst_length = 0;

        transfer_size = 3'b010;


        s_data  = 0;

        s_strb  = 0;

        s_valid = 0;


        // No stall initially
        allow_write = 1'b1;


        // ---------------------------------
        // RESET
        // ---------------------------------

        #20;

        ARESETn = 1;


        @(posedge ACLK);


        // =================================
        // START 4-BEAT WRITE BURST
        // =================================

        @(negedge ACLK);

        start_address = 32'h0000_0040;

        burst_length = 8'd4;

        transfer_size = 3'b010;

        start = 1'b1;


        @(negedge ACLK);

        start = 1'b0;


        // =================================
        // BEAT 1
        // =================================

        send_data(32'hAAAA_0001);


        // =================================
        // INSERT W-CHANNEL BACKPRESSURE
        // =================================

        @(negedge ACLK);

        allow_write = 1'b0;


        $display("");
        $display("W CHANNEL STALL STARTED");


        fork

            // -----------------------------
            // MASTER RECEIVES SECOND
            // INPUT STREAM BEAT
            // -----------------------------
            begin

                send_data(32'hBBBB_0002);

            end


            // -----------------------------
            // KEEP AXI W CHANNEL STALLED
            // FOR FOUR CLOCKS
            // -----------------------------
            begin

                repeat (4) begin
                    @(posedge ACLK);
                end


                @(negedge ACLK);

                allow_write = 1'b1;


                $display(
                    "W CHANNEL STALL RELEASED"
                );

            end

        join


        // =================================
        // BEAT 3
        // =================================

        send_data(32'hCCCC_0003);


        // =================================
        // BEAT 4
        // =================================

        send_data(32'hDDDD_0004);


        // =================================
        // WAIT FOR COMPLETE AXI RESPONSE
        // =================================

        wait(done == 1'b1);


        @(posedge ACLK);


        // =================================
        // RESULT
        // =================================

        $display("");
        $display("==============================");
        $display("WRITE BACKPRESSURE TEST");
        $display("==============================");


        // 0x40 / 4 = 16

        if (
            ram_inst.mem[16] == 32'hAAAA_0001 &&
            ram_inst.mem[17] == 32'hBBBB_0002 &&
            ram_inst.mem[18] == 32'hCCCC_0003 &&
            ram_inst.mem[19] == 32'hDDDD_0004
        ) begin

            $display("TEST PASSED");

        end

        else begin

            $display("TEST FAILED");

        end


        // =================================
        // RAM VALUES
        // =================================

        $display("");
        $display(
            "RAM[16] = %h",
            ram_inst.mem[16]
        );

        $display(
            "RAM[17] = %h",
            ram_inst.mem[17]
        );

        $display(
            "RAM[18] = %h",
            ram_inst.mem[18]
        );

        $display(
            "RAM[19] = %h",
            ram_inst.mem[19]
        );


        // =================================
        // AXI INFORMATION
        // =================================

        $display("");
        $display(
            "AWLEN   = %0d",
            AWLEN
        );

        $display(
            "AWSIZE  = %b",
            AWSIZE
        );

        $display(
            "AWBURST = %b",
            AWBURST
        );

        $display(
            "BRESP   = %b",
            BRESP
        );


        if (BRESP == 2'b00) begin

            $display(
                "WRITE RESPONSE = OKAY"
            );

        end

        else begin

            $display(
                "WRITE RESPONSE ERROR"
            );

        end


        #20;

        $finish;

    end

endmodule