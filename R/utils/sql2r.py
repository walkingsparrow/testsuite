# convert sql data set to txt file that R can read

import re # regular expression
import sys

def convert (in_file, out_file):
    of = open(out_file, "w")
    count = 0
    for line in open(in_file):
        if line[0] == "{" or line[0:6] == "array[":
            count += 1
            elm = []
            for m in re.finditer(r"([^,\s\{\}]+)", line):
                elm.append(m.group(1))
            if count == 1:
                for i in range(len(elm)-1):
                    of.write("x" + str(i+1) + ",")
                of.write("y\n")
            for i in range(len(elm)):
                of.write(elm[i])
                if i != len(elm) - 1:
                    of.write(",")
                else:
                    of.write("\n")
    of.close()

if __name__ == "__main__":
    convert (sys.argv[1], sys.argv[2])

