#!/bin/bash

set -e

echo " AXI WRITE UVM TEST"


xrun -uvm \
-incdir tb_uvm \
rtl/ram.sv \
rtl/axi_write_slave.sv \
tb_uvm/axi_write_if.sv \
tb_uvm/axi_write_pkg.sv \
tb_uvm/axi_write_tb.sv \
-top axi_write_tb \
-access rwc \
-coverage all \
-covoverwrite \
-input "@run; exit;"

echo " AXI WRITE UVM COMPLETE"
