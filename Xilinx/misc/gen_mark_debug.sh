#! /bin/bash

#
#
# Copyright (c) 2016 University of Granada
# Author: Miguel Jimenez Lopez <klyone@ugr.es>
# Distributed under the GNU GPL v2. For full terms see the file LICENSE.
#
#

# Comment the following line to allow relative path
FORCE_ABS_PATH=1

#include util.sh
if [ -z ${SCRIPT_BASE_FOLDER} ] ; then
	echo "ERROR: SCRIPT_BASE_FOLDER var not defined!"
	exit -1
fi

. ${SCRIPT_BASE_FOLDER}/misc/util.sh

function help_msg {
	echo_norm "-------------------------------------------------------------------"
	echo_norm "$(basename $0) -f <configuration file>"
	echo_norm ""
	echo_norm "Options:"
	echo_norm "\t-f: Set configuration file"
	echo_norm "\t-h: Print help message"
	echo_norm ""
	echo_norm "-------------------------------------------------------------------"
	echo_norm "Copyright (C) 2015, University of Granada"
	echo_norm "Miguel Jimenez Lopez <klyone@ugr.es>"
	echo_norm "GPLv2 License or later"
	echo_norm "-------------------------------------------------------------------"
}

function check_signals {
	OLDIFS=$IFS
	IFS=$','
	for signal in $1
	do
		tmp=$(cat $2 | grep -w "signal ${signal}")
		if [ -z "${tmp}" ] ; then
			fail "Signal \"${signal}\" not defined in $2"
		fi
	done
	IFS=OLDIFS
}

function show_dbg_signals {
	echo_norm ""
	echo_norm "\t-- Debug stuff"
	echo_norm "\tattribute MARK_DEBUG : string;"
	echo_norm ""

	OLDIFS=$IFS
	IFS=$','
	for signal in $1
	do
		echo_norm "\tattribute MARK_DEBUG of ${signal} : signal is \"TRUE\";"
	done
	IFS=OLDIFS
}

while getopts ":f:h" opt; do
  case $opt in
    f)
      conf_file="${OPTARG}"
      check_file ${conf_file}
      file_ok=$?
      
      assert $file_ok "\"${conf_file}\" file not found!"
      
      if [ ! -z "${FORCE_ABS_PATH}" ] ; then
		check_abs_path ${conf_file}
		file_ok=$?
		
		assert $file_ok "\"${conf_file}\" invalid, only absolute path are allowed!"
	  fi
	  
      ;;
	h)
	  help_msg
	  exit 0
	  ;;
    \?)
      fail "Invalid option: -$OPTARG"
      ;;
  esac
done

if [ -z "${conf_file}" ] ; then
	fail "Configuration file not found!"
fi

file_in=$(cat ${conf_file} | grep "FILE_IN=" | sed "s,FILE_IN=,,")
debug_signals=$(cat ${conf_file} | grep "DEBUG=" | sed "s,DEBUG=,,")
show_debug_only=$(cat ${conf_file} | grep "SHOW_DEBUG_ONLY=" | sed "s,SHOW_DEBUG_ONLY=,,")

if [ -z "${debug_signals}" ] ; then
	fail "You must specify the signals to debug!"
fi

check_file ${file_in}
file_ok=$?
assert $file_ok "\"${file_in}\" file not found!"

if [ ! -z "${FORCE_ABS_PATH}" ] ; then
	check_abs_path ${file_in}
	file_ok=$?
	assert $file_ok "\"${file_in}\" invalid, only absolute path are allowed!"
fi

check_signals ${debug_signals} ${file_in}

if [ ! -z "${show_debug_only}" ] && [ "${show_debug_only}" == "YES" ] ; then
	show_dbg_signals ${debug_signals}
	exit 0
fi

arch_begin_found=${FALSE}
func_begin_found=${FALSE}
arch_found=${FALSE}

while IFS='' read -r line || [[ -n "$line" ]]
do
	if [ ${arch_found} == ${FALSE} ] ; then
		tmp=$(echo_norm ${line} | grep -w "architecture")
	
		if [ ! -z "${tmp}" ] ; then
			echo_norm "${line}"
			arch_found=${TRUE}
		else
			echo_norm "${line}"
		fi
	else
		if [ ${arch_begin_found} == ${FALSE} ] ; then
			tmp=$(echo_norm ${line} | grep -w "begin")
			tmp2=$(echo_norm ${line} | grep -w "function")
			
			if [ ! -z "${tmp2}" ] && [ "${tmp2: -1}" != ";" ] ; then
				func_begin_found=${TRUE}
			fi
			
			if [ ! -z "${tmp}" ] ; then
				if [ ${func_begin_found} == ${FALSE} ] ; then
					
					show_dbg_signals ${debug_signals}
					
					echo_norm "${line}"
					arch_begin_found=${TRUE}
				else
					echo_norm "${line}"
					func_begin_found=${FALSE}
				fi
			else
				echo_norm "${line}"
			fi
		else
			echo_norm "${line}"
		fi
	fi
done < "${file_in}"

exit 0
