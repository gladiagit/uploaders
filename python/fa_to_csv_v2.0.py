import sys
import os
#import Bio


# infile  assembly.version    outputfile    start-end   [bed]
if (sys.argv[-1] is "-h" )or  (sys.argv[-1] is "help" ) or (len(sys.argv)<3):
    print " arguments:\n infile  assembly.version    outputfile    start-end   [bed]"
    print "infile:\t-the input filename "
    print "assembly.version:\t-the assembly version and release number, when presuming a human genome assembly. Can be only the assembly version if the release is not known"
    print "outputfile:\t-the output filename"
    print "start-end:\t-[optional] only generates a file for positions between start and end (including start and end)"
    print "[bed]:\t-[optional] default output of the program is CSV but when using start-end we may also want BED formated files "
else:
    assembly=sys.argv[2].split(".")
    print "assembly: "+assembly[0]
    print "version: "+assembly[1]
    print "outputfile: "+sys.argv[3]
    from Bio import SeqIO
    record=SeqIO.read(sys.argv[1],"fasta")
    sub_record=record[1:10]
    start=0
    end=len(record)

    with open(sys.argv[3],'w+b') as f:
        try:
            sys.argv[4]        
        except :
            print "no coordinates given, and we can't have bed files qwithout coordinates"
            f.write("nucleotide,coordinate,assembly,assemblyVersion,chromosome,position\n")
            for i in range (start,end):
                f.write(str(record[i:i+1].seq)+","+"["+assembly[0]+"."+assembly[1]+"]"+record[i:i+1].id+":"+str(i+1)+","+assembly[0]+","+assembly[1]+","+record[i:i+1].id+","+str(i+1)+"\n")  
        else:
            if "-" in sys.argv[4]: 
                coords=sys.argv[4].split("-")
                start=int(coords[0])
                end=int(coords[1])
            else:
                start=0
                end=len(record)
            try:
                sys.argv[5]=='bed'
            except:
                f.write("nucleotide,coordinate,assembly,assemblyVersion,chromosome,position\n")
            else:
                print "we want bed files!"
            try:
                sys.argv[5]=='bed'
            except:
                for i in range (start,end):
                    f.write(str(record[i:i+1].seq)+","+"["+assembly[0]+"."+assembly[1]+"]"+record[i:i+1].id+":"+str(i+1)+","+assembly[0]+","+assembly[1]+","+record[i:i+1].id+","+str(i+1)+"\n")
            else:
                for i in range (start,end):
                    f.write(record[i:i+1].id+":"+str(i+1)+"-"+str(i+1)+"\n")
