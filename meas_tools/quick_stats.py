#!   /usr/bin/env   python3
#    coding: utf8
'''
A simple script for parsing a raw phase difference data file and obtain the
most common statistics.

@file
@author Felipe Torres González (torresfelipex1<AT>gmail.com)
@date Created on May, 2017
@copyright GPL v3
'''

# Script for parsing raw phase data files
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
import statistics as stat
import argparse as arg


class NoDataAvailable(Exception):
    """Used when no data is available to compute the stats"""
    pass


class PhaseDataParser():
    """
    Parser
    """
    # How many positions keep when rounding input measures
    ROUND = 14

    # Flag to indicate when the stats are computed
    statsComputed = False

    def __init__(self, fname):
        """
        Constructor

        Args:
            fname (str) : File name with the raw data
        """
        self._rawfile = open(fname, 'r')
        self._data = None

    def loadFile(self):
        """
        Read the raw file and load it into an array.
        """
        self._data = []
        for l in self._rawfile.readlines():
            self._data.append(float(l))

    def normalize(self, data=None):
        """
        Pass all read values to ps

        Args:
            data (array) : Input conatiner with
        """
        if data is None and self._data is None:
            raise NoDataAvailable("Please load some data before calling this \
                                   method.")

        # When external data is passed overwrite the internal array
        if data is not None:
            self._data = data

        for k in range(len(self._data)):
            self._data[k] = round(self._data[k], self.ROUND)

    def writeFile(self, output="output.dat", data=None):
        """
        Write internal data to a file
        """
        if data is None and self._data is None:
            raise NoDataAvailable("Please load some data before calling this \
                                   method.")

        if data is not None:
            self._data = data

        ofile = open(output, 'w')
        for k in self._data:
            ofile.write("%g" % k)

    def computeStats(self, data=None):
        """
        Compute the common stats for the data
        """
        if data is None and self._data is None:
            raise NoDataAvailable("Please load some data before calling this \
                                   method.")

        if data is not None:
            self._data = data

        self.statsComputed = True
        self.mean = stat.mean(self._data)
        self.stdev = stat.stdev(self._data)
        self.maximum = max(self._data)
        self.minimum = min(self._data)
        self.pktopk = self.maximum - self.minimum

        return (self.mean, self.stdev, self.pktopk)

    def printStats(self):
        """
        Print a quick overview of the data statistics
        """
        if not self.statsComputed:
            print("Please compute stats before.")
            return

        print("-- Stats ------------------------")
        print("-------- Mean    : %g\ts" % (self.mean))
        print("-------- StDev   : %g\ts" % (self.stdev))
        print("-------- Pk-to-Pk: %g\ts" % (self.pktopk))
        print("-------- Max     : %g\ts" % (self.maximum))
        print("-------- Min     : %g\ts" % (self.minimum))


def main():
    """Simple script to analyze raw phase data from csv files."""
    parser = arg.ArgumentParser(description='Raw phase data stats')
    parser.add_argument('FILEIN', type=str, help='Path to raw data file')
    args = parser.parse_args()

    if args.FILEIN:
        parser = PhaseDataParser(args.FILEIN)
        parser.loadFile()
        parser.normalize()
        parser.computeStats()
        parser.printStats()


if __name__ == '__main__':
    main()
