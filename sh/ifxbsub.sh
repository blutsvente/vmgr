#!/bin/bash
#
# not finished: Wrapper script to convert bsub command to ifxlsf command
#

opts="$@"

# standard options + default values

queue_name=""
job_name=""
out_file=""
err_file=""
file_limit=""
run_limit=""
mem_limit=""
pre_exec_cmd=""
project_name=""

debug=0
if [ -n "$IFXBSUB_DEBUG" ]; then
    debug=1
fi

this=$0


# Call getopt
# temp=`getopt -q -a -o q:R:J:oo:e:F:W:M:E:P: -- "$@"`

# if [ $? != 0 ]; then
#    echo "$this: ERROR: terminating"
#    exit 1
# fi
# echo $temp
# eval set -- "$temp"

res_reqs=
rem_args=
ifxlsf_cmd="ifxlsf"

for opt in $opts; do
    case "$1" in 
        -q)     queue_name=$2 ;   shift 2 ;;
        -R)     res_reqs=$2 ;    shift 2 ;;
        -J)     job_name=$2 ;     shift 2 ;;
        -o|-oo) out_file=$2 ;     shift 2 ;;
        -e|-ee) err_file=$2 ;     shift 2 ;;
 		  -F)     file_limit=$2 ;   shift 2 ;;
 		  -W)     run_limit=$2 ;    shift 2 ;;
 		  -M)     mem_limit=$2 ;    shift 2 ;;
 		  -E)     pre_exec_cmd=$2 ; shift 2 ;;
 		  -P)     project_name=$2 ; shift 2 ;;
        *)      rem_args="$rem_args $1"; shift ;;        
    esac
done

#
# bsub options
#
lsf_opts="-R '$res_reqs'"

if [ -n "$job_name" ]; then
    lsf_opts="$lsf_opts -J $job_name"
fi
if [ -n "$out_file" ]; then
    lsf_opts="$lsf_opts -o $out_file"
fi
if [ -n "$err_file" ]; then
    lsf_opts="$lsf_opts= -e $err_file"
fi
if [ -n "$lsf_opts" ]; then
    ifxlsf_cmd="$ifxlsf_cmd -eh_lsfopts \"$lsf_opts\""
fi

ifxlsf_cmd="$ifxlsf_cmd $rem_args"
echo $ifxlsf_cmd > ifxbub.sh.log
$ifxlsf_cmd



