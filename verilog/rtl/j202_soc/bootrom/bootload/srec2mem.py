#!/usr/bin/python

#-----------------------------------------------
# Convert .srec(S3) to Verilog $readmemh format
#
# Usage: rec2mem.py file.srec > file.mem
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
        addr = line[4:12]
        data = line[12:-3]
        print("@" + addr)

        for i in range(0, len(data)):
            if (i % 2 == 0):
                d = data[i:i+2]
                print(d)

