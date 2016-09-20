#!/bin/sh

EXACPATH="/data1/home/nipm/jenica/Data/exac"
INFILE=$1
OUTFILE=$2
DBPATH="/data1/home/nipm/jenica/testDBs/neo4j-community-3.0.3"
DBNAMe="test.db"
NODE=$3

head -n 1 $EXACPATH"/curent/"$INFILE > $EXACPATH"/test/"$OUTFILE;
less $EXACPATH"/curent/"$INFILE |grep "chr21" >> $EXACPATH"/test/"$OUTFILE;

rm -r $DBPATH"/data/databases/"$DBNAME;
sh $DBPATH"/bin/neo4j-import" --into $DBPATH"/data/databases/"$DBNAME --nodes:$NODE $EXACPATH"/test/"$OUTFILE; 