#!/usr/bin/python

import sqlite3
import os
import sys
import datetime

#import py2neo

# a 1000G formated VCF parser  (each column is a sample)
#python 1Gparser.py 1000Genome_file.vcf database table [user] [password] keyword
def lineparser(line,p):
   words=line.split("\t")
   vnotation=getnotation(line)
   people=gettallele(line,p)
   #affected=[]
   affected={}
   if (len(vnotation)==1):
     # affected.append(vnotation)
      for person in people:
       #  print person
         if (("alt" in people[person]["heterozygosity"]) or ("het" in people[person]["heterozygosity"])):
            affected.update({person:{"variant":vnotation[0],"heterozygosity":people[person]["heterozygosity"]}})
    #        affected.append(person)
#   info=get_info(line)
   return affected

def get_info (line):
   words=line.split("\t")
   alleles=get_alleles(words[4])
   info={}
   for i in range (len (alleles)):
      allele=alleles[i]
      coords=get_start_and_end(words[1],words[3],allele)
      vtype=get_variant_type(allele,words[3])
      vnotation=getnotation(line)
      info.update({vnotation[i]:{"chromosome":words[0],"start":coords[0],"end":coords[1],"notation":vnotation[i],"referenceNT":words[3],"alternativeNT":allele,"type":vtype,"qScore":words[5],"filter":words[6]}})
   return info
   
def get_start_and_end(start,ref,allele):
    """ infers start and end coordinate of the variant based on the type of mutation """
    mtype=get_variant_type(allele,ref)
    coords=[]
    if (mtype=="SNP" or mtype=="delins"):
        coords.append(start)
        coords.append(start)
    elif (mtype=="insertion"):
        coords.append(start)
        coords.append((int(start)+1))
    elif (mtype=="deletion"):
        coords.append((int(start)+1))
        coords.append((int(start)+(len(ref)-len(allele))))
    return coords
    
def getnotation(line):
    words=line.split("\t")
    notation=""
    alleles=get_alleles(words[4])
    chrom=words[0]
    nottemp="chr"+str(chrom)+":g."
 #   print " alleles are : "
    #get_variant_type(alleles)
    notation=[]
    for i in range(len(alleles)):
        mtype=get_variant_type(alleles[i],words[3])
        if (mtype=="SNP"):
            tnot=nottemp+str(words[1])+str(words[3])+">"+alleles[i]
        elif (mtype=="delins"):
            tnot=nottemp+str(words[1])+mtype+alleles[i]
        else:
            coords=get_start_and_end(words[1],words[3],alleles[i])
        #    print str(words[3])+" > "+str(alleles[i])+ " ("+str(alleles[i][:len(words[3])])+" )"
            if (mtype=="insertion"):
                nottemp+=str(coords[0])+"_"+str(coords[1])
            else:
                nottemp+=str(coords[0])
            # often for insertions they inculde the last letter of the reference in the alternative
            if (words[3]==alleles[i][:len(words[3])]):
                tnot=nottemp+mtype[:3]+alleles[i][len(words[3]):]
            elif ((mtype=="deletion")and (alleles[i]==words[3][:len(alleles[i])])):
                tnot=nottemp+mtype[:3]+words[3][len(alleles[i]):]
            else:
                tnot=nottemp+mtype[:3]+alleles[i]
            #print tnot
        notation.append(tnot)
       # print "allele"+str(i)+" = "+alleles[i]+ " is a "+mtype+ " with notations: "+tnot
    return notation

def get_variant_type(al,ref):
    """ infers the type of variant based on the size of the reference allele and the alternative allele """
    allele=str(al)
    #print "number of alleles "+str(len(alleles))
    mtype=""
#    print str(ref)+" > "+allele+ " reflen="+str(len(ref))
    if (len(ref)==len(allele)==1 and not allele.startswith(".")):
        mtype="SNP"
    elif (len(ref)==len(allele)>1 and ref!=allele):
  #      print" we have a delins!!!!!!!!!!!!"
        mtype="delins"
    elif (len(allele)>1):
        mtype="insertion"
    #elif ((len(allele)==1) and (allele.startswith(".") or len(ref)>1)):
    elif (len(ref)>len(allele) or (len(ref)==len(allele) and allele.startswith(".") )):
 #   elif (len(ref)>len(allele) )#or (len(ref)==len(allele) and allele.startswith(".") )):
       # print "we have deletion"
        mtype="deletion"
    #print " allele: "+alleles[i]+" is a "+mtype
    return mtype

def get_alleles(var):
    """ the function takes in a variant position and if there are multiple alleles at the same position it splits them into separate values """
    alt=str(var)
    alleles=[]
    if "," in alt:              # if we have more than one allele at that position it splits them into separate values
        alleles=alt.split(",")
    else:           
        alleles.append(alt)          # if there is actually only one change at one position it returns that change 
    return alleles
   
def gettallele(line,p):
   """ this functions assigns a char allele to each individuall patient"""
   words=line.split("\t")
   palleles=get_alleles(str(words[4]))    #possible alleles
   people={}
   ref=str(words[3])
   for k in range(9, len(words)):
 #  for k in range(9,12):
      if (len(palleles)==1):
         alleles=[]
         twords2=str(words[k]).split(":")
         twords3=str(twords2[0]).split("|")
    #     print "nalleles="+str(len(twords3))
         person=p[k]
         for i in range (len(twords3)):
            if (int(twords3[i])==1):
               alleles.append(str(words[4]))
            else:
               alleles.append(str(words[3]))
         if (str(alleles[0])==str(alleles[1])==str(words[3])):
            het="hom ref"
         elif (str(alleles[0])==str(alleles[1])==str(words[4])):
            het="hom alt"
            
         else:
            het="het"
         people.update({person:{"allele1":alleles[0],"alllele2":alleles[1],"heterozygosity":het}})
       #  print str(p[k])+" has "+str(alleles[0])+"/"+str(alleles[1])+" ("+ str(words[3])+" > "+str(words[4])+"-"+twords2[0]+" ) and is "+str(het)
   return people

def create_table(conn,table,pkey,headers):
    print "creating table"
    com=""
    heads=""
    for i in range(len(headers)):
        #if (headers[i]==pkey):
        #    print " wanted primary key: "+headers[i]
        #    heads+=headers[i]+" string primary key not null,"
      #  else:
            heads+=headers[i]+" string,"
    com="create table "+str(table)+" ("+str(heads)+" vid integer primary key autoincrement);"
    #print com
    conn.execute(com)
    conn.commit()

def split_values(variants, variant):
    hval=[]
    headers=""
    values=""
    for head in variants[variant].keys():
         headers+="'"+head+"',"
         values+="'"+str(variants[variant][head])+"',"
       
    hval.append(headers[:len(headers)-1])
    hval.append(values[:len(values)-1])
    return hval

def filereader(argu):
#   print "filename:\t"+str(argu[1])
#   print "database:\t"+str(argu[2])
#   print "table/node/vertex:\t"+str(argu[3])
#   if (len(argu)<6):#
#      print " no username or password given"
#   else:
#      print "user:\t"+str(argu[3])
#      print "password:\t"+str(argu[5])
#   print "dbType:\t"+str(argu[-1])
   db=argu[2]
   table=argu[3]
   headers=[]
   headers.append("notation")
   headers.append("chromosome")
   headers.append("start")
   headers.append("end")
   headers.append("referenceNT")
   headers.append("alternativeNT")
   headers.append("type")
   headers.append("qScore")
   headers.append("filter")
   if ("sqlite" in (argu[-1]).lower()):  
      f=open(argu[1])
      line=f.readline()
      #headers=[]
      first=0  
      p={}              #1000G IDs 
      i=0
      batch=0
      conn=sqlite3.connect(db)
      cursor=conn.cursor()
      com=" SELECT COUNT(*) FROM sqlite_master WHERE name ='"+table+"' and type='table'"
    #  com2=" SELECT COUNT(*) FROM sqlite_master WHERE name ='has_variant' and type='table'"  # this table will be created manually 
      cursor.execute(com)
      res=cursor.fetchone()
    #  while i<100:
      while line:
         line=line.rstrip("\n")
         if (not line.startswith("#")):
         #   print "line "+str(i)
            affected=lineparser(line,p)
            info=get_info(line)
            for variant in info:
               hval=split_values(info,variant)
               coms=[]
               com="INSERT or Ignore INTO "+str(table)+" ("+str(hval[0])+") VALUES ("+str(hval[1])+") ;"
               com2="INSERT or Ignore into has_variant (notation, personID, heterozygosity) values "
               people=""
#               for person in affected:
               k=1
            #   print "variant: "+str(variant)+" has "+str(len(affected))+" affected individuals"
               l=1;
               for person in affected:
                 # print "k="+str(k)
               #   print k
                #  print person
                  if k==50*l or k==len(affected) or len(affected)==1:
                     people+="(\""+str(variant)+"\","+"\""+str(person)+"\",\""+affected[person]["heterozygosity"]+"\""+"),"
                     coms.append(com2+people.rstrip(",")+";")
                     people=""
                     l+=1
                  else:
                     people+="(\""+str(variant)+"\","+"\""+str(person)+"\",\""+affected[person]["heterozygosity"]+"\""+"),"
                  k+=1
               print "variant: "+variant + "  people:"+str(len(affected))
               if (res[0]==0 and first==0):
               #   print "creating table"
                  create_table(conn,table,"notation",headers)
                  first=1
               else:
                #  print com
                  try:
                     cursor.execute(com)
                  except:
                     print "error on: " + str(com)
                  for j in range(len(coms)):
              #       print "\t"+ str(coms[j])
                     try:
                        conn.execute(coms[j])
                     except:
                        print "error on: " + str(coms[j])
                 # print
         elif line.startswith("#C"):
            print "headers!"
            words=line.split("\t")
            #for j in range(9):
         #      word=(words[j]).lstrip("#")
             #  headers.append(word)
            for k in range(9, len(words)):
               p.update({k:words[k]})
               
         i+=1
         line=f.readline()
         if (batch==10000):
            conn.commit()
            batch=0
         else:
            batch+=1
      conn.commit()
      conn.close()



print "start time: "+ str(datetime.datetime.now())
filereader(sys.argv)
print "end time: "+str(datetime.datetime.now())