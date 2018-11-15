#!/bin/bash -f
export TFILE=${1}
export F02=${2}
export F03=${3}
export F04=${4}
export F06=${5}
export OUTPATH=${6}
# Load the required modules
module add idl/8.5
${IDL_DIR}/bin/idl -rt=/home/users/mchristensen/idl/trunk/ship/a-train/shiptrack_algorithm/auto_main.sav
exit
