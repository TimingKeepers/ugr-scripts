#! /bin/bash

#
#
# Copyright (c) 2016 University of Granada
# Author: Miguel Jimenez Lopez <klyone@ugr.es>
# Distributed under the GNU GPL v2. For full terms see the file LICENSE.
#
#

#include util.sh

function help_msg {
	echo -e  "-------------------------------------------------------------------"
	echo -e  "$(basename $0) -p -u -r <rootfs> -i <image>"
	echo -e  ""
	echo -e  "Options:"
	echo -e  "\t-m: Mode (pack|unpack)"
	echo -e  "\t-c: Compress mode (none|gzip)"
	echo -e  "\t-r: Root filesystem folder"
	echo -e  "\t-i: Image name without extension"
	echo -e  "\t-h: Print help message"
	echo -e  ""
	echo -e  "Variable SCRIPT_BASE_FOLDER must contain repository parent folder"
	echo -e  ""
	echo -e  "-------------------------------------------------------------------"
	echo -e  "Copyright (C) 2015, University of Granada"
	echo -e  "Miguel Jimenez Lopez <klyone@ugr.es>"
	echo -e  "GPLv2 License or later"
	echo -e  "-------------------------------------------------------------------"
}

if [ -z ${SCRIPT_BASE_FOLDER} ] ; then
	help_msg
	echo "ERROR: SCRIPT_BASE_FOLDER var not defined!"
	exit -1
fi

. ${SCRIPT_BASE_FOLDER}/misc/util.sh

function uboot_image_unpack {
	case $3 in
		"none")
			TMPF=$(mktemp --suffix=.cpio /tmp/image.XXXXXX)
			fakeroot_cmd "dd if=\"$1\" bs=64 skip=1 of=\"${TMPF}\" && cd \"$2\" && cpio -i --no-absolute-filenames < \"${TMPF}\""
			;;
		"gzip")
			TMPF=$(mktemp --suffix=.cpio /tmp/image.XXXXXX)
			TMPF_GZ=$(mktemp --suffix=.gz /tmp/image.XXXXXX)
			fakeroot_cmd "dd if=\"$1\" bs=64 skip=1 of=\"${TMPF_GZ}\" && zcat \"${TMPF_GZ}\" > \"${TMPF}\" && cd \"$2\" && cpio -i --no-absolute-filenames < \"${TMPF}\""
			;;
		*)
			fail "unpack mode invalid: none | gzip"
			;;
	esac
}

function uboot_image_pack {
	case $3 in
		"none")
			TMPF=$(mktemp --suffix=.cpio /tmp/image.XXXXXX)
			fakeroot_cmd "shopt -s dotglob && cd \"$2\" && (find . | cpio -H newc -o > \"${TMPF}\") && mkimage -A arm -T ramdisk -C none -d \"${TMPF}\" \"$1\""
			;;
		"gzip")
			TMPF_GZ=$(mktemp --suffix=.gz /tmp/image.XXXXXX)
			fakeroot_cmd "shopt -s dotglob && cd \"$2\" && (find . | cpio -H newc -o | gzip > \"${TMPF_GZ}\") && mkimage -A arm -T ramdisk -C gzip -d \"${TMPF_GZ}\" \"$1\""
			;;
		*)
			fail "pack mode invalid: none | gzip"
			;;
	esac
}

while getopts ":m:c:r:i:h" opt; do
  case $opt in
    m)
	  mode="${OPTARG}"
	  
	  if [ ! "${mode}" == "pack" ] && [ ! "${mode}" == "unpack" ] ; then
		fail "The mode must be \"pack\" or \"unpack\"."
	  fi
	  
      ;;
	c)
	  compress="${OPTARG}"

	  if [ ! "${compress}" == "none" ] && [ ! "${compress}" == "gzip" ] ; then
	    fail "The compress mode must be \"none\" or \"gzip\"."
	  fi

	  ;;
	r)
	  rootfs_dir="${OPTARG}"
	  check_abs_path ${rootfs_dir}
	  file_ok=$?
		
	  assert $file_ok "\"${rootfs_dir}\" invalid, only absolute path are allowed!"
	  
      check_dir ${rootfs_dir}
      file_ok=$?
      assert $file_ok "\"${rootfs_dir}\" not found!"
      
	  ;;
	i)
	  image_file="${OPTARG}"
	  
	  check_abs_path ${image_file}
	  file_ok=$?
		
	  assert $file_ok "\"${image_file}\" invalid, only absolute path are allowed!"
	  
	  check_file ${image_file}
	  image_file_exists=$?
	  
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

if [ -z ${compress} ] ; then
	compress="none"
fi

if [ -z ${mode} ] || [ -z ${image_file} ] || [ -z ${rootfs_dir} ] ; then
	fail "You must specified the mode, image file and the rootfs folder!"
fi

if [ "${mode}" == "pack" ] ; then
	uboot_image_pack ${image_file} ${rootfs_dir} ${compress} && echo_ok "U-Boot image packed!"
else
	assert ${image_file_exists} "${image_file} not found!"
	uboot_image_unpack ${image_file} ${rootfs_dir} ${compress} && echo_ok "U-Boot image unpacked!"
fi

exit 0
