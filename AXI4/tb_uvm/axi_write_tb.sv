`timescale 1ns/1ps

module axi_write_tb;

    import uvm_pkg::*;
    import axi_write_pkg::*;


    logic ACLK;

    logic        ram_we;
    logic [3:0]  ram_wstrb;
    logic [7:0]  ram_addr;
    logic [31:0] ram_wdata;
    logic [31:0] ram_rdata;


    always #5 ACLK = ~ACLK;


    axi_write_if axi_if (
        .ACLK(ACLK)
    );


    axi_write_slave dut (

        .ACLK(ACLK),
        .ARESETn(axi_if.ARESETn),

        .AWADDR(axi_if.AWADDR),
        .AWLEN(axi_if.AWLEN),
        .AWSIZE(axi_if.AWSIZE),
        .AWBURST(axi_if.AWBURST),

        .AWVALID(axi_if.AWVALID),
        .AWREADY(axi_if.AWREADY),

        .WDATA(axi_if.WDATA),
        .WSTRB(axi_if.WSTRB),
        .WVALID(axi_if.WVALID),
        .WLAST(axi_if.WLAST),
        .WREADY(axi_if.WREADY),

        .BRESP(axi_if.BRESP),
        .BVALID(axi_if.BVALID),
        .BREADY(axi_if.BREADY),

        .ram_we(ram_we),
        .ram_wstrb(ram_wstrb),
        .ram_addr(ram_addr),
        .ram_wdata(ram_wdata)

    );


    ram memory (

        .ACLK(ACLK),

        .we(ram_we),
        .wstrb(ram_wstrb),
        .addr(ram_addr),
        .wdata(ram_wdata),

        .rdata(ram_rdata)

    );


    initial begin

        ACLK = 0;

        axi_if.ARESETn = 0;

        #30;

        @(negedge ACLK);

        axi_if.ARESETn = 1;

    end


    initial begin

        uvm_config_db#(
            virtual axi_write_if
        )::set(
            null,
            "*",
            "vif",
            axi_if
        );

        run_test("axi_write_test");

    end

endmodule