#
#
# Copyright (c) 2016 University of Granada
# Author: Miguel Jimenez Lopez <klyone@ugr.es>
# Distributed under the GNU GPL v2. For full terms see the file LICENSE.
#
#

TRUE=0
FALSE=1

function echo_norm {
	echo -e "$1"
}

function echo_err {
	echo -e "\033[0;31m$1\033[0m"
}

function echo_ok {
	echo -e "\e[42m$1\033[0m"
}

function check_var_defined {
	b=$TRUE
	if [ -z "$1" ] ; then
		b=${FALSE}
	fi
	
	return $b
}

function check_existence {
	check_var_defined $1
	
	b=$?
	
	if [ ! -e "$1" ] ; then
		b=${FALSE}
	fi
	
	return $b
}

function check_abs_path {
	b=$TRUE
	path=$1
	
	if [ "${path:0:1}" != "/" ] ; then
		b=${FALSE}
	fi
	
	return $b
}

function check_dir {
	check_existence $1
	b=$?
	
	if [ ! -d "$1" ] ; then
		b=${FALSE}
	fi
	
	return $b
}

function check_file {
	check_existence $1
	b=$?

	if [ ! -f "$1" ] ; then
		b=${FALSE}
	fi
	
	return $b
}

function assert {
	if [ $1 == ${FALSE} ] ; then
		echo_err "ERROR: $2"
		exit -1
	fi
}

function fail {
	assert ${FALSE} "$1"
}

function fakeroot_exec {
	fakeroot $2 $3 "$1"
}

function fakeroot_cmd {
	fakeroot_exec "$1" "bash" "-c"
}
