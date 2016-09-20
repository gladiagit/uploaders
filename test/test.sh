#!/bin/sh

DBPATH="/data1/home/nipm/jenica/testDBs/neo4j-community-3.0.3/"
DBName="test.db"
EXACPATH="/data1/home/nipm/jenica/Data/exac/curent"


sh $DBPATH"bin/neo4j-import" --into $DBPATH"data/databases/"$DBNAME
