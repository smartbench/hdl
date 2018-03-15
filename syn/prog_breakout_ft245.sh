#!/bin/bash

ARGS="BOARD=breakout INT=ft245"

# syn
# make syn $ARGS

# place and route
make pnr $ARGS

# program flash
# make prog $ARGS

# load configuration to CRAM
# make load-cram $ARGS
