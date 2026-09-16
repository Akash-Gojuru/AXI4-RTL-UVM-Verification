`timescale 1ns/1ps

module axi_read_backpressure_tb;

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
    logic        ARVALID;
    logic        ARREADY;


    // =====================================
    // AXI READ DATA CHANNEL
    // =====================================

    logic [31:0] RDATA;
    logic [1:0]  RRESP;
    logic        RVALID;
    logic        RLAST;
    logic        RREADY;


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
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),

        .RDATA(RDATA),
        .RRESP(RRESP),
        .RVALID(RVALID),
        .RLAST(RLAST),
        .RREADY(RREADY)

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

        $dumpfile("axi_read_backpressure.vcd");
        $dumpvars(0, axi_read_backpressure_tb);


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


        // ---------------------------------
        // RESET
        // ---------------------------------

        #20;

        ARESETn = 1;

        @(posedge ACLK);


        // =================================
        // PRELOAD RAM
        // =================================

        ram_inst.mem[16] = 32'hAAAA_0001;
        ram_inst.mem[17] = 32'hBBBB_0002;
        ram_inst.mem[18] = 32'hCCCC_0003;
        ram_inst.mem[19] = 32'hDDDD_0004;


        // =================================
        // START 4-BEAT READ
        // =================================

        @(negedge ACLK);

        start_address = 32'h0000_0040;

        burst_length = 8'd4;

        transfer_size = 3'b010;

        start = 1'b1;


        @(negedge ACLK);

        start = 1'b0;


        // =================================
        // WAIT FOR FIRST OUTPUT BEAT
        // =================================

        wait(m_valid == 1'b1);

        wait(count == 1);


        // =================================
        // STALL OUTPUT STREAM
        // =================================

        @(negedge ACLK);

        m_ready = 1'b0;

        $display("");
        $display("READ OUTPUT STALL STARTED");


        // Hold downstream stalled
        repeat (4) begin

            @(posedge ACLK);

            if (m_valid) begin
                $display(
                    "STALLED DATA = %h",
                    m_data
                );
            end

        end


        @(negedge ACLK);

        m_ready = 1'b1;

        $display("READ OUTPUT STALL RELEASED");


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
        $display("READ BACKPRESSURE TEST");
        $display("==============================");


        if (
            received[0] == 32'hAAAA_0001 &&
            received[1] == 32'hBBBB_0002 &&
            received[2] == 32'hCCCC_0003 &&
            received[3] == 32'hDDDD_0004
        ) begin

            $display("TEST PASSED");

        end

        else begin

            $display("TEST FAILED");

        end


        // =================================
        // PRINT RECEIVED DATA
        // =================================

        $display("");
        $display("DATA[0] = %h", received[0]);
        $display("DATA[1] = %h", received[1]);
        $display("DATA[2] = %h", received[2]);
        $display("DATA[3] = %h", received[3]);


        // =================================
        // AXI INFORMATION
        // =================================

        $display("");
        $display("ARLEN   = %0d", ARLEN);
        $display("ARSIZE  = %b", ARSIZE);
        $display("ARBURST = %b", ARBURST);
        $display("RRESP   = %b", RRESP);

        $display(
            "BEATS RECEIVED = %0d",
            count
        );


        if (count == 4) begin
            $display("BEAT COUNT PASSED");
        end
        else begin
            $display("BEAT COUNT FAILED");
        end


        #20;

        $finish;

    end

endmodule