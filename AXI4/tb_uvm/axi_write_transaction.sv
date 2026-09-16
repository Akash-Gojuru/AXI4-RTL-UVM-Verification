class axi_write_transaction extends uvm_sequence_item;

    rand bit [31:0] addr;
    rand bit [7:0]  len;
    rand bit [2:0]  size;
    rand bit [1:0]  burst;

    rand bit [31:0] data[];
    rand bit [3:0]  strb[];

    bit [1:0] bresp;


    constraint c_size {
        size == 3'b010;
    }

    constraint c_burst {
        burst == 2'b01;
    }

    constraint c_len {
        len inside {[0:15]};
    }

    constraint c_array_size {
        data.size() == len + 1;
        strb.size() == len + 1;
    }

    constraint c_strb {
        foreach (strb[i])
            strb[i] == 4'b1111;
    }


    `uvm_object_utils(axi_write_transaction)


    function new(
        string name = "axi_write_transaction"
    );

        super.new(name);

    endfunction

endclass