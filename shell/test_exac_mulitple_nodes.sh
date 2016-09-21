#####################################################
# Jenica Abrudan, NIPM V1.0 09/20/2016              #
#####################################################
#!/bin/sh -x


EXACPATH="/data1/home/nipm/jenica/Data/exac"
CRIT="chr21"
EXACV="3.1_v3"
INFILE1=$1
NODE1=$2
INFILE2=$3
NODE2=$4
COL=$5        # the ID columns in INFILE1 and INFILE2 that can be used to create the relationship file 
REL=$6

TEMP1=$(echo $INFILE1 | rev| cut -f 1 -d "/"|rev|cut -f 1 -d "_")
TEMP2=$(echo $INFILE2 | rev| cut -f 1 -d "/"|rev|cut -f 1 -d "_")
OFILE1=$EXACPATH"/test/"$TEMP1"_"$CRIT"_exac_"$EXACV".txt"
OFILE2=$EXACPATH"/test/"$TEMP2"_"$CRIT"_exac_"$EXACV".txt"
RELFILE=$EXACPATH"/test/"$TEMP1"-"$TEMP2"_"$CRIT"_exac_"$EXACV".txt"
#COLS=$(echo $COL | cut -f 1,2 -d ,)
COL1=$(echo $COL | cut -f 1 -d ,)
COL2=$(echo $COL | cut -f 2 -d ,)
DBPATH="/data1/home/nipm/jenica/testDBs/neo4j-community-3.0.3"
DBNAME="test.db"

head -n 1 $INFILE1 > $OFILE1;
less $INFILE1 |grep $CRIT >> $OFILE1;
head -n 1 $INFILE2 > $OFILE2;
less $INFILE2 |grep $CRIT >> $OFILE2;
echo -e ":START_ID("$NODE1")\t:END_ID("$NODE2")" > $RELFILE;

paste <(cut -f $COL1 $OFILE1) <(cut -f $COL2 $OFILE2) | sed -e '1d' >> $RELFILE;
rm -r $DBPATH"/data/databases/"$DBNAME;
sh $DBPATH"/bin/neo4j-import" --delimiter "\t" --into $DBPATH"/data/databases/"$DBNAME --nodes:$NODE1 $OFILE1 --nodes:$NODE2 $OFILE2 --relationships:$REL $RELFILE; 