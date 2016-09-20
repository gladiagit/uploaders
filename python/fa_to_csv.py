import sys
import os
#import Bio


# infile  assembly.version    outputfile    start-end   [bed]
#print sys.argv[1]
assembly=sys.argv[2].split(".")
print "assembly: "+assembly[0]
print "version: "+assembly[1]
print "outputfile: "+sys.argv[3]
from Bio import SeqIO
#handle=open(sys.argv[1],"rU")
#record_dict=SeqIO.to_dict(SeqIO.parse(handle,"fasta"))
#record_dict=SeqIO.index(sys.argv[1],"fasta")
#handle.close()
#print record_dict["chrX"]
record=SeqIO.read(sys.argv[1],"fasta")
sub_record=record[1:10]
#print len(sub_record)
#print sub_record.seq
#print record[62304:62305].seq
start=0
end=len(record)
 #   (start,end)=int(sys.argv[4].split("-"))  # not working
with open(sys.argv[3],'w+b') as f:
    try:
        sys.argv[4]        
    except :
        print "no coordinates given, and we can't have bed files qwithout coordinates"
        f.write("nucleotide,coordinate,assembly,assemblyVersion,chromosome,position\n")
        for i in range (start,end):
            f.write(str(record[i:i+1].seq)+","+record[i:i+1].id+":"+str(i+1)+","+assembly[0]+","+assembly[1]+","+record[i:i+1].id+","+str(i+1)+"\n")  
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
                f.write(str(record[i:i+1].seq)+","+record[i:i+1].id+":"+str(i+1)+","+assembly[0]+","+assembly[1]+","+record[i:i+1].id+","+str(i+1)+"\n")
        else:
            for i in range (start,end):
                f.write(record[i:i+1].id+":"+str(i+1)+"-"+str(i+1)+"\n")
