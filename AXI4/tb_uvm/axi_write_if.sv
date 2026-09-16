`timescale 1ns/1ps

interface axi_write_if (
    input logic ACLK
);

    logic ARESETn;

    // Write address channel
    logic [31:0] AWADDR;
    logic [7:0]  AWLEN;
    logic [2:0]  AWSIZE;
    logic [1:0]  AWBURST;
    logic        AWVALID;
    logic        AWREADY;

    // Write data channel
    logic [31:0] WDATA;
    logic [3:0]  WSTRB;
    logic        WVALID;
    logic        WLAST;
    logic        WREADY;

    // Write response channel
    logic [1:0] BRESP;
    logic       BVALID;
    logic       BREADY;

endinterface