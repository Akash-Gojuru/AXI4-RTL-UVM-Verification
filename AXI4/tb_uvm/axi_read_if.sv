`timescale 1ns/1ps

interface axi_read_if (
    input logic ACLK
);

    logic ARESETn;

    // Read address channel
    logic [31:0] ARADDR;
    logic [7:0]  ARLEN;
    logic [2:0]  ARSIZE;
    logic [1:0]  ARBURST;
    logic        ARVALID;
    logic        ARREADY;

    // Read data channel
    logic [31:0] RDATA;
    logic [1:0]  RRESP;
    logic        RVALID;
    logic        RLAST;
    logic        RREADY;


    // TB-only RAM preload signals
    logic        preload_we;
    logic [3:0]  preload_wstrb;
    logic [7:0]  preload_addr;
    logic [31:0] preload_wdata;

endinterface