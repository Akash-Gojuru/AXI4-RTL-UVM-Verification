class axi_write_coverage extends uvm_subscriber #(axi_write_transaction);

    `uvm_component_utils(axi_write_coverage)

    axi_write_transaction tr;

    covergroup write_cg;

        option.per_instance = 1;

        // -------------------------
        // Burst length coverage
        // -------------------------
        cp_len : coverpoint tr.len {

            bins single = {0};

            bins short_burst[] = {[1:3]};

            bins medium_burst[] = {[4:7]};

            bins long_burst[] = {[8:15]};

        }


        // -------------------------
        // Transfer size coverage
        // -------------------------
        cp_size : coverpoint tr.size {

            bins byte_transfer = {3'b000};

            bins halfword_transfer = {3'b001};

            bins word_transfer = {3'b010};

            illegal_bins unsupported =
                {[3'b011:3'b111]};

        }


        // -------------------------
        // Burst type coverage
        // -------------------------
        cp_burst : coverpoint tr.burst {

            bins fixed = {2'b00};

            bins incr  = {2'b01};

            bins wrap  = {2'b10};

            illegal_bins reserved = {2'b11};

        }


        // -------------------------
        // BRESP coverage
        // -------------------------
        cp_bresp : coverpoint tr.bresp {

            bins okay   = {2'b00};

            bins exokay = {2'b01};

            bins slverr = {2'b10};

            bins decerr = {2'b11};

        }


        // -------------------------
        // Address region coverage
        // -------------------------
        cp_addr : coverpoint tr.addr[9:2] {

            bins low    = {[0:63]};

            bins middle = {[64:191]};

            bins high   = {[192:255]};

        }


        // -------------------------
        // WSTRB coverage
        // -------------------------
        cp_strb : coverpoint tr.strb[0] {

            bins full_word = {4'b1111};

            bins lower_byte = {4'b0001};

            bins lower_half = {4'b0011};

            bins upper_half = {4'b1100};

            bins upper_byte = {4'b1000};

            bins others = default;

        }


        // -------------------------
        // Useful crosses
        // -------------------------
        burst_len_cross :
            cross cp_burst, cp_len;

        size_len_cross :
            cross cp_size, cp_len;

        response_burst_cross :
            cross cp_bresp, cp_burst;

    endgroup


    function new(
        string name = "axi_write_coverage",
        uvm_component parent = null
    );

        super.new(name, parent);

        write_cg = new();

    endfunction


    virtual function void write(
        axi_write_transaction t
    );

        tr = t;

        write_cg.sample();

    endfunction


    function void report_phase(
        uvm_phase phase
    );

        super.report_phase(phase);

        `uvm_info(
            "WRITE_COV",
            $sformatf(
                "WRITE FUNCTIONAL COVERAGE = %0.2f%%",
                write_cg.get_coverage()
            ),
            UVM_NONE
        )

    endfunction

endclass