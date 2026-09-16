`timescale 1ns/1ps

module axi_read_channel_backpressure_tb;

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
    // OUTPUT STREAM
    // =====================================

    logic [31:0] m_data;
    logic        m_valid;
    logic        m_last;
    logic        m_ready;


    // =====================================
    // AXI READ ADDRESS CHANNEL
    // =====================================

    logic [31:0] ARADDR;
    logic [7:0]  ARLEN;
    logic [2:0]  ARSIZE;
    logic [1:0]  ARBURST;

    logic ARVALID_master;
    logic ARVALID_slave;

    logic ARREADY_master;
    logic ARREADY_slave;

    logic allow_ar;


    // =====================================
    // AXI READ DATA CHANNEL
    // =====================================

    logic [31:0] RDATA;
    logic [1:0]  RRESP;
    logic        RLAST;

    logic RVALID_master;
    logic RVALID_slave;

    logic RREADY_master;
    logic RREADY_slave;

    logic allow_r;


    // =====================================
    // RAM
    // =====================================

    logic        ram_we;
    logic [3:0]  ram_wstrb;
    logic [7:0]  ram_addr;
    logic [31:0] ram_wdata;
    logic [31:0] ram_rdata;


    // =====================================
    // TEST STORAGE
    // =====================================

    integer count;

    logic [31:0] received [0:3];


    // =====================================
    // CLOCK
    // =====================================

    always #5 ACLK = ~ACLK;


    // =====================================
    // AR CHANNEL BACKPRESSURE GATE
    // =====================================

    assign ARVALID_slave =
        ARVALID_master && allow_ar;

    assign ARREADY_master =
        ARREADY_slave && allow_ar;


    // =====================================
    // R CHANNEL BACKPRESSURE GATE
    // =====================================

    assign RVALID_master =
        RVALID_slave && allow_r;

    assign RREADY_slave =
        RREADY_master && allow_r;


    // =====================================
    // AXI READ MASTER
    // =====================================

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

        .ARVALID(ARVALID_master),
        .ARREADY(ARREADY_master),

        .RDATA(RDATA),
        .RRESP(RRESP),
        .RVALID(RVALID_master),
        .RLAST(RLAST),
        .RREADY(RREADY_master)

    );


    // =====================================
    // AXI READ SLAVE
    // =====================================

    axi_read_slave slave_inst (

        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .ARADDR(ARADDR),
        .ARLEN(ARLEN),
        .ARSIZE(ARSIZE),
        .ARBURST(ARBURST),

        .ARVALID(ARVALID_slave),
        .ARREADY(ARREADY_slave),

        .RDATA(RDATA),
        .RRESP(RRESP),
        .RVALID(RVALID_slave),
        .RLAST(RLAST),
        .RREADY(RREADY_slave),

        .ram_addr(ram_addr),
        .ram_rdata(ram_rdata)

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
    // CAPTURE OUTPUT STREAM
    // =====================================

    always @(posedge ACLK) begin

        if (m_valid && m_ready) begin

            received[count] <= m_data;

            count <= count + 1;

        end

    end


    // =====================================
    // TEST
    // =====================================

    initial begin

        $dumpfile("axi_read_channel_backpressure.vcd");
        $dumpvars(0, axi_read_channel_backpressure_tb);


        // ---------------------------------
        // INITIAL VALUES
        // ---------------------------------

        ACLK = 0;
        ARESETn = 0;

        start = 0;

        start_address = 0;
        burst_length  = 0;
        transfer_size = 3'b010;

        m_ready = 1'b1;

        ram_we = 1'b0;
        ram_wstrb = 4'b0000;
        ram_wdata = 32'b0;

        count = 0;

        // Start with both AXI channels blocked
        allow_ar = 1'b0;
        allow_r  = 1'b0;


        // ---------------------------------
        // RESET
        // ---------------------------------

        #20;

        ARESETn = 1;

        @(posedge ACLK);


        // =================================
        // PRELOAD RAM
        // =================================

        ram_inst.mem[24] = 32'hAAAA_2001;
        ram_inst.mem[25] = 32'hBBBB_2002;
        ram_inst.mem[26] = 32'hCCCC_2003;
        ram_inst.mem[27] = 32'hDDDD_2004;


        // =================================
        // START READ
        // =================================

        @(negedge ACLK);

        start_address = 32'h0000_0060;

        burst_length = 8'd4;

        transfer_size = 3'b010;

        start = 1'b1;


        @(negedge ACLK);

        start = 1'b0;


        // =================================
        // AR CHANNEL STALL
        // =================================

        $display("");
        $display("AR CHANNEL STALL STARTED");


        repeat (4) begin

            @(posedge ACLK);

            $display(
                "AR STALL: ARVALID=%b ARADDR=%h ARLEN=%0d",
                ARVALID_master,
                ARADDR,
                ARLEN
            );

        end


        @(negedge ACLK);

        allow_ar = 1'b1;

        $display("AR CHANNEL STALL RELEASED");


        // Wait until AR handshake happens
        wait(ARVALID_master && ARREADY_master);

        @(posedge ACLK);


        // =================================
        // ALLOW FIRST READ BEAT
        // =================================

        allow_r = 1'b1;


        // Wait until first output beat reaches consumer
        wait(count == 1);


        // =================================
        // R CHANNEL STALL
        // =================================

        @(negedge ACLK);

        allow_r = 1'b0;

        $display("");
        $display("R CHANNEL STALL STARTED");


        // Wait for slave to present next beat
        wait(RVALID_slave == 1'b1);


        repeat (4) begin

            @(posedge ACLK);

            $display(
                "R STALL: RVALID=%b RDATA=%h RRESP=%b RLAST=%b",
                RVALID_slave,
                RDATA,
                RRESP,
                RLAST
            );

        end


        @(negedge ACLK);

        allow_r = 1'b1;

        $display("R CHANNEL STALL RELEASED");


        // =================================
        // WAIT FOR COMPLETE BURST
        // =================================

        wait(done == 1'b1);

        @(posedge ACLK);


        // =================================
        // RESULT
        // =================================

        $display("");
        $display("==============================");
        $display("AR + R BACKPRESSURE TEST");
        $display("==============================");


        if (
            received[0] == 32'hAAAA_2001 &&
            received[1] == 32'hBBBB_2002 &&
            received[2] == 32'hCCCC_2003 &&
            received[3] == 32'hDDDD_2004
        ) begin

            $display("TEST PASSED");

        end

        else begin

            $display("TEST FAILED");

        end


        // =================================
        // RECEIVED DATA
        // =================================

        $display("");
        $display("DATA[0] = %h", received[0]);
        $display("DATA[1] = %h", received[1]);
        $display("DATA[2] = %h", received[2]);
        $display("DATA[3] = %h", received[3]);


        // =================================
        // AXI INFO
        // =================================

        $display("");
        $display("ARLEN   = %0d", ARLEN);
        $display("ARSIZE  = %b", ARSIZE);
        $display("ARBURST = %b", ARBURST);
        $display("RRESP   = %b", RRESP);
        $display("BEATS   = %0d", count);


        if (count == 4)
            $display("BEAT COUNT PASSED");
        else
            $display("BEAT COUNT FAILED");


        #20;

        $finish;

    end

endmodule