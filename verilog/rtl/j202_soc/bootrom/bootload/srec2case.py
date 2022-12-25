#!/usr/bin/python

#-----------------------------------------------
# Convert .srec(S3) to Verilog case format
#
# Usage: rec2case.py file.srec > file.v
#-----------------------------------------------

import sys
import re

args = sys.argv
with open(args[1], "r") as f:
    lines = f.readlines()

s3 = re.compile("^S3")
for line in lines:
    line = line[:-1]
    m = s3.search(line, 0)
    if m:
        size = int(line[2:4], 16)
        addr = int(line[4:12], 16) / 4
        data = line[12:-3]

        for i in range(0, len(data)):
            if (i % 8 == 0):
                d = "{:0<8}".format(data[i:i+8])
                print("32'h{addr:08x} : rd = 32'h{data};".format(addr=addr, data=d)).lower()
                addr = addr + 1

