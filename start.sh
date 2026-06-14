#!/bin/bash

rm -f *.beam

erlc *.erl

erl -eval "inventory_server:start_link(), vending_machine:start_link()."