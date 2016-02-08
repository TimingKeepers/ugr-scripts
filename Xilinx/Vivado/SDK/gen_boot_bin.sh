#! /bin/bash

#
#
# Copyright (c) 2016 University of Granada
# Author: Miguel Jimenez Lopez <klyone@ugr.es>
# Distributed under the GNU GPL v2. For full terms see the file LICENSE.
#
#

# Ask for the Bootgen tool
BOOTGEN=$(which bootgen)

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
	echo_norm "$(basename $0) -b <bootloader> -a <application> [-g <gateware>]"
	echo_norm ""
	echo_norm "Options:"
	echo_norm "\t-b: Set bootloader file"
	echo_norm "\t-g: Set gateware file"
	echo_norm "\t-a: Set application file"
	echo_norm "\t-o: Set BOOT.bin path"
	echo_norm "\t-h: Print help message"
	echo_norm ""
	echo_norm "-------------------------------------------------------------------"
	echo_norm "Copyright (C) 2015, University of Granada"
	echo_norm "Miguel Jimenez Lopez <klyone@ugr.es>"
	echo_norm "GPLv2 License or later"
	echo_norm "-------------------------------------------------------------------"
}

if [ -z ${BOOTGEN} ] ; then
	fail "The Xilinx environment variables must be set!"
fi

while getopts ":b:g:a:o:h" opt; do
  case $opt in
    b)
      bootloader_file="${OPTARG}"
      check_file ${bootloader_file}
      file_ok=$?
      
      assert $file_ok "Bootloader \"${bootloader_file}\" file not found!"
      
      if [ ! -z "${FORCE_ABS_PATH}" ] ; then
		check_abs_path ${bootloader_file}
		file_ok=$?
		
		assert $file_ok "\"${bootloader_file}\" invalid, only absolute path are allowed!"
	  fi
	  
      ;;
    g)
	  gw_file="${OPTARG}"
      check_file ${gw_file}
      file_ok=$?
      
      assert $file_ok "Gateware \"${gw_file}\" file not found!"
      
      if [ ! -z "${FORCE_ABS_PATH}" ] ; then
		check_abs_path ${gw_file}
		file_ok=$?
		
		assert $file_ok "\"${gw_file}\" invalid, only absolute path are allowed!"
	  fi
	  
	  ;;
	a)
	  app_file="${OPTARG}"
      check_file ${app_file}
      file_ok=$?
      
      assert $file_ok "Application \"${app_file}\" file not found!"
      
      if [ ! -z "${FORCE_ABS_PATH}" ] ; then
		check_abs_path ${app_file}
		file_ok=$?
		
		assert $file_ok "\"${app_file}\" invalid, only absolute path are allowed!"
	  fi
	  
	  ;;
	o)
	  bootbin_file="${OPTARG}"
	  
	  if [ ! -z "${FORCE_ABS_PATH}" ] ; then
		check_abs_path ${bootbin_file}
		file_ok=$?
		
		assert $file_ok "\"${bootbin_file}\" invalid, only absolute path are allowed!"
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

if [ -z ${app_file} ] || [ -z ${bootloader_file} ] ; then
	fail "You must specify the bootloader and the application files at least"
fi

if [ -z ${bootbin_file} ] ; then
	bootbin_file="BOOT.bin"
fi

echo_norm "Generating tmp files..."
TMPF=$(mktemp --suffix=.bif /tmp/bootbin.XXXXXX)

echo_norm "the_ROM_image:" > ${TMPF}
echo_norm "{" >> ${TMPF}
echo_norm "\t[bootloader] ${bootloader_file}" >> ${TMPF}
if [ ! -z "${gw_file}" ] ; then
	echo_norm "\t${gw_file}" >> ${TMPF}
fi
echo_norm "\t${app_file}" >> ${TMPF}
echo_norm "}" >> ${TMPF}
echo_norm "" >> ${TMPF}

echo_norm "Generating BOOT.bin..."
${BOOTGEN} -image ${TMPF} -o ${bootbin_file} -w on
echo_ok "${bootbin_file} generated!"

exit 0
