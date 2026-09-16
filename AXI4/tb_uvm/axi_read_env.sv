class axi_read_env extends uvm_env;

    `uvm_component_utils(axi_read_env)

    axi_read_agent      agent;
    axi_read_scoreboard scoreboard;
    axi_read_coverage   coverage;


    function new(
        string name = "axi_read_env",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);

        agent =
            axi_read_agent::type_id::create(
                "agent",
                this
            );

        scoreboard =
            axi_read_scoreboard::type_id::create(
                "scoreboard",
                this
            );

        coverage =
            axi_read_coverage::type_id::create(
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