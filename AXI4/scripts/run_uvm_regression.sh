#!/bin/bash

set -e

echo " AXI4 UVM REGRESSION"


echo "[1/2] Running AXI WRITE UVM..."
echo ""

./scripts/run_uvm_write.sh

echo ""
echo "WRITE TEST PASSED"
echo ""


echo ""
echo "[2/2] Running AXI READ UVM..."
echo ""

./scripts/run_uvm_read.sh

echo ""
echo "READ TEST PASSED"
echo ""

echo " AXI4 UVM REGRESSION PASSED"
