#####################################################
# Jenica Abrudan, NIPM V1.1 09/21/2016              #
#####################################################
#!/usr/bin/env bash -x


EXACPATH="/data1/home/nipm/jenica/Data/csv/full_assembly"
CRIT="chr21"
EXACV="hg19"
INFILE=$1
NODE=$2
IN=$(echo $INFILE | rev| cut -f 1 -d "/"|rev)
TEMP=$(echo $IN |cut -f 1 -d "_")
OFILE=$EXACPATH"/test/"$TEMP"_"$CRIT"_assem_"$EXACV".txt"
DBPATH="/data1/home/nipm/jenica/testDBs/neo4j-community-3.0.3"
DBNAMe="test.db"

head -n 1 $INFILE > $OFILE;
less $INFILE |grep $CRIT >> $OFILE;

rm -r $DBPATH"/data/databases/"$DBNAME;
sh $DBPATH"/bin/neo4j-import" --delimiter "\t" --array-delimiter "|" --into $DBPATH"/data/databases/"$DBNAME --nodes:$NODE $OFILE; 