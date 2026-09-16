class axi_read_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(axi_read_scoreboard)

    uvm_analysis_imp #(
        axi_read_transaction,
        axi_read_scoreboard
    ) imp;

    int transactions_checked;
    int errors;


    function new(
        string name = "axi_read_scoreboard",
        uvm_component parent = null
    );

        super.new(name, parent);

        imp = new("imp", this);

    endfunction


    function void write(
        axi_read_transaction tr
    );

        transactions_checked++;


        if (
            tr.data.size() !=
            tr.len + 1
        ) begin

            errors++;

            `uvm_error(
                "READ_SCB",
                $sformatf(
                    "Beat count mismatch: ARLEN=%0d beats=%0d",
                    tr.len,
                    tr.data.size()
                )
            )

        end


        foreach (tr.data[i]) begin

            if (
                tr.data[i] !==
                (32'hA000_0000 + i)
            ) begin

                errors++;

                `uvm_error(
                    "READ_SCB",
                    $sformatf(
                        "DATA ERROR beat=%0d expected=%h actual=%h",
                        i,
                        32'hA000_0000 + i,
                        tr.data[i]
                    )
                )

            end


            if (
                tr.response[i] !=
                2'b00
            ) begin

                errors++;

                `uvm_error(
                    "READ_SCB",
                    $sformatf(
                        "RRESP ERROR beat=%0d response=%b",
                        i,
                        tr.response[i]
                    )
                )

            end

        end


        if (errors == 0) begin

            `uvm_info(
                "READ_SCB",
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
            "READ_SCB",
            $sformatf(
                "READ SUMMARY: checked=%0d errors=%0d",
                transactions_checked,
                errors
            ),
            UVM_NONE
        )

    endfunction

endclass