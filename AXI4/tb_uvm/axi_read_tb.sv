`timescale 1ns/1ps

module axi_read_tb;

    import uvm_pkg::*;
    import axi_read_pkg::*;


    logic ACLK;

    logic [7:0]  ram_addr;
    logic [31:0] ram_rdata;

    logic [7:0] selected_ram_addr;


    always #5 ACLK = ~ACLK;


    axi_read_if axi_if (
        .ACLK(ACLK)
    );


    axi_read_slave dut (

        .ACLK(ACLK),
        .ARESETn(axi_if.ARESETn),

        .ARADDR(axi_if.ARADDR),
        .ARLEN(axi_if.ARLEN),
        .ARSIZE(axi_if.ARSIZE),
        .ARBURST(axi_if.ARBURST),

        .ARVALID(axi_if.ARVALID),
        .ARREADY(axi_if.ARREADY),

        .RDATA(axi_if.RDATA),
        .RRESP(axi_if.RRESP),
        .RVALID(axi_if.RVALID),
        .RLAST(axi_if.RLAST),
        .RREADY(axi_if.RREADY),

        .ram_addr(ram_addr),
        .ram_rdata(ram_rdata)

    );


    assign selected_ram_addr =
        axi_if.preload_we ?
        axi_if.preload_addr :
        ram_addr;


    ram memory (

        .ACLK(ACLK),

        .we(axi_if.preload_we),
        .wstrb(axi_if.preload_wstrb),

        .addr(selected_ram_addr),

        .wdata(axi_if.preload_wdata),

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
            virtual axi_read_if
        )::set(
            null,
            "*",
            "vif",
            axi_if
        );

        run_test("axi_read_test");

    end

endmodule