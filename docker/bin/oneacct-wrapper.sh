#!/bin/bash

source $(dirname $0)/configuration.sh

configure_oneacct-export
oneacct-export $@
