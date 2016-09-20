#!/usr/bin/python

import os
import sys
import datetime
import sqlite3



# a program that takes in a setings file containg the tabldelim file info, the database and the table to query
# python nutriquery.py settings 
#def fileparser(file):
#	pass
#def dataaccess(database, table, vof, values):
#	pass
#def get_settings(file):
#	pass

def get_settings(file):
	""" a routine meant to get the basic information for db parsing from a file """ 
	settings={}
	f=open(file)
	line=f.readline()
	while line:
		line=line.rstrip("\n")
		words=line.split("\t")
		settings.update({str(words[0]):str(words[1])})
		line=f.readline()
	#print "here we are:"
	#print settings
	return settings

def file_parser(file, col=0):
	""" a generalized function for tab delim files with the headers on the first line of the file. v1.0 06/08/16"""
	data={}
	headers=[]
	f=open(file)
	line=f.readline()
	i=1;
	while line:
		line=line.rstrip("\n")
		if (i==1):
			headers=line.split("\t")
		else:
			words=line.split("\t")
			for j in range(len(words)):
				data.update({str(words[col]):{str(headers[j]):str(words[j])}})
		line=f.readline()
		i+=1
	f.close()
	return data

def get_col_from_vof(file, vof):
	""" a function that using the the vof(=value of interest) returns its column number in the idea to be used as a unique identifier for the dataset"""
	col=-1
	f=open(file)
	line=f.readline()
	headers=line.split("\t")
	for j in range(len(headers)):
		if str(vof).lower() in str(headers[j]).lower():
			col=j
	return col

def construct_query(table,rcol,wcol,wcolval,gcol=""):
#	rcol=header of column to be return
#	wcol=header of column to be used for the where clause
#	gcol=header of column to be used for group by
	query="SELECT "+str(rcol)+" FROM "+str(table)+" WHERE "
	wcols=str(wcol).split(",")
	if (len(wcols)==1):
		query+=str(wcol)+"='"+str(wcolval)+"' "
	else:
		wcolvals=str(wcolval).split(",")
		for i in range(len(wcols)-1):
			query+=str(wcols[i])+"='"+str(wcolvals[i])+"' AND "
		query+=str(wcols[len(wcols)-1])+"='"+str(wcolvals[len(wcols)-1])+"' "
	if not gcol is "":
		query+=" GROUP BY "+str(gcol)+";"
	else:
		query+=";"
#	print query
	return query
	
def db_search(db,settings,data):
	#try:
	print "database : "+db
	results={}
	conn=sqlite3.connect(db)
	cursor=conn.cursor()
	for key in data:
		scom1=construct_query(settings['table1'],settings['ccol1'],settings['vof'],str(key))
		cursor.execute(scom1)
	#	result=cursor.fetchall()
#		result=cursor.fetchone()
		for result in cursor:
#		print len(result)
			if (len(result)==1):
				#print result
				scom2=construct_query(settings['table2'],settings['ccol2'],settings['ccol1'],str(result[0]),settings['gcol2'])
				cursor.execute(scom2)
				temp={}
				for ns in cursor:
#					print str(key)+"\t"+str(ns[0])+"\t"+str(ns[1])
					temp.update({str(ns[0]):str(ns[1])})
				results.update({str(key):temp})
#	print results
	return results
	#except:
	#	print "couldn't open the database"


# the main block
if (len(sys.argv)<3):
	print "too few arguments:\n python nutriquery.py settings_filename database"
	pass
else:
	sets=get_settings(sys.argv[1])
	col=get_col_from_vof(sets['file'],sets['vof'])
	data=file_parser(sets['file'],col)
	print "we have "+str(len(data))+" values"
	#conn=sqlite3.connect(sys.argv[2])
	results=db_search(sys.argv[2],sets,data)
	for key in results:
#		print str(key)+"\t"+str(results[key]['het'])+"\t"+str(results[key]['hom alt'])
		#for hetero in results[key]:
		#	print hetero[0]                         
		#	print hetero[1]
#			print str(key)+"\t"+str(hetero)+"="+str(results[key]['hom alt'])
		try:
			print str(key)+"\t"+str(results[key]['het'])+"\t"+str(results[key]['hom alt'])
		except:
			print "issues with "+str(key)