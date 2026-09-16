`timescale 1ns/1ps

module ram (

    input  logic        ACLK,

    input  logic        we,
    input  logic [3:0]  wstrb,
    input  logic [7:0]  addr,
    input  logic [31:0] wdata,

    output logic [31:0] rdata

);

    logic [31:0] mem [0:255];


    always_ff @(posedge ACLK) begin

        if (we) begin

            if (wstrb[0])
                mem[addr][7:0] <= wdata[7:0];

            if (wstrb[1])
                mem[addr][15:8] <= wdata[15:8];

            if (wstrb[2])
                mem[addr][23:16] <= wdata[23:16];

            if (wstrb[3])
                mem[addr][31:24] <= wdata[31:24];

        end
    end

    assign rdata = mem[addr];


endmodule