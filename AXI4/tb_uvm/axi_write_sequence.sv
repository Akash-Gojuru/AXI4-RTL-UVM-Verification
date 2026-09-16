class axi_write_sequence extends
    uvm_sequence #(axi_write_transaction);

    `uvm_object_utils(axi_write_sequence)


    function new(
        string name = "axi_write_sequence"
    );

        super.new(name);

    endfunction


    task body();

        axi_write_transaction tr;

        repeat (10) begin

            tr =
                axi_write_transaction::type_id::create(
                    "tr"
                );

            start_item(tr);

            if (!tr.randomize() with {

                addr[1:0] == 2'b00;

                addr inside {
                    [32'h0000_0000 :
                     32'h0000_03C0]
                };

            }) begin

                `uvm_fatal(
                    "WRITE_SEQ",
                    "Write transaction randomization failed"
                )

            end

            finish_item(tr);

        end

    endtask

endclass