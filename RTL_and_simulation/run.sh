#!/bin/bash

iverilog -g2005-sv -v -Wall -gstrict-ca-eval -gstrict-expr-width -gio-range-error testbench.v 
vvp a.out -lxt2
rm a.out
