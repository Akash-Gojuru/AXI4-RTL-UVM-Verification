class axi_read_monitor extends uvm_monitor;

    `uvm_component_utils(axi_read_monitor)

    virtual axi_read_if vif;

    uvm_analysis_port #(
        axi_read_transaction
    ) ap;


    function new(
        string name = "axi_read_monitor",
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
            virtual axi_read_if
        )::get(
            this,
            "",
            "vif",
            vif
        )) begin

            `uvm_fatal(
                "NOVIF",
                "Read monitor interface missing"
            )

        end

    endfunction


    task run_phase(
        uvm_phase phase
    );

        axi_read_transaction tr;

        bit [31:0] data_q[$];
        bit [1:0]  resp_q[$];


        forever begin

            // AR handshake
            do begin
                @(posedge vif.ACLK);
            end
            while (!(vif.ARVALID &&
                     vif.ARREADY));


            tr =
                axi_read_transaction::type_id::create(
                    "mon_tr"
                );

            tr.addr  = vif.ARADDR;
            tr.len   = vif.ARLEN;
            tr.size  = vif.ARSIZE;
            tr.burst = vif.ARBURST;

            data_q.delete();
            resp_q.delete();


            // Read data
            forever begin

                @(posedge vif.ACLK);

                if (
                    vif.RVALID &&
                    vif.RREADY
                ) begin

                    data_q.push_back(
                        vif.RDATA
                    );

                    resp_q.push_back(
                        vif.RRESP
                    );

                    if (vif.RLAST)
                        break;

                end

            end


            tr.data =
                new[data_q.size()];

            tr.response =
                new[resp_q.size()];


            foreach (tr.data[i])
                tr.data[i] = data_q[i];

            foreach (tr.response[i])
                tr.response[i] = resp_q[i];


            ap.write(tr);

        end

    endtask

endclass