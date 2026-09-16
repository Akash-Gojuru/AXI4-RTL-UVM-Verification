class axi_write_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(axi_write_scoreboard)

    uvm_analysis_imp #(
        axi_write_transaction,
        axi_write_scoreboard
    ) imp;

    int transactions_checked;
    int errors;


    function new(
        string name = "axi_write_scoreboard",
        uvm_component parent = null
    );

        super.new(name, parent);

        imp = new("imp", this);

    endfunction


    function void write(
        axi_write_transaction tr
    );

        transactions_checked++;


        if (
            tr.data.size() !=
            (tr.len + 1)
        ) begin

            errors++;

            `uvm_error(
                "WRITE_SCB",
                $sformatf(
                    "Beat mismatch AWLEN=%0d beats=%0d",
                    tr.len,
                    tr.data.size()
                )
            )

        end


        if (tr.bresp != 2'b00) begin

            errors++;

            `uvm_error(
                "WRITE_SCB",
                $sformatf(
                    "Unexpected BRESP=%b addr=%h",
                    tr.bresp,
                    tr.addr
                )
            )

        end


        if (
            tr.data.size() ==
            tr.len + 1 &&
            tr.bresp == 2'b00
        ) begin

            `uvm_info(
                "WRITE_SCB",
                $sformatf(
                    "PASS addr=%h beats=%0d",
                    tr.addr,
                    tr.data.size()
                ),
                UVM_LOW
            )

        end

    endfunction


    function void report_phase(
        uvm_phase phase
    );

        super.report_phase(phase);

        `uvm_info(
            "WRITE_SCB",
            $sformatf(
                "WRITE SUMMARY: checked=%0d errors=%0d",
                transactions_checked,
                errors
            ),
            UVM_NONE
        )

    endfunction

endclass