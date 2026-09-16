class axi_write_monitor extends uvm_monitor;

    `uvm_component_utils(axi_write_monitor)

    virtual axi_write_if vif;

    uvm_analysis_port #(
        axi_write_transaction
    ) ap;


    function new(
        string name = "axi_write_monitor",
        uvm_component parent = null
    );

        super.new(name, parent);

        ap = new("ap", this);

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
                "Write monitor interface missing"
            )

        end

    endfunction


    task run_phase(
        uvm_phase phase
    );

        axi_write_transaction tr;

        bit [31:0] data_q[$];
        bit [3:0]  strb_q[$];


        forever begin

            // AW handshake
            do begin
                @(posedge vif.ACLK);
            end
            while (!(vif.AWVALID &&
                     vif.AWREADY));


            tr =
                axi_write_transaction::type_id::create(
                    "mon_tr"
                );

            tr.addr  = vif.AWADDR;
            tr.len   = vif.AWLEN;
            tr.size  = vif.AWSIZE;
            tr.burst = vif.AWBURST;

            data_q.delete();
            strb_q.delete();


            // W beats
            forever begin

                @(posedge vif.ACLK);

                if (
                    vif.WVALID &&
                    vif.WREADY
                ) begin

                    data_q.push_back(
                        vif.WDATA
                    );

                    strb_q.push_back(
                        vif.WSTRB
                    );

                    if (vif.WLAST)
                        break;

                end

            end


            tr.data =
                new[data_q.size()];

            tr.strb =
                new[strb_q.size()];


            foreach (tr.data[i])
                tr.data[i] = data_q[i];

            foreach (tr.strb[i])
                tr.strb[i] = strb_q[i];


            // B handshake
            do begin
                @(posedge vif.ACLK);
            end
            while (!(vif.BVALID &&
                     vif.BREADY));


            tr.bresp = vif.BRESP;

            ap.write(tr);

        end

    endtask

endclass