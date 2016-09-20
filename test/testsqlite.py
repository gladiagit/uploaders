#!/usr/bin/python
import sqlite3
import os
import sys
import datetime

def getdata(line,sep):
    words=line.split(sep)
    for i in range(len(words)):
        words[i]="'"+words[i]+"'"
    return words



conn=sqlite3.connect(sys.argv[1])
#c=conn.coursor
table=sys.argv[2]
print datetime.datetime.now()
f=open(sys.argv[3])
line=f.readline()

i=0
header=""
while line:
#while i in range(10):
#    print "in while"
    com=""
    line=line.rstrip("\n")
    if (i>=1):
      #  print line
        value=getdata(line,",")
        com="INSERT INTO "+table+" ("
        for j in range(len(header)-1):
            com+=header[j]+","
        com+=header[len(header)-1]+") VALUES ("
        for j in range(len(value)-1):
            com+=value[j]+","
        com+=value[len(value)-1]+");"
#        print com
        conn.execute(com)
    else:
        header=getdata(line,",")
  #  print com
    line=f.readline()
    i+=1
conn.commit()
print datetime.datetime.now()
f.close()
