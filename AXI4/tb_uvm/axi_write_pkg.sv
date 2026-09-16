package axi_write_pkg;

    import uvm_pkg::*;

    `include "uvm_macros.svh"

    `include "axi_write_transaction.sv"
    `include "axi_write_sequence.sv"
    `include "axi_write_sequencer.sv"
    `include "axi_write_driver.sv"
    `include "axi_write_monitor.sv"
    `include "axi_write_scoreboard.sv"
    `include "axi_write_coverage.sv"
    `include "axi_write_agent.sv"
    `include "axi_write_env.sv"
    `include "axi_write_test.sv"

endpackage