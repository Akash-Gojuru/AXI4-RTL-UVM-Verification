`timescale 1ns/1ps

module axi_write_burst_master (

    input logic ACLK,
    input logic ARESETn,


    // CONTROL INTERFACE
    input logic start,

    input logic [31:0] start_address,

    input logic [7:0] burst_length,

    input logic [3:0] write_strobe,


    input logic [31:0] data0,
    input logic [31:0] data1,
    input logic [31:0] data2,
    input logic [31:0] data3,


    output logic done,


    // AXI WRITE ADDRESS CHANNEL

    output logic [31:0] AWADDR,

    output logic [7:0] AWLEN,

    output logic [2:0] AWSIZE,

    output logic [1:0] AWBURST,

    output logic AWVALID,

    input logic AWREADY,


    // AXI WRITE DATA CHANNEL

    output logic [31:0] WDATA,

    output logic [3:0] WSTRB,

    output logic WVALID,

    output logic WLAST,

    input logic WREADY,


    // AXI WRITE RESPONSE CHANNEL

    input logic [1:0] BRESP,

    input logic BVALID,

    output logic BREADY

);


    typedef enum logic [2:0] {

        IDLE,

        SEND_ADDR,

        SEND_DATA,

        WAIT_RESP

    } state_t;


    state_t state;


    logic [7:0] beat_count;

    logic [7:0] saved_burst_length;


    always_ff @(posedge ACLK or negedge ARESETn) begin

        if (!ARESETn) begin

            state <= IDLE;


            AWADDR <= 32'b0;
            AWLEN <= 8'b0;
            AWSIZE <= 3'b010;
            AWBURST <= 2'b01;
            AWVALID <= 1'b0;


            WDATA <= 32'b0;
            WSTRB <= 4'b0000;
            WVALID <= 1'b0;
            WLAST <= 1'b0;


            BREADY <= 1'b0;


            beat_count <= 8'b0;

            saved_burst_length <= 8'b0;


            done <= 1'b0;

        end


        else begin

            // done is only high for one clock cycle
            done <= 1'b0;


            case (state)

                IDLE: begin

                    if (start) begin

                        AWADDR <= start_address;


                        // AXI uses beats - 1
                        AWLEN <= burst_length - 1'b1;

                        // 32-bit data = 4 bytes
                        AWSIZE <= 3'b010;

                        // INCR burst
                        AWBURST <= 2'b01;

                        AWVALID <= 1'b1;


                        saved_burst_length <= burst_length;

                        beat_count <= 8'd0;


                        WSTRB <= write_strobe;


                        state <= SEND_ADDR;

                    end

                end


                SEND_ADDR: begin

                    if (AWVALID && AWREADY) begin

                        AWVALID <= 1'b0;
                        WDATA <= data0;
                        WVALID <= 1'b1;

                        if (saved_burst_length == 1)
                            WLAST <= 1'b1;

                        else
                            WLAST <= 1'b0;


                        state <= SEND_DATA;

                    end

                end


                SEND_DATA: begin

                    if (WVALID && WREADY) begin


                        if (beat_count ==
                            (saved_burst_length - 1'b1)) begin

                            WVALID <= 1'b0;

                            WLAST <= 1'b0;


                            BREADY <= 1'b1;


                            state <= WAIT_RESP;

                        end


                        else begin

                            beat_count <= beat_count + 1'b1;

                            case (beat_count + 1'b1)

                                8'd1:
                                    WDATA <= data1;

                                8'd2:
                                    WDATA <= data2;

                                8'd3:
                                    WDATA <= data3;

                                default:
                                    WDATA <= 32'b0;

                            endcase


                            // Is next beat the last beat
                            if ((beat_count + 1'b1) ==
                                (saved_burst_length - 1'b1)) begin

                                WLAST <= 1'b1;

                            end

                            else begin

                                WLAST <= 1'b0;

                            end

                        end

                    end

                end


                WAIT_RESP: begin

                    if (BVALID && BREADY) begin

                        BREADY <= 1'b0;
                        done <= 1'b1;
                        state <= IDLE;

                    end

                end

                default: begin

                    state <= IDLE;

                end


            endcase

        end

    end


endmodule