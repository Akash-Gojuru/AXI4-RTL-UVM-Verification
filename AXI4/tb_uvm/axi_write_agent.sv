class axi_write_agent extends uvm_agent;

    `uvm_component_utils(axi_write_agent)

    axi_write_sequencer sequencer;
    axi_write_driver    driver;
    axi_write_monitor   monitor;


    function new(
        string name = "axi_write_agent",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);

        sequencer =
            axi_write_sequencer::type_id::create(
                "sequencer",
                this
            );

        driver =
            axi_write_driver::type_id::create(
                "driver",
                this
            );

        monitor =
            axi_write_monitor::type_id::create(
                "monitor",
                this
            );

    endfunction


    function void connect_phase(
        uvm_phase phase
    );

        super.connect_phase(phase);

        driver.seq_item_port.connect(
            sequencer.seq_item_export
        );

    endfunction

endclass