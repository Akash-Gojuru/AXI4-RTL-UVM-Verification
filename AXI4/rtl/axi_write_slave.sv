`timescale 1ns/1ps

module axi_write_slave (

    input  logic        ACLK,
    input  logic        ARESETn,

    input  logic [31:0] AWADDR,
    input  logic [7:0]  AWLEN,
    input  logic [2:0]  AWSIZE,
    input  logic [1:0]  AWBURST,
    input  logic        AWVALID,
    output logic        AWREADY,

    input  logic [31:0] WDATA,
    input  logic [3:0]  WSTRB,
    input  logic        WVALID,
    input  logic        WLAST,
    output logic        WREADY,

    output logic [1:0]  BRESP,
    output logic        BVALID,
    input  logic        BREADY,
    
    //ram
    output logic        ram_we,
    output logic [3:0]  ram_wstrb,
    output logic [7:0]  ram_addr,
    output logic [31:0] ram_wdata

);

    logic [31:0] current_addr;
    logic [7:0] burst_len;
    logic [7:0] beat_count;
    logic [2:0] saved_size;

    logic burst_active;
    logic burst_error;


    always_ff @(posedge ACLK or negedge ARESETn) begin

        if (!ARESETn) begin
            AWREADY <= 1'b1;
            WREADY  <= 1'b0;
            BRESP  <= 2'b00;
            BVALID <= 1'b0;

            current_addr <= 32'b0;
            burst_len  <= 8'b0;
            beat_count <= 8'b0;
            saved_size <= 3'b0;

            burst_active <= 1'b0;
            burst_error  <= 1'b0;

            ram_we    <= 1'b0;
            ram_wstrb <= 4'b0000;
            ram_addr  <= 8'b0;
            ram_wdata <= 32'b0;

        end

        else begin

            ram_we <= 1'b0;


            if (AWVALID && AWREADY) begin

                current_addr <= AWADDR;
                burst_len <= AWLEN;
                saved_size <= AWSIZE;
                beat_count <= 8'd0;
                burst_active <= 1'b1;

                AWREADY <= 1'b0;
                WREADY <= 1'b1;

                if ((AWBURST != 2'b01) || (AWSIZE > 3'b010)) begin      //curenlty it only support the increment type brust
                    burst_error <= 1'b1;
                end

                else begin
                    burst_error <= 1'b0;
                end

            end


            if (WVALID && WREADY && burst_active) begin

                ram_addr  <= current_addr[9:2];
                ram_wdata <= WDATA;
                ram_wstrb <= WSTRB;
                ram_we    <= 1'b1;


                // Final expected beat
                if (beat_count == burst_len) begin

                    WREADY <= 1'b0;
                    burst_active <= 1'b0;

                    if (!WLAST)
                        BRESP <= 2'b10;
                    else if (burst_error)
                        BRESP <= 2'b10;
                    else
                        BRESP <= 2'b00;

                    BVALID <= 1'b1;
                end

                else begin

                    if (WLAST) begin

                        WREADY <= 1'b0;
                        burst_active <= 1'b0;
                        BRESP <= 2'b10;
                        BVALID <= 1'b1;

                    end

                    else begin
                        
                        current_addr <= current_addr + (32'd1 << saved_size);   // address increment = 2^AWSIZE
                        beat_count <= beat_count + 1'b1;
                    end
                end

            end

            if (BVALID && BREADY) begin     // response handshake
                BVALID <= 1'b0;
                AWREADY <= 1'b1;
            end
        end

    end

endmodule