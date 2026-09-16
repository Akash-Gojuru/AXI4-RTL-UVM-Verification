`timescale 1ns/1ps

module axi_read_master (

    input  logic        ACLK,
    input  logic        ARESETn,

    // Control
    input  logic        start,
    input  logic [31:0] start_address,
    input  logic [7:0]  burst_length,
    input  logic [2:0]  transfer_size,

    output logic        done,

    // Output Stream
    output logic [31:0] m_data,
    output logic        m_valid,
    output logic        m_last,
    input  logic        m_ready,

    // AXI Read Address Channel
    output logic [31:0] ARADDR,
    output logic [7:0]  ARLEN,
    output logic [2:0]  ARSIZE,
    output logic [1:0]  ARBURST,
    output logic        ARVALID,
    input  logic        ARREADY,

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


    always_ff @(posedge ACLK or negedge ARESETn) begin

        if (!ARESETn) begin

            state <= IDLE;

            ARADDR  <= 32'b0;
            ARLEN   <= 8'b0;
            ARSIZE  <= 3'b010;
            ARBURST <= 2'b01;
            ARVALID <= 1'b0;

            RREADY <= 1'b0;

            m_data  <= 32'b0;
            m_valid <= 1'b0;
            m_last  <= 1'b0;

            done <= 1'b0;

        end

        else begin

            done <= 1'b0;

            case (state)

                IDLE: begin

                    m_valid <= 1'b0;
                    m_last  <= 1'b0;
                    RREADY  <= 1'b0;

                    if (start) begin

                        ARADDR <= start_address;

                        ARLEN <= burst_length - 1'b1;

                        ARSIZE <= transfer_size;

                        ARBURST <= 2'b01;

                        ARVALID <= 1'b1;

                        state <= SEND_ADDR;

                    end

                end


                SEND_ADDR: begin

                    if (ARVALID && ARREADY) begin

                        ARVALID <= 1'b0;

                        RREADY <= 1'b1;

                        state <= READ_DATA;

                    end

                end


                READ_DATA: begin

                    // Capture AXI data
                    if (RVALID && RREADY) begin

                        m_data <= RDATA;

                        m_valid <= 1'b1;

                        m_last <= RLAST;

                        RREADY <= 1'b0;

                    end


                    // Output stream consumed
                    if (m_valid && m_ready) begin

                        m_valid <= 1'b0;

                        if (m_last) begin

                            m_last <= 1'b0;

                            done <= 1'b1;

                            state <= IDLE;

                        end

                        else begin

                            RREADY <= 1'b1;

                        end

                    end

                end


                default: begin
                    state <= IDLE;
                end

            endcase

        end

    end

endmodule