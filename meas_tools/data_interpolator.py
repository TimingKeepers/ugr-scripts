#!   /usr/bin/env   python3
#    coding: utf8
'''
A simple to generate new values for a measured variable using linear 
interpolation.

@file
@author Felipe Torres González (torresfelipex1<AT>gmail.com)
@date Created on Sep, 2017
@copyright GPL v3
'''

# Data Interpolator
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
from scipy.interpolate import interp1d
import numpy as np
import subprocess
import argparse as arg

def main():
    """Simple script for computing new values for discrete experimental vars"""
    parser = arg.ArgumentParser(description="Simple script for computing new values for discrete experimental vars")
    parser.add_argument('filein', metavar='FILEIN', type=str, help="Input file (remove before trailing whitespaces!)")

    args = parser.parse_args()

    FILEOUT = "%s_output.%s" % (args.filein.split(".")[0], args.filein.split(".")[1])
    #yesno = input("Output results will be saved in '%s', continue? y/n :"  % FILEOUT)

    #if yesno != 'y': exit(1)

    print("Parsing the input file, please wait...")

    with open(args.filein, 'r') as fi, open(FILEOUT, 'w') as fileout:
        # Format the header of the output file
        fileout.write("#\n")
        fileout.write("# Parsed output from the '%s' input file\n" % args.filein)
        fileout.write("#\n")
        
        # First load each column of the input file into a independent variable
        lines = fi.readlines()
        # Remove commented lines and check that there's no whitespaces at
        # the end of lines
        i = 0
        while lines[i][0] == "#": i+=1
        lines = lines[i:-1]
        if lines[0][-2] == " ":
            print("Please remove trailing whitespaces from the input file.")
            exit(1)
        
        vars = len(lines[0].split(" "))
        dataset = [None, ] * vars
        for i in range(vars):
            dataset[i] = []
            
        for line in lines:
            s = line.split(" ")
            i = 0
            for k in s:
                dataset[i].append(k)
                i+=1
                
        # Now cast the arrays from str to some numeric type
        dataset[0] = list(map(int, dataset[0]))
        i = 1
        for d in range(i,vars):
            dataset[i] = list(map(float, dataset[i]))
            i+=1
            
        # Data is ready to make a linear model
        f_pool = [None, ] * (vars-1)
        for k in range(1,vars):
            f_pool[k-1] = interp1d(dataset[0], dataset[k])
        
        # Generate the new vectors with real data and interpolated data
        n = dataset[0][-1] - dataset[0][0]
        ts_full = range(dataset[0][0], dataset[0][-1])
        for d in range(i,vars):
            dataset[d] = 0 # It's may a good idea to free some memory...
        
        fileout.write("# Automatic generated file from data_interpolator script\n#\n")
        
        for k in ts_full:
            l = "%d " % (k)
            for f in f_pool:
                l += "%.2f " % (f(k))
            t = l[:-1]+"\n"
            fileout.write(t)
        
        print("New values generated!")

#x=np.linspace(1505118019,1505137939,19920,True,dtype=int)

if __name__ == '__main__':
    main()

