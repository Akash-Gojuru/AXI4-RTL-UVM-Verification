class axi_write_driver extends
    uvm_driver #(axi_write_transaction);

    `uvm_component_utils(axi_write_driver)

    virtual axi_write_if vif;


    function new(
        string name = "axi_write_driver",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);

        if (!uvm_config_db#(
            virtual axi_write_if
        )::get(
            this,
            "",
            "vif",
            vif
        )) begin

            `uvm_fatal(
                "NOVIF",
                "axi_write_if not found"
            )

        end

    endfunction


    task reset_signals();

        vif.AWADDR  <= '0;
        vif.AWLEN   <= '0;
        vif.AWSIZE  <= 3'b010;
        vif.AWBURST <= 2'b01;
        vif.AWVALID <= 1'b0;

        vif.WDATA   <= '0;
        vif.WSTRB   <= '0;
        vif.WVALID  <= 1'b0;
        vif.WLAST   <= 1'b0;

        vif.BREADY  <= 1'b0;

    endtask


    task drive_transaction(
        axi_write_transaction tr
    );

        // =========================
        // AW CHANNEL
        // =========================

        @(negedge vif.ACLK);

        vif.AWADDR  <= tr.addr;
        vif.AWLEN   <= tr.len;
        vif.AWSIZE  <= tr.size;
        vif.AWBURST <= tr.burst;
        vif.AWVALID <= 1'b1;


        do begin
            @(posedge vif.ACLK);
        end
        while (!vif.AWREADY);


        @(negedge vif.ACLK);

        vif.AWVALID <= 1'b0;

        for (
            int i = 0;
            i < tr.data.size();
            i++
        ) begin

            @(negedge vif.ACLK);

            vif.WDATA  <= tr.data[i];
            vif.WSTRB  <= tr.strb[i];
            vif.WVALID <= 1'b1;

            vif.WLAST <=
                (i == tr.data.size() - 1);


            do begin
                @(posedge vif.ACLK);
            end
            while (!vif.WREADY);


            @(negedge vif.ACLK);

            vif.WVALID <= 1'b0;
            vif.WLAST  <= 1'b0;

        end


        @(negedge vif.ACLK);

        vif.BREADY <= 1'b1;


        do begin
            @(posedge vif.ACLK);
        end
        while (!vif.BVALID);


        tr.bresp = vif.BRESP;


        @(negedge vif.ACLK);

        vif.BREADY <= 1'b0;

    endtask


    task run_phase(
        uvm_phase phase
    );

        axi_write_transaction tr;

        reset_signals();

        wait(vif.ARESETn == 1'b1);


        forever begin

            seq_item_port.get_next_item(tr);

            drive_transaction(tr);

            seq_item_port.item_done();

        end

    endtask

endclass