#!/bin/bash

ARGS="BOARD=mainboard"

# syn
# make syn $ARGS

# place and route
make pnr $ARGS

# program flash
# make prog $ARGS

# load configuration to CRAM
# make load-cram $ARGS
