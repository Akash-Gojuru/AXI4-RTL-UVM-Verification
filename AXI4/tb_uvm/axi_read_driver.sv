class axi_read_driver extends
    uvm_driver #(axi_read_transaction);

    `uvm_component_utils(axi_read_driver)

    virtual axi_read_if vif;


    function new(
        string name = "axi_read_driver",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);

        if (!uvm_config_db#(
            virtual axi_read_if
        )::get(
            this,
            "",
            "vif",
            vif
        )) begin

            `uvm_fatal(
                "NOVIF",
                "axi_read_if not found"
            )

        end

    endfunction


    task reset_signals();

        vif.ARADDR  <= '0;
        vif.ARLEN   <= '0;
        vif.ARSIZE  <= 3'b010;
        vif.ARBURST <= 2'b01;
        vif.ARVALID <= 1'b0;

        vif.RREADY <= 1'b0;

        vif.preload_we    <= 1'b0;
        vif.preload_addr  <= '0;
        vif.preload_wdata <= '0;
        vif.preload_wstrb <= '0;

    endtask


    task preload_memory(
        axi_read_transaction tr
    );

        for (
            int i = 0;
            i <= tr.len;
            i++
        ) begin

            @(negedge vif.ACLK);

            vif.preload_addr <=
                (tr.addr >> 2) + i;

            vif.preload_wdata <=
                32'hA000_0000 + i;

            vif.preload_wstrb <=
                4'b1111;

            vif.preload_we <=
                1'b1;


            @(posedge vif.ACLK);

            @(negedge vif.ACLK);

            vif.preload_we <=
                1'b0;

        end

    endtask


    task drive_transaction(
        axi_read_transaction tr
    );

        preload_memory(tr);


        @(negedge vif.ACLK);

        vif.ARADDR  <= tr.addr;
        vif.ARLEN   <= tr.len;
        vif.ARSIZE  <= tr.size;
        vif.ARBURST <= tr.burst;
        vif.ARVALID <= 1'b1;


        do begin
            @(posedge vif.ACLK);
        end
        while (!vif.ARREADY);


        @(negedge vif.ACLK);

        vif.ARVALID <= 1'b0;

        vif.RREADY <= 1'b1;

        // WAIT FOR LAST READ BEAT
 

        forever begin

            @(posedge vif.ACLK);

            if (
                vif.RVALID &&
                vif.RREADY &&
                vif.RLAST
            ) begin

                break;

            end

        end


        @(negedge vif.ACLK);

        vif.RREADY <= 1'b0;

    endtask


    task run_phase(
        uvm_phase phase
    );

        axi_read_transaction tr;

        reset_signals();

        wait(vif.ARESETn == 1'b1);


        forever begin

            seq_item_port.get_next_item(tr);

            drive_transaction(tr);

            seq_item_port.item_done();

        end

    endtask

endclass