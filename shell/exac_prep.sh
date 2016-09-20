#!/bin/sh

EXACPATH="/data1/home/nipm/jenica/Data/exac"
COLS="2-19"
INFILE="all_full_exac_3.1_v3.txt"
OUTFILE="all_chr21_exac_3.1_v3.txt"

head -n 1 $EXACPATH"/curent/"$INFILE > $EXACPATH"/test/"$OUTFILE;
less $EXACPATH"/curent/"$INFILE |grep "chr21" >> $EXACPATH"/test/"$OUTFILE;