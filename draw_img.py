#
# Written by Sangho Lee (sangho@gatech.edu)
#
import Image
import random
import sys

# 1000 x 1000 ?
pyimg = Image.new('RGB',(int(sys.argv[2]), int(sys.argv[3])))

flag = False

ll = []
aa = []
for line in open(sys.argv[1]):
        a = line.strip()
        if a == '00000000':
                continue

        ll.append((int('0x'+a[2:4],0), int('0x'+a[4:6],0), int('0x'+a[6:8],0)))

print len(ll)

pyimg.putdata(ll)
pyimg.show() # drag open the pill view window to see (its not large enough)
