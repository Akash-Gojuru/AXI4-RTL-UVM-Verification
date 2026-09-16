`timescale 1ns/1ps

module axi_read_burst_slave (

    input  logic        ACLK,
    input  logic        ARESETn,

    // AXI Read Address Channel
    input  logic [31:0] ARADDR,
    input  logic [7:0]  ARLEN,
    input  logic [2:0]  ARSIZE,
    input  logic [1:0]  ARBURST,
    input  logic        ARVALID,
    output logic        ARREADY,

    // AXI Read Data Channel
    output logic [31:0] RDATA,
    output logic [1:0]  RRESP,
    output logic        RVALID,
    output logic        RLAST,
    input  logic        RREADY,

    // RAM Interface
    output logic [7:0]  ram_addr,
    input  logic [31:0] ram_rdata
);

    logic [31:0] current_addr;
    logic [7:0]  burst_len;
    logic [7:0]  beat_count;
    logic        burst_active;


    always_ff @(posedge ACLK or negedge ARESETn) begin

        if (!ARESETn) begin

            ARREADY      <= 1'b1;

            RDATA        <= 32'b0;
            RRESP        <= 2'b00;
            RVALID       <= 1'b0;
            RLAST        <= 1'b0;

            current_addr <= 32'b0;
            burst_len    <= 8'b0;
            beat_count   <= 8'b0;
            burst_active <= 1'b0;

            ram_addr     <= 8'b0;

        end

        else begin

            // READ ADDRESS HANDSHAKE
            if (ARVALID && ARREADY) begin

                current_addr <= ARADDR;
                burst_len    <= ARLEN;
                beat_count   <= 0;

                ram_addr     <= ARADDR[9:2];

                burst_active <= 1'b1;

                ARREADY <= 1'b0;
                RVALID  <= 1'b0;
                RLAST   <= 1'b0;

            end

            // PRESENT FIRST/NEXT DATA
            
            if (burst_active && !RVALID) begin

                RDATA  <= ram_rdata;
                RRESP  <= 2'b00;
                RVALID <= 1'b1;

                if (beat_count == burst_len)
                    RLAST <= 1'b1;
                else
                    RLAST <= 1'b0;

            end


            // DATA HANDSHAKE
            if (RVALID && RREADY) begin

                if (RLAST) begin

                    RVALID       <= 1'b0;
                    RLAST        <= 1'b0;
                    burst_active <= 1'b0;

                    ARREADY <= 1'b1;

                end

                else begin

                    beat_count <= beat_count + 1'b1;

                    current_addr <= current_addr + 32'd4;

                    ram_addr <= (current_addr + 32'd4) >> 2;

                    RVALID <= 1'b0;

                end

            end

        end

    end

endmodule