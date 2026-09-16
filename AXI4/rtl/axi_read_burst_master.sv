`timescale 1ns/1ps

module axi_read_burst_master (

    input  logic        ACLK,
    input  logic        ARESETn,

    // Control
    input  logic        start,
    input  logic [31:0] start_address,
    input  logic [7:0]  burst_length,

    output logic [31:0] data0,
    output logic [31:0] data1,
    output logic [31:0] data2,
    output logic [31:0] data3,

    output logic        done,

    // AXI Read Address Channel
    output logic [31:0] ARADDR,
    output logic [7:0]  ARLEN,
    output logic [2:0]  ARSIZE,
    output logic [1:0]  ARBURST,
    output logic        ARVALID,
    input  logic        ARREADY,

    // AXI Read Data Channel
    input  logic [31:0] RDATA,
    input  logic [1:0]  RRESP,
    input  logic        RVALID,
    input  logic        RLAST,
    output logic        RREADY
);

    typedef enum logic [1:0] {
        IDLE,
        SEND_ADDR,
        READ_DATA
    } state_t;

    state_t state;

    logic [7:0] beat_count;


    always_ff @(posedge ACLK or negedge ARESETn) begin

        if (!ARESETn) begin

            state      <= IDLE;
            beat_count <= 0;

            ARADDR     <= 0;
            ARLEN      <= 0;
            ARSIZE     <= 3'b010;
            ARBURST    <= 2'b01;
            ARVALID    <= 0;

            RREADY     <= 0;

            data0      <= 0;
            data1      <= 0;
            data2      <= 0;
            data3      <= 0;

            done       <= 0;

        end

        else begin

            done <= 0;

            case (state)

                IDLE: begin

                    if (start) begin

                        ARADDR  <= start_address;
                        ARLEN   <= burst_length - 1'b1;

                        ARSIZE  <= 3'b010;
                        ARBURST <= 2'b01;

                        ARVALID <= 1'b1;

                        beat_count <= 0;

                        state <= SEND_ADDR;

                    end

                end


                SEND_ADDR: begin

                    if (ARVALID && ARREADY) begin

                        ARVALID <= 0;

                        RREADY <= 1;

                        state <= READ_DATA;

                    end

                end


                READ_DATA: begin

                    if (RVALID && RREADY) begin

                        case (beat_count)

                            0: data0 <= RDATA;
                            1: data1 <= RDATA;
                            2: data2 <= RDATA;
                            3: data3 <= RDATA;

                        endcase

                        if (RLAST) begin

                            RREADY <= 0;
                            done   <= 1;

                            state <= IDLE;

                        end

                        else begin

                            beat_count <= beat_count + 1'b1;

                        end

                    end

                end

            endcase

        end

    end

endmodule