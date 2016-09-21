#####################################################
# Jenica Abrudan, NIPM V1.0 09/20/2016              #
#####################################################
#!/bin/sh

EXACPATH="/data1/home/nipm/jenica/Data/exac"
CRIT="chr21"
EXACV="3.1_v3"
INFILE=$1
NODE=$2
IN=$(echo $INFILE | rev| cut -f 1 -d "/"|rev)
TEMP=$(echo $IN |cut -f 1 -d "_")
OFILE=$EXACPATH"/test/"$TEMP"_"$CRIT"_exac_"$EXACV".txt"
DBPATH="/data1/home/nipm/jenica/testDBs/neo4j-community-3.0.3"
DBNAMe="test.db"

head -n 1 $INFILE > $OFILE;
less $INFILE |grep $CRIT >> $OFILE;

rm -r $DBPATH"/data/databases/"$DBNAME;
sh $DBPATH"/bin/neo4j-import" --delimiter "\t" --into $DBPATH"/data/databases/"$DBNAME --nodes:$NODE $OFILE; 