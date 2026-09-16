class axi_write_env extends uvm_env;

    `uvm_component_utils(axi_write_env)

    axi_write_agent      agent;
    axi_write_scoreboard scoreboard;
    axi_write_coverage   coverage;


    function new(
        string name = "axi_write_env",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);

        agent =
            axi_write_agent::type_id::create(
                "agent",
                this
            );

        scoreboard =
            axi_write_scoreboard::type_id::create(
                "scoreboard",
                this
            );

        coverage =
            axi_write_coverage::type_id::create(
                "coverage",
                this
            );

    endfunction


    function void connect_phase(
        uvm_phase phase
    );

        super.connect_phase(phase);

        // Monitor -> Scoreboard
        agent.monitor.ap.connect(
            scoreboard.imp
        );

        // Monitor -> Coverage
        agent.monitor.ap.connect(
            coverage.analysis_export
        );

    endfunction

endclass