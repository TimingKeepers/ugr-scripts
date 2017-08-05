#!   /usr/bin/env   python3
#    coding: utf8
'''
A simple script for parsing data from the output of the WRC monitor.

@file
@author Felipe Torres González (torresfelipex1<AT>gmail.com)
@date Created on Aug, 2017
@copyright GPL v3
'''

# WRC monitor parser
# Copyright (C) 2017  Felipe Torres González (torresfelipex1<AT>gmail.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# System modules
import re
import os
import math
import time
import subprocess
import argparse as arg

def main():
    """Simple script to compute the average and stdev of RTT or CRTT"""
    parser = arg.ArgumentParser(description="Simple script for parsing WRC monitor's output.")
    parser.add_argument('--keys', '-k', help='Which keys should be catched.',
                        dest="keys", nargs='+')
    parser.add_argument('--ts', '-t', help='Add a timestamp for every record                        ("seed" "incr")', nargs=2)
    parser.add_argument('filein', metavar='FILEIN', type=str, help="Input file")

    args = parser.parse_args()
    ts_enabled = False

    regex_pool = []
    for i in args.keys:
        if i != "temp":
            temp_r = r"%s:(\d+)" % i
            regex_pool.append(re.compile(temp_r))
        elif i == "temp":
            regex_pool.append(re.compile(r'temp:.(\d{2}\.\d{2})'))

    FILEOUT = "%s_output.%s" % (args.filein.split(".")[0], args.filein.split(".")[1])
    yesno = input("Output results will be saved in '%s', continue? y/n :"  % FILEOUT)

    if yesno != 'y': exit(1)

    print("Parsing the input file, please wait...")

    with open(args.filein, 'r') as fi, open(FILEOUT, 'w') as fileout:
        # Format the header of the output file
        fileout.write("#\n")
        fileout.write("# Parsed output from the '%s' input file\n" % args.filein)
        fileout.write("#\n")
        fileout.write("# Columns:\n")
        fileout.write("# ")
        if args.ts:
            fileout.write("timestamp ")
            seed, incr = (int(args.ts[0]), int(args.ts[1]))
            ts_enabled = True

        for i in args.keys:
            fileout.write("%s " % (i))
        fileout.write("\n")
        if ts_enabled:
            fileout.write("%d " % seed)
            seed += incr

        # Now search for keys in the input file
        matched = 0
        for line in fi.readlines():
            # Sure it could be done better, but I'm lazy to learn perl.
            for r in regex_pool:
                temp = r.search(line)
                if temp is not None:
                    fileout.write("%s " % temp.groups()[0])
                    matched += 1
                    if matched >= len(args.keys):
                        fileout.write("\n")
                        if ts_enabled:
                            fileout.write("%d " % seed)
                            seed += incr
                        matched = 0

    # Remove dummy last line
    with open(FILEOUT, 'r+') as tfile:
        tfile.seek(0, os.SEEK_END)
        pos = tfile.tell() - len(str(seed)) - 2
        tfile.seek(pos, os.SEEK_SET)
        tfile.truncate()

if __name__ == '__main__':
    main()

