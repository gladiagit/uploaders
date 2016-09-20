#!/usr/bin/perl

use strict;
use warnings;
my $npa=3;            # the minimum number of arguments to run the programs 

# the program will execute a temporary 3 json file using the orientDB oetl.sh program
# if database location is given, the program will use that value instead of the one in the settings file
# the database location will be used for both the running of the oetl.sh script and for uploading the data
my %inst=&setup_instructions;
if (&check_param($npa,"perl etl_pipeline.pl temporary_folder settings etl_template [database]",\@ARGV,\%inst))
{
    &main(@ARGV);
}

# a function to check the number of variable passed to a program (v1, 04/06/2016),
sub check_param
{
    my $n=$_[0];
    my $errorMessage=$_[1];     chomp($errorMessage);
    my $param_ref=$_[2];        chomp($param_ref);
    my $inst_ref=$_[3];         chomp($inst_ref);
    my %instructions=%{$inst_ref};
    my @params=@{$param_ref};
  
    if ((@params)&&($params[0] eq '-help') &&(%instructions)) 
    {
        foreach my $key  (sort keys %instructions)
        {
            print $key,"\t=\t".$instructions{$key}."\n";
        }
        return 0;
    }
    elsif ((!$param_ref) || ($#params<$n-1)  )
    {
        print $errorMessage."\n";
        return 0;
    }
    else
        {return 1;}
}
# a function to setup an instruction array
sub setup_instructions
{
    my %inst;
    $inst{'etl_pipeline.pl'}="program";
    $inst{'settings'}="a file containing the setings for the JSON file, things like database, connetion protocol, className and user information as well as metadata settings for data upload";
    $inst{'temporary_folder'}="the path where the jsonfile will be written to and executed from";
    $inst{'database'}="this parameter is optional but if its present it will be used instead of the same parameter in the settings file";
    $inst{'etl_template'}="a template for the JSON file used to update the metadata table in the DB";
 #   $inst{'class_template'}="a template file for the JSON final file containing the data to be uploaded to the databse";
    
    return %inst;
}

# a function that reads a text file and outputs an array address
sub read_file #v 1.0 09/17/2015
{
    my $filename=$_[0];                 chomp($filename);
    open(FILE,"<$filename")||die "Could not open file: $filename for reading in function read_file \n$!\n";
    my @data=<FILE>;                    chomp(@data);
    return @data;    
}
# a function that reads a text file and outputs an array address
# assumes that the data is tab delimineted and that there are only 3 columns
# propertyName  propertyValue   class/metadata
# class             - for the information to the uploaded to data vertex/edge
# metadata          - for data strictly for the TRACK_UPLOAD_VM vertex
# class,metadata    - for data to be uploaded both to the data vertex (or at least has to be part of the data JSON) and for the metadata vertex
# data checked for duplicates 
sub read_file_to_hash #v2.0 (04/08/2016)
{
    my $filename=$_[0];                 chomp($filename);
    my %hash;
    open(FILE,"<$filename")||die "Could not open file: $filename for reading in function read_file \n$!\n";
    my @data=<FILE>;                    chomp(@data);
    foreach my $line (@data)
    {
        if ($line!~ /^$/gi )
        {
            my @temp=split/\t/,$line;
         #   print "line: ".$line."\n";
         #   for (my $i=0;$i<=$#temp;$i++)
         #   {
         #       print "temp[$i]=".$temp[$i]."\n";
         #   }
         #   print "\n";
            if ($#temp>=2)
            {
                 my @temp2=split/,/,$temp[2];                     # checking to see if any information has to be placed in more than one class
                 foreach my $loc (@temp2)
                 {
                    if (! exists $hash{$loc}{$temp[0]})
                    {
                        if ($temp[1] ne '')
                        {
                            $hash{$loc}{$temp[0]}=$temp[1];
                        }
                        else
                        {
                            $hash{$loc}{$temp[0]}=1;
                        }
                        
                    }
                    else
                    {
                        print "WARNING: (".$temp[0].") is a duplicate\n";
                    }
                 }
            }
           
        }        
        
    }
    return %hash;    
}
# a function that give a filename will split it into path info and filname info (v2, 04/06/2016)
# the variables don't get squished together, as in if there is no file, the path variable is still in the $path 
# main assumption - a folder ends in /, files does not and the final folder doesn't contain . in the name
sub split_path
{
    my $filename=$_[0];      chomp($filename);
    my $file='';
    my $path='';
    
    my @temp=split/\//, $filename;
   #  for (my $i=0;$i<=$#temp;$i++)
   # {
   #     print"temp[$i]=".$temp[$i]."\n";
   # }
    #print "temp[".$#temp."]=".$temp[$#temp]."\n";
    #print "substr=". (lc substr($temp[$#temp], -1))."\n";
    if ((substr($filename, -1, ) ne '/')||($temp[$#temp]=~ /\./))
    {
        $file=$temp[$#temp];
    #    print "we have file :".$file."\n";
        if ($#temp>=1)
        {
            for (my $i=0;$i<$#temp-1;$i++)
            {
                $path.=$temp[$i]."/";
            }
        }
    }
    else
    {
        foreach my $value (@temp)
        {
            $path.=$value."/";
        }
     #  print "we only have a path\n$path\n";

    }
    return $file,$path; 
}
#a function to get the current time
sub get_time
{
    #my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    #printf("Time Format - HH:MM:SS\n");
    my %mon2num = qw(
  jan 1  feb 2  mar 3  apr 4  may 5  jun 6
  jul 7  aug 8  sep 9  oct 10 nov 11 dec 12
    );  

    
   # my $time=sprintf("%02d:%02d:%02d", $hour, $min, $sec);
   # my $date=sprintf("%04d-%02d-%02d",$year,$mon,$mday);
   # print $mon."\n";
#    my $datestring = gmtime();
    my $datestring = localtime();
    my @temp=split/\s{1,}/, $datestring;
#    print "GMT date and time $datestring\n";
  #  for (my $i=0;$i<=$#temp;$i++)
  #  {
  #      print"temp[$i]=".$temp[$i]."\n";
  #  }
    my $month= $mon2num{ lc substr($temp[$#temp-3], 0, 3) };
    my $datetime=$temp[$#temp]."-".(sprintf("%02d-%02d",$month,$temp[$#temp-2]))." ".$temp[$#temp-1];
 #   print "datetime=".$datetime."\n";
    return $datetime; 
}
# populate the metadata fields
# assumptions: only care to populate the metadata fields 
sub get_runtime_values
{
    my $hash_ref=$_[0];             chomp($hash_ref);
    my $flag=$_[1];                 chomp($flag);           # will be used to select between populating the dateOfStart or dateOfStop according to  situation
    my $time=$_[2];                 chomp($time);
    my $setfilen=$_[3];             chomp($setfilen);
    my %settings=%{$hash_ref};
    
    foreach my $location (sort keys %settings)
    {
        if ($location=~ /metadata/gi)
        {
            foreach my $setting (sort keys %{$settings{$location}})
            {
                if (($flag=~/start/gi) && (($setting=~ /dateOfStart/gi)||(($setting=~ /dateOfUpload/gi)))
                    &&($settings{$location}{$setting}==1)) 
                {
                    $settings{$location}{$setting}=$time;
                }
                elsif (($flag=~/stop/gi) )#&& (($setting=~/dateofstop/gi)||($setting=~/date*end/gi))&&($settings{$location}{$setting}==1))
                {
                     print "**************************************we aRE STOPPPOING****************************\n";
                    $settings{$location}{"dateOfStop"}=$time;
                }
                elsif ($setting=~/settings*file*/gi)
                {
                       $settings{$location}{$setting}=$setfilen;
                }
                elsif (($setting=~/totalNlines*/gi)||($setting=~/file*size*/gi))
                {
                 #   print "here "; # yeah , this section needs improvement [04/08/16]
                    my $command='less '.$settings{'class'}{'path'}.$settings{'metadata'}{'inFileName'}." | wc";
                    my $res=`$command`;
                    my @temp=split/\s+/,$res;
#                    print "size=".$#temp."\n";
                    $settings{$location}{$setting}=int($temp[1])-1;             
                }
               elsif (($setting eq 'completed') &&($settings{$location}{$setting} eq '1'))
               {
                    $settings{$location}{$setting}='false'; 
               }
                    
                
            }
          my $com="head -n 2 ".$settings{'class'}{'path'}."/".$settings{'class'}{'inFileName'}." | tail -n 1 ";
          my $res=`$com`;
          my @tempc=split/,|:/,$res;
          foreach my $val (@tempc)
          {
            if  ($val=~ /chr/gi)
            {
              $settings{'metadata'}{'chromosome'}=$val;
            }
            elsif ($val=~/GRCh/gi)
            {
            $settings{'metadata'}{'assembly'}=$val;
            }
          }
          
          print "\n".$res."\n";
        }
    }
    
    return %settings;    
        
}
# a function that adds a slass only if the last character is not a /
#version 1.0 (04/14/2016)
sub add_slash
{
    my $filename=$_[0];         chomp($filename);
    my $lastc=chop($filename);
    if ($lastc ne '/')
    {
        $filename.=$lastc."/";
    }
    else
    {
        $filename.="/";
    }
     
    return $filename;
}

# a function to create the csv temporary file for the metadata part of the upload 
sub create_csv
{
    my $temppath=$_[0];             chomp($temppath);
    my $flag=$_[1];                 chomp($flag);
    my $hash_ref=$_[2];             chomp($hash_ref);
    my %settings=%{$hash_ref};
    my $outfile='';
    my $headers='';
    my $values='';
    
    foreach my $location (sort keys %settings)
    {
        if ($location=~ /metadata/gi)
        {
            foreach my $setting (sort keys %{$settings{$location}})
            {
                $headers.=$setting.",";
                if ($settings{$location}{$setting}ne 1)
                {
                    $values.=$settings{$location}{$setting}.",";
                }
                else
                {$values.=",";}
                
            }
        }
    }
    my @temp=split/\s/,$settings{'metadata'}{'dateOfStart'};
#    $outfile=&add_slash($temppath).$settings{'metadata'}{'structuresAffected'}."_".$temp[0]."_start_upload.csv";
    $outfile=&create_filename($temppath,$settings{'metadata'}{'structuresAffected'}."_upload","csv","start");
    $headers=substr($headers,0,length($headers)-1);
    $values=substr($values,0,length($values)-1);
 #   print "headers: ".$headers."\n";
 #   print "values: ".$values."\n";
  #  print "outfile: ".$outfile."\n";
    open(OUT, ">$outfile") or die " could not open file $outfile for writing due to $!\n";
    print OUT $headers."\n";
    print OUT $values."\n";
    
    close(OUT);
    return $outfile;
}
# a function to generate the filename
sub create_filename
{
    my $tempf=$_[0];                chomp($tempf);      # the temporary folder where the file will be placed
    my $keyword=$_[1];              chomp($keyword);    # this will most likely be the vertex to be uploaded
    my $type=$_[2];                 chomp($type);       # the exteension of the filename
    my $flag=$_[3];                 chomp($flag);       # start/stop/upload foe the json files
    my $time=&get_time();
    my $filename="";
    my @temp=split/\s/, $time;
    
    $filename=&add_slash($tempf).$keyword."_".$temp[0]."_".$flag.".".$type;
#    print $filename."\n";   
    return $filename;
}
# a function taking a string and escaping characters such as / and whitespace
sub escape_chars
{
    my $string=$_[0];               chomp($string);
    my $nstring="";
#    print " looking to escape\n";
    if ($string=~ /\s/g)
    {
     #   print "we have white space in: '".$string."'\n";
        my @temp=split/\s/,$string;
        $nstring=$temp[0]."\\ ".$temp[1];
        
    }
    elsif ($string=~ /\//g)
    {
        $_=$string;
        $nstring=~ s/\//\\\//g;
        my @temp=split/\//,$string;
       for (my $i=0;$i<=$#temp;$i++)
        {
            if ($temp[$i]!~ /^$/gi)
            {
      #          print "temp[$i]=".$temp[$i]."\n";
                $nstring.="\\/".$temp[$i];
                
            }
            
            
#            $nstring.="\\/".$path;
        }
    }
    else
    {
        $nstring=$string;
    }
#    print "old string:'".$string."'\n";
#    print "new string:'".$nstring."'\n";
    
    return $nstring; 
# function to create the temporary json fil
}
sub create_etl
{
   my $tempf=$_[0];                 chomp($tempf);
   my $set_ref=$_[1];               chomp($set_ref);
   my $etltemp=$_[2];               chomp($etltemp);
   my $flag=$_[3];                  chomp($flag);
   my %settings=%{$set_ref};
   my $command="sed ";
   my $outfile=&create_filename($tempf,$settings{'metadata'}{'structuresAffected'},"json",$flag);
    my $s=&escape_chars($settings{'metadata'}{'fpath'});
    
    print "oufile: ".$outfile."\n";
    my $subcomm='';
    foreach my $field (keys %{$settings{'metadata'}})
    {
        if ($field ne 'fpath')
        {       
            print $field."=".$settings{'metadata'}{$field}."\n";
            my $s=&escape_chars($settings{'metadata'}{$field});
            $subcomm.="s/".$field."Value/".$s."/g;";
        }
    }
        
    if ($flag eq 'start')
    {
        print "we are starting\n";
        $command.="\'/Update/d; /skipDuplicates/d; ".$subcomm."s/fpathValue/".$s."/g;"."' <$etltemp"." >$outfile";
    }
    elsif ($flag eq 'upload')
    {
        my $fpath=&add_slash($settings{'class'}{'path'}).$settings{'class'}{'inFileName'};
        $command.="\'/Insert/d; /completed/d; ".$subcomm."s/fpathValue/".&escape_chars($fpath)."/g;"."' <$etltemp"." >$outfile";
    }
    elsif ($flag eq 'stop')
    {
        $command.="\'/Insert/d; /increment/d; /skipDuplicates/d;".$subcomm."s/fpathValue/".$s."/g;"."' <$etltemp"." >$outfile";
    }
    print "command: ".$command."\n";
    `$command`;
    
    return $outfile;
}
# the main subfunction
sub main
{
    my $tempfolder=$_[0];           chomp($tempfolder);
    my $settingsfile=$_[1];         chomp($settingsfile);
    my $etltempfile=$_[2];          chomp($etltempfile);
    my $dbinfo=$_[5];               if ($dbinfo) {chomp($dbinfo)}
    my $startime=&get_time;
    my %settings=&read_file_to_hash($settingsfile);
    my $db='';
    my $dbpath='';
    my ($setfilename,$setpath)=&split_path($settingsfile);
    
    if ($dbinfo)
    {
        ($db,$dbpath)=&split_path($dbinfo); #code
        $settings{'class'}{'database'}=$dbpath."databases/".$db;
        $settings{'metadata'}{'database'}=$dbpath."databases/".$db;
    }
    else
    {
        ($db,$dbpath)=&split_path($settings{'class'}{'database'});
         $dbpath=~ s/database//;
         $dbpath.="bin/";
    }

    $settings{'metadata'}{'password'}='admin';
    print "starting : ".$startime."\n";
    %settings=&get_runtime_values(\%settings,'start',$startime,$setfilename);
#    &create_filename($tempfolder,$settings{'metadata'}{'structuresAffected'}."_upload","json","start");
    $settings{'metadata'}{'fpath'}=&create_csv($tempfolder,"start",\%settings);
    my $comm1=&create_etl($tempfolder,\%settings,$etltempfile,"start");
    my $command="sh ".$dbpath."oetl.sh ".$comm1;
   print "\n\t".$command."\n";
    `$command`;
    my $comm2=&create_etl($tempfolder,\%settings,$etltempfile,"upload");
    $command="sh ".$dbpath."oetl.sh ".$comm2;
   print "\n\t".$command."\n";
    `$command`;
    my $stoptime=&get_time;
    %settings=&get_runtime_values(\%settings,'stop',$stoptime,$setfilename);
    my $comm3=&create_etl($tempfolder,\%settings,$etltempfile,"stop");
    $command="sh ".$dbpath."oetl.sh ".$comm3;
   print "\n\t".$command."\n";
   
 `$command`;
        print "starting : ".$stoptime."\n";

    print " ar the close\n"
}
