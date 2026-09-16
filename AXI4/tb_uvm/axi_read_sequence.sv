class axi_read_sequence extends
    uvm_sequence #(axi_read_transaction);

    `uvm_object_utils(axi_read_sequence)


    function new(
        string name = "axi_read_sequence"
    );

        super.new(name);

    endfunction


    task body();

        axi_read_transaction tr;

        repeat (10) begin

            tr =
                axi_read_transaction::type_id::create(
                    "tr"
                );

            start_item(tr);

            if (!tr.randomize() with {

                addr inside {
                    [32'h0000_0000 :
                     32'h0000_03C0]
                };

            }) begin

                `uvm_fatal(
                    "READ_SEQ",
                    "Read transaction randomization failed"
                )

            end

            finish_item(tr);

        end

    endtask

endclass