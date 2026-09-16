class axi_read_coverage extends uvm_subscriber #(axi_read_transaction);

    `uvm_component_utils(axi_read_coverage)

    axi_read_transaction tr;

    covergroup read_cg;

        option.per_instance = 1;


    
        cp_len : coverpoint tr.len {

            bins single = {0};

            bins short_burst[] = {[1:3]};

            bins medium_burst[] = {[4:7]};

            bins long_burst[] = {[8:15]};

        }

        cp_size : coverpoint tr.size {

            bins byte_transfer =
                {3'b000};

            bins halfword_transfer =
                {3'b001};

            bins word_transfer =
                {3'b010};

            illegal_bins unsupported =
                {[3'b011:3'b111]};

        }

        // Burst type
        cp_burst : coverpoint tr.burst {

            bins fixed = {2'b00};

            bins incr = {2'b01};

            bins wrap = {2'b10};

            illegal_bins reserved =
                {2'b11};

        }


        // Address coverage
        cp_addr : coverpoint tr.addr[9:2] {

            bins low =
                {[0:63]};

            bins middle =
                {[64:191]};

            bins high =
                {[192:255]};

        }


        // RRESP
        cp_rresp : coverpoint tr.response[0] {

            bins okay =
                {2'b00};

            bins exokay =
                {2'b01};

            bins slverr =
                {2'b10};

            bins decerr =
                {2'b11};

        }


        // Crosses
        burst_len_cross :
            cross cp_burst, cp_len;

        size_len_cross :
            cross cp_size, cp_len;

        response_burst_cross :
            cross cp_rresp, cp_burst;

    endgroup


    function new(
        string name = "axi_read_coverage",
        uvm_component parent = null
    );

        super.new(name, parent);

        read_cg = new();

    endfunction


    virtual function void write(
        axi_read_transaction t
    );

        tr = t;

        read_cg.sample();

    endfunction


    function void report_phase(
        uvm_phase phase
    );

        super.report_phase(phase);

        `uvm_info(
            "READ_COV",
            $sformatf(
                "READ FUNCTIONAL COVERAGE = %0.2f%%",
                read_cg.get_coverage()
            ),
            UVM_NONE
        )

    endfunction

endclass