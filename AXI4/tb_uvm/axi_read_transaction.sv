class axi_read_transaction extends uvm_sequence_item;

    rand bit [31:0] addr;
    rand bit [7:0]  len;
    rand bit [2:0]  size;
    rand bit [1:0]  burst;

    bit [31:0] data[];
    bit [1:0]  response[];


    constraint c_size {
        size == 3'b010;
    }

    constraint c_burst {
        burst == 2'b01;
    }

    constraint c_len {
        len inside {[0:15]};
    }

    constraint c_alignment {
        addr[1:0] == 2'b00;
    }


    `uvm_object_utils(axi_read_transaction)


    function new(
        string name = "axi_read_transaction"
    );

        super.new(name);

    endfunction

endclass