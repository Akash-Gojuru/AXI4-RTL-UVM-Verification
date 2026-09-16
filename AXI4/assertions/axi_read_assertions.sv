`timescale 1ns/1ps

module axi_read_assertions (

    input logic        ACLK,
    input logic        ARESETn,


    input logic [31:0] ARADDR,
    input logic [7:0]  ARLEN,
    input logic [2:0]  ARSIZE,
    input logic [1:0]  ARBURST,
    input logic        ARVALID,
    input logic        ARREADY,


    input logic [31:0] RDATA,
    input logic [1:0]  RRESP,
    input logic        RVALID,
    input logic        RLAST,
    input logic        RREADY
);


    property ar_stable;

        @(posedge ACLK)
        disable iff (!ARESETn)

        ARVALID && !ARREADY
        |=>
        ARVALID &&
        $stable(ARADDR) &&
        $stable(ARLEN) &&
        $stable(ARSIZE) &&
        $stable(ARBURST);

    endproperty


    assert property (ar_stable)

    else begin

        $error(
            "AXI READ ERROR: AR channel changed while stalled"
        );

    end

    // R CHANNEL MUST STAY STABLE

    property r_stable;

        @(posedge ACLK)
        disable iff (!ARESETn)

        RVALID && !RREADY
        |=>
        RVALID &&
        $stable(RDATA) &&
        $stable(RRESP) &&
        $stable(RLAST);

    endproperty


    assert property (r_stable)

    else begin

        $error(
            "AXI READ ERROR: R channel changed while stalled"
        );

    end


    // ARSIZE MUST FIT 32-BIT DATA BUS
  
    property valid_arsize;

        @(posedge ACLK)
        disable iff (!ARESETn)

        ARVALID
        |->
        (ARSIZE <= 3'b010);

    endproperty


    assert property (valid_arsize)

    else begin

        $error(
            "AXI READ ERROR: Unsupported ARSIZE"
        );

    end

    // INCR BURSTS ONLY
  
    property valid_arburst;

        @(posedge ACLK)
        disable iff (!ARESETn)

        ARVALID
        |->
        (ARBURST == 2'b01);

    endproperty


    assert property (valid_arburst)

    else begin

        $error(
            "AXI READ ERROR: Unsupported ARBURST"
        );

    end


    // RRESP MUST BE A VALID AXI RESPONSE
    // WHEN RVALID IS HIGH
   
    property valid_rresp;

        @(posedge ACLK)
        disable iff (!ARESETn)

        RVALID
        |->
        (
            RRESP == 2'b00 ||   // OKAY
            RRESP == 2'b01 ||   // EXOKAY
            RRESP == 2'b10 ||   // SLVERR
            RRESP == 2'b11      // DECERR
        );

    endproperty


    assert property (valid_rresp)

    else begin

        $error(
            "AXI READ ERROR: Invalid RRESP"
        );

    end


endmodule