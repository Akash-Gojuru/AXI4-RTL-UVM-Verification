`timescale 1ns/1ps

module axi_write_master (

    input  logic        ACLK,
    input  logic        ARESETn,

    // Control signals
    input  logic        start,
    input  logic [31:0] start_address,
    input  logic [7:0]  burst_length,
    input  logic [2:0]  transfer_size,

    output logic        done,

    // Input stream 
    input  logic [31:0] s_data,
    input  logic [3:0]  s_strb,
    input  logic        s_valid,
    output logic        s_ready,

    // Write Address Channel (AW)
    output logic [31:0] AWADDR,
    output logic [7:0]  AWLEN,
    output logic [2:0]  AWSIZE,     //
    output logic [1:0]  AWBURST,
    output logic        AWVALID,
    input  logic        AWREADY,

    //  Write Data Channel (W)
    output logic [31:0] WDATA,
    output logic [3:0]  WSTRB,
    output logic        WVALID,
    output logic        WLAST,
    input  logic        WREADY,

    //  Write Response Channel (B) (this give the response from the slave)
    input  logic [1:0]  BRESP,
    input  logic        BVALID,
    output logic        BREADY

);

    typedef enum logic [2:0] {
        IDLE,
        SEND_ADDR,
        SEND_DATA,
        WAIT_RESP
    } state_t;

    state_t state;

    logic [7:0] beat_count;     // temporary saving
    logic [7:0] saved_burst_length;


    always_ff @(posedge ACLK or negedge ARESETn) begin

        if (!ARESETn) begin

            state <= IDLE;

            AWADDR  <= 32'b0;
            AWLEN  <= 8'b0;
            AWSIZE  <= 3'b010;
            AWBURST <= 2'b01;
            AWVALID <= 1'b0;

            WDATA  <= 32'b0;
            WSTRB  <= 4'b0000;
            WVALID <= 1'b0;
            WLAST  <= 1'b0;

            BREADY <= 1'b0;

            s_ready <= 1'b0;
            beat_count <= 8'b0;
            saved_burst_length  <= 8'b0;
            done <= 1'b0;

        end

        else begin

            done <= 1'b0;

            case (state)
                IDLE: begin
                    s_ready <= 1'b0;

                    if (start) begin

                        AWADDR <= start_address;
                        AWLEN <= burst_length - 1'b1; // this len - 1
                        AWSIZE <= transfer_size;
                        AWBURST <= 2'b01;
                        AWVALID <= 1'b1;

                        saved_burst_length <= burst_length;
                        beat_count <= 8'd0;
                        state <= SEND_ADDR;
                    end
                end


                SEND_ADDR: begin

                    if (AWVALID && AWREADY) begin
                       
                        AWVALID <= 1'b0;
                        s_ready <= 1'b1;
                        state <= SEND_DATA;
                    end
                end


                SEND_DATA: begin

                    if (!WVALID && s_valid && s_ready) begin

                        WDATA <= s_data;
                        WSTRB <= s_strb;
                        WVALID <= 1'b1;

                        if (beat_count == (saved_burst_length - 1'b1))
                            WLAST <= 1'b1;
                        else
                            WLAST <= 1'b0;

                        s_ready <= 1'b0;
                    end

                    if (WVALID && WREADY) begin     // data handshake

                        WVALID <= 1'b0;

                        if (beat_count == (saved_burst_length - 1'b1)) begin
                            
                            WLAST <= 1'b0;
                            BREADY <= 1'b1;
                            state <= WAIT_RESP;
                        end

                        else begin
                            beat_count <= beat_count + 1'b1;
                            s_ready <= 1'b1;
                        end
                    end
                end


                WAIT_RESP: begin

                    s_ready <= 1'b0;
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