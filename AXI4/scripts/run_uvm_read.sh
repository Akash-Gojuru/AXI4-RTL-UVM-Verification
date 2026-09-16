#!/bin/bash

set -e


echo " AXI READ UVM TEST"


xrun -uvm \
-incdir tb_uvm \
rtl/ram.sv \
rtl/axi_read_slave.sv \
tb_uvm/axi_read_if.sv \
tb_uvm/axi_read_pkg.sv \
tb_uvm/axi_read_tb.sv \
-top axi_read_tb \
-access rwc \
-coverage all \
-covoverwrite \
-input "@run; exit;"


echo " AXI READ UVM COMPLETE"
