#!   /usr/bin/env   python
#    coding: utf8
'''
A simple script to take some WR link variables and perform statistics.
Useful for calibration procedure.

@file
@author Felipe Torres González (torresfelipex1<AT>gmail.com)
@date Created on June, 2017
@copyright GPL v3
'''

# Calibration tool
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
import math
import time
import subprocess
import argparse as arg

# Define the shell command to retrieve the WR link status
# use -f to force refresh every read
MONITOR = "gpa_ctrl ppsi -f"

# Regular expressions
RTT_REGEX = r'servo/rtt.*\d+'
RRTT = re.compile(RTT_REGEX)
DRXM_REGEX = r'servo/drxm.*\d+'
RRXM = re.compile(DRXM_REGEX)
DRXS_REGEX = r'servo/drxs.*\d+'
RRXS = re.compile(DRXS_REGEX)

def main():
    """Simple script to compute the average and stdev of RTT or CRTT"""
    parser = arg.ArgumentParser(description="Simple script to compute the \
                                average and stdev of RTT or CRTT")
    parser.add_argument('--key', '-k', help='Key to filter and compute its statistics.',
                        dest="key", default="rtt")
    parser.add_argument('--samples', '-s', help="How many samples take to compute the average",
                        dest="samples", default=100, type=int)
    parser.add_argument('--interval', '-i', help="Time between samples", dest="inter",
                        default=0, type=int)

    args = parser.parse_args()

    print("Taking %d samples of %s (each %d s)..." %
          (args.samples, args.key, args.inter))

    values = [None, ] * args.samples

    if args.key == "rtt" or args.key == "crtt":
        regex = RRTT
    else:
        print("Invalid key used as argument (%s)" % args.key)
        exit(1)

    # Take bitslides to obtain the CRTT
    statout = subprocess.check_output([MONITOR], shell=True,
                                      stderr=subprocess.STDOUT,
                                      universal_newlines=True)
    drxm = int(RRXM.search(statout).group().split(":")[-1].strip())
    drxs = int(RRXS.search(statout).group().split(":")[-1].strip())
    print("BitSlides: M -> %d ps | S -> %d ps" % (drxm, drxs))
    sub = 0
    if args.key == "crtt":
        sub = drxm + drxs

    for i in range(args.samples):
        statout = subprocess.check_output([MONITOR], shell=True,
                                          stderr=subprocess.STDOUT,
                                          universal_newlines=True)

        values[i] = int(regex.search(statout).group().split(":")[-1].strip()) - sub
        time.sleep(args.inter)

    # Average
    avg = 0
    for i in range(args.samples):
        avg += values[i]
    avg /= args.samples

    # Standard Deviation
    std = 0
    for i in range(args.samples):
        std += (values[i]-avg)**2

    std = math.sqrt(std/args.samples)

    print("Average: %d ps | StDev: %d ps" % (avg, std))

if __name__ == '__main__':
    main()

