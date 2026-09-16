`timescale 1ns/1ps

module axi_write_withoutstall_tb;

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

    // AXI AW channel
    logic [31:0] AWADDR;
    logic [7:0]  AWLEN;
    logic [2:0]  AWSIZE;
    logic [1:0]  AWBURST;
    logic        AWVALID;
    logic        AWREADY;

    // AXI W channel
    logic [31:0] WDATA;
    logic [3:0]  WSTRB;
    logic        WVALID;
    logic        WLAST;
    logic        WREADY;

    // AXI B channel
    logic [1:0]  BRESP;
    logic        BVALID;
    logic        BREADY;

    // RAM
    logic        ram_we;
    logic [3:0]  ram_wstrb;
    logic [7:0]  ram_addr;
    logic [31:0] ram_wdata;
    logic [31:0] ram_rdata;


    // =================================================
    // CLOCK
    // =================================================

    always #5 ACLK = ~ACLK;


    // =================================================
    // MASTER
    // =================================================

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


    // =================================================
    // SLAVE
    // =================================================

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


    // =================================================
    // RAM
    // =================================================

    ram ram_inst (

        .ACLK(ACLK),

        .we(ram_we),
        .wstrb(ram_wstrb),

        .addr(ram_addr),
        .wdata(ram_wdata),

        .rdata(ram_rdata)
    );


    // =================================================
    // SEND ONE DATA BEAT
    // =================================================

    task send_data(input logic [31:0] value);

        begin

            @(negedge ACLK);

            s_data  = value;
            s_strb  = 4'b1111;
            s_valid = 1'b1;

            // Wait until master accepts data
            while (!(s_valid && s_ready)) begin
                @(posedge ACLK);
            end

            @(negedge ACLK);

            s_valid = 1'b0;

        end

    endtask


    // =================================================
    // TEST
    // =================================================

    initial begin

       // $dumpfile("axi_write_basic.vcd");
       // $dumpvars(0, axi_write_basic_tb);


        // Initial values

        ACLK = 0;
        ARESETn = 0;

        start = 0;

        start_address = 0;
        burst_length = 0;
        transfer_size = 3'b010;

        s_data = 0;
        s_strb = 0;
        s_valid = 0;


        // =================================================
        // RESET
        // =================================================

        #20;

        ARESETn = 1;

        @(posedge ACLK);


        // =================================================
        // START 4-BEAT WRITE
        // =================================================

        @(negedge ACLK);

        start_address = 32'h0000_0040;
        burst_length = 8'd4;
        transfer_size = 3'b010;

        start = 1'b1;


        @(negedge ACLK);

        start = 1'b0;


        // =================================================
        // SEND 4 DATA BEATS
        // =================================================

        send_data(32'hAAAA_0001);

        send_data(32'hBBBB_0002);

        send_data(32'hCCCC_0003);

        send_data(32'hDDDD_0004);


        // =================================================
        // WAIT FOR WRITE RESPONSE
        // =================================================

        wait(done == 1'b1);


        @(posedge ACLK);


        // =================================================
        // CHECK RESULT
        // =================================================

        $display("");
        $display("==============================");
        $display("BASIC AXI WRITE TEST");
        $display("==============================");


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


        // Print RAM values

        $display("");
        $display("RAM[16] = %h", ram_inst.mem[16]);
        $display("RAM[17] = %h", ram_inst.mem[17]);
        $display("RAM[18] = %h", ram_inst.mem[18]);
        $display("RAM[19] = %h", ram_inst.mem[19]);


        // AXI information

        $display("");
        $display("AWADDR  = %h", AWADDR);
        $display("AWLEN   = %0d", AWLEN);
        $display("AWSIZE  = %b", AWSIZE);
        $display("AWBURST = %b", AWBURST);
        $display("BRESP   = %b", BRESP);


        if (BRESP == 2'b00)
            $display("WRITE RESPONSE = OKAY");
        else
            $display("WRITE RESPONSE ERROR");


        #20;

        $finish;

    end

endmodule
