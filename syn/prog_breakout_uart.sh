#!/bin/bash

ARGS="BOARD=breakout INT=uart"

# syn
# make syn $ARGS

# place and route
make pnr $ARGS

# program flash
# make prog $ARGS

# load configuration to CRAM
# make load-cram $ARGS
