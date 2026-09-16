class axi_read_sequencer extends
    uvm_sequencer #(axi_read_transaction);

    `uvm_component_utils(axi_read_sequencer)


    function new(
        string name = "axi_read_sequencer",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction

endclass