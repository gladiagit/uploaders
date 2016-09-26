#!/usr/bin/perl
#####################################################
# Jenica Abrudan, NIPM V1.0 09/22/2016              #
#####################################################
use strict;
use warnings;

if (($#ARGV<3) || ($ARGV[0]eq '-h') || ($ARGV[0] eq 'help'))
{
   print "perl ".$0." exac_tab_separated_file split_settings_file output_filename_template realtionship_file [delim]\n\n";
   print "exac_tab_separated_file :\n\t the exac file processed to be separated into columns\n";
   print "split settings file :\n\t a file in the format :\t column_name\tcolumn_number\tclass_name\n";
   print "output_filename_template :\n\t how to name the output files. it has to include the location of the files\n";
   print "relationship_file:\n\t a file [delim] separated containing the relationships between classes. \n\t Make sure the first column in the file contains unique values and that the first row contains the TO/FROM keys \n";
   print "[delim] :\n\t optional paramater for the case where the exac file is separated by a different character (default is {tab}\n"; 
}
else
{
   &main(@ARGV);
}
# v1 (09.22.16 - reads a file and outputs the content into a hash by spliting the file into a given number of columns
# assumption : the first line in the file contains numes for the values in each column
sub read_file_to_hash  
{
   my $file=$_[0];         chomp($file);                  # the file to be split, the first column will used as keys for the rest of the values
   my $delim=$_[1];         if ($delim) {chomp($delim);}   # the delimiter to be used for spliting the file, \t for default 
                              else {$delim="\t";}
   my $flag=$_[2];          if ($flag) {chomp($flag);}
                              else {$flag='true';}
   my %file;
   my $startline=1;
#   print "delim :".$delim.":\n";
#   print "reading\n";
   open(IN,"<$file") || die "could not open $file for opening in ".(caller(0))[3]." due to $!\n";
   my @data=<IN>;          chomp(@data);
   my @headers;
   if ($flag eq 'true')
   {
      @headers=split($delim,$data[0]);
   }
   else
   {
      my @temp2=split/$delim/,$data[0];
      for (my $i=0;$i<=$#temp2;$i++)
      {
         push @headers,($i+1);
      }
      $startline=0;
   }
   
 #  print "nheaders ".($#headers+1)."\n";
   for (my $j=$startline;$j<=$#data;$j++)
   {
      
      my @temp=split/$delim/,  $data[$j];
      #print $line."\n";
#      print "n cols = ".($#temp+1)."\n";
      for (my $i=1;$i<=$#temp;$i++)
      {
  #       print $temp[0]." - ".$headers[$i]." = ".$temp[$i]."\n";
         $file{$temp[0]}{$headers[$i]}=$temp[$i];        # skiping the name of the first column because that is the hash key 
      }
   }
   #print "keys ".(keys %file)."\n";
   return %file;
}


# v1 (09.24.2016)  - a general function for printing out a two level hash
sub print_2l_hash
{
   my $hash_ref=$_[0];        chomp($hash_ref);
   
   my %hash=%{$hash_ref};
   
   foreach my $key1 (keys %hash)
   {
      print $key1.":\n";
      foreach my $key2 (keys %{$hash{$key1}})
      {
         print "\t".$key2." - ".$hash{$key1}{$key2}."\n";
      }
   }
   
}
# a function to generate command lines commands for file spliting
sub get_classes
{
   my $info_ref=$_[0];     chomp($info_ref);
   my %info=%{$info_ref};
   my %classes;

   foreach my $column (keys %info)
   {
#      print $column;
      my $once=1;
      foreach my $key (keys %{$info{$column}})
      {
         if ($info{$column}{'Class'}!~ /,/gi)
         {
            if (!exists $classes{$info{$column}{'Class'}})
            {
               if ($once==1)
               {
                  push @{$classes{$info{$column}{'Class'}}{'col_order'}},$info{$column}{'Number'};
                  $once=2;
               }
            }
            else
            {
               if ($once==1)
               {
                  push @{$classes{$info{$column}{'Class'}}{'col_order'}},$info{$column}{'Number'};
                  $once=2;
               }
            }
         }
         else
         {
            my @temp=split/,/ , $info{$column}{'Class'};
           # print "onece=".$once."\n";
           if ($once==1)
           {
               foreach my $class (@temp)
               {
                  push @{$classes{$class}{'col_order'}},$info{$column}{'Number'};
                }
            $once=2;
           }
         }
      }
   }
   return \%classes;
}
# a function to replace the top row to contain column type infp
sub get_nline
{
   my $info_ref=$_[0];     chomp($info_ref);
   my $class_ref=$_[1];    chomp($class_ref);
   my %info=%{$info_ref};
   my %classes=%{$class_ref};
   
   foreach my $class (keys %classes)
   {
#      print $class.":\n\t";
      foreach my $ncol (sort {$a<=>$b} @{$classes{$class}{'col_order'}})
      {
#         print $ncol."-";
         foreach my $col (keys %info)
         {
            if ($info{$col}{'Number'}==$ncol)
            {
               if ($info{$col}{'Type'} eq 'ID')
               {
#                  print $col.":".$info{$col}{'Type'}."(".$class.")"."\t";
                  $classes{$class}{'nline'}.=$col.":".$info{$col}{'Type'}."(".$class.")"."\t";
               }
               else
               {
#                  print $col.":".$info{$col}{'Type'}."\t";
                  $classes{$class}{'nline'}.=$col.":".$info{$col}{'Type'}."\t";
               }
               $classes{$class}{'oline'}.=$col."\t";
            }
         }
      }
      chop($classes{$class}{'nline'});
      chop($classes{$class}{'oline'});
      #print $classes{$class}{'nline'};
      #print "\n";
   }
   return \%classes;
}
# a function to generate the command lines
sub generate_coms
{
   my $class_ref=$_[0];    chomp($class_ref);
   my $filetemp=$_[1];     chomp($filetemp);
   my $infile=$_[2];       chomp($infile);
   my $info_ref=$_[3];     chomp($info_ref);
   my ($fname,$fpath)=split_full_path($filetemp);
    
   my %classes=%{$class_ref};
   my %info=%{$info_ref};
   
   foreach my $class (keys %classes)
   {
      my $ofile=$fpath."nodes/".$fname."-".$class.".txt";
      $classes{$class}{'out_file'}=$ofile;
      my $cutcom="cut -f ";
      my $sedcom="sed -i ";
      my $first=1;
      foreach my $n (sort {$a<=>$b} @{$classes{$class}{'col_order'}})
      {
         if ($first==1)
         {
            $cutcom.=$n;
            $first=2;
         }
         else
         {
            $cutcom.=",".$n;
         }
         foreach my $col (keys %info)
         {
            if ($info{$col}{'Number'}==$n)
            {
               if ($info{$col}{'Type'} ne 'ID')
               {
                  $sedcom.="-e 's/".$col."/".$col.":".$info{$col}{'Type'}."/' ";
               }
               else
               {
                  $sedcom.="-e 's/".$col."/".$col.":".$info{$col}{'Type'}."(".$class.")/' ";
                  $classes{$class}{'id_col'}=$n;
                  $classes{$class}{'id_name'}=$col;
               }
            }
         }
      }
      if ((($#{$classes{$class}{'col_order'}}+1)>=2) && ($class ne 'IGNORE'))
      {
         $classes{$class}{'sed_command'}=$sedcom." ".$classes{$class}{'out_file'};
         $cutcom.=" ".$infile." > ".$ofile;
         $classes{$class}{'cut_command'}=$cutcom;
      }
    #  $classes{$class}{'sed_command'}="sed -i 's/".$classes{$class}{'oline'}."/".$classes{$class}{'nline'}."/' ". $classes{$class}{'out_file'};
   }
#   foreach my $class (keys %classes)
#   {
#      print "class: ".$class."\n\t";
#      print "new line:\t".$classes{$class}{'nline'}."\n";
#      print "output filename:\t".$classes{$class}{'out_file'}."\n";
#      print "cut command:\t".$classes{$class}{'cut_command'}."\n";
#      print "sed command:\t",$classes{$class}{'sed_command'}."\n";
#      print"\n";
#   }
   return \%classes;
}
# V1 (09/25/2016) a function that takes in a full path and returns the filename and path separately
sub split_full_path
{
   my $full=$_[0];        chomp($full);
   my $name="";
   my $path="";
   
   my @temp=split/\//, $full;
   for (my $i=0;$i<  $#temp;$i++)
   {
   #   print "temp[$i]=".$temp[$i]."\n";
      $path.=$temp[$i]."/";
   }
   $name=$temp[$#temp];
   return $name,$path;
}
# a function to generate relationships files
sub generate_rel_coms
{
   my $rel_ref=$_[0];      chomp($rel_ref);
   my $class_ref=$_[1];    chomp($class_ref);
   my $filetemp=$_[3];     chomp($filetemp);
   my $infile=$_[2];       chomp($infile);
   my  %rels=%{$rel_ref};
   my  %classes=%{$class_ref};
   my ($fname,$fpath)=split_full_path($filetemp);
   foreach my $class1  (keys %rels)
   {
      my $cutcom="cut -f ";
      my $sedcom="sed -i ";
      my $ofile=$fpath."relationships/".$fname."_";
      foreach my $rel  (keys %{$rels{$class1}})
      {
         if ($rel=~/to/gi)
         {
            $ofile.=$class1."-".$rels{$class1}{$rel}."-".$rels{$class1}{'Name'}.".txt";
          #  print $class1 ." to  ".$rels{$class1}{$rel}." (".$classes{$class1}{'id_col'}."-".$classes{$rels{$class1}{$rel}}{'id_col'}.")"."\n";
            $cutcom.=$classes{$class1}{'id_col'}.",".$classes{$rels{$class1}{$rel}}{'id_col'};
            $sedcom.=" -e 's/".$classes{$class1}{'id_name'}."/:START_ID(".$class1.")/' -e 's/".$classes{$rels{$class1}{$rel}}{'id_name'}."/:END_ID(".$rels{$class1}{$rel}."/'";
         }
         elsif ($rel=~/from/gi)
         {
            $ofile.=$rels{$class1}{$rel}."-".$class1."-".$rels{$class1}{'Name'}.".txt";
           # print $rels{$class1}{$rel}. " to ".$class1 ." (".$classes{$rels{$class1}{$rel}}{'id_col'}."-".$classes{$class1}{'id_col'}.")"."\n";
            $cutcom.=$classes{$rels{$class1}{$rel}}{'id_col'}.",".$classes{$class1}{'id_col'};
            $sedcom.=" -e 's/".$classes{$class1}{'id_name'}."/:START_ID(".$class1.")/' -e 's/".$classes{$rels{$class1}{$rel}}{'id_name'}."/:END_ID(".$rels{$class1}{$rel}."/'";
       
          }
         $rels{$class1}{'sed_command'}=$sedcom." ".$ofile;
         $rels{$class1}{'cut_command'}=$cutcom."  ".$infile." > ".$ofile;       
      }
      $rels{$class1}{'ofile'}=$ofile;
   }
#   foreach my $class (keys %rels)
#   {
#      print $class."\n";
#      foreach my $key (keys %{$rels{$class}})
#      {
#         print "\t".$key." : ".$rels{$class}{$key}."\n";
#      }
#      print "\n";
#   }
   return \%rels;
}
# a function that prints out the commands l
sub generate_script
{
   #upgrade ideas: don't create files for classes containing only ID column (09/25/2016)
   my $class_ref=$_[0];   chomp($class_ref);
   my $fexac=$_[1];        chomp($fexac);    # the full tab separated exac file
   my $fset=$_[2];         chomp($fset);     # the file containing the instructions as to which columns belong to which classes
   my $ftemp=$_[4];        chomp($ftemp);    # the output filename temaplate
   my $frel=$_[3];         chomp($frel);
   my $rels_ref=$_[5];     chomp($rels_ref);

   my %classes=%{$class_ref};
   my %rels=%{$rels_ref};
   my ($fname,$fpath)=split_full_path($ftemp);   
   my $fshell=$fpath.$fname."_prepare.sh";
   open(OUT,">$fshell") || die "could not open $fshell in $0 due to $!\n";
   use Time::localtime;

   my (@temp)=@{localtime(time)};
#   print $day ." today\n";
#      for (my $i=0;$i<=$#temp;$i++)
#      {
#         print "temp[$i]=".$temp[$i]."\n";
#      }
   my $date=($temp[4]+1)."/".$temp[3]."/".($temp[5]+1900);
   #to be changed for better looking (09/25/16)
   print OUT "#!/usr/bin/env bash -x\n";
   print OUT "####################################################################################################################\n";
   print OUT "# input file:";
   printf OUT "%100s #\n",$fexac;
   print OUT "# input classes:";
   printf OUT  "%100s #\n",$fset;
   print OUT "# input relationships:";
   printf OUT "%90s #\n",$frel;
   print OUT "# output filename template:";
   printf OUT  "%80s\n",$ftemp;
   print OUT "# generated on:";
   printf OUT "%100s #\n",$date;
   print OUT "# script generated using:";
   printf OUT "%90s #\n",$0;
   print OUT "############################################################################################################3#######\n\n";
   
   print OUT "mkdir ".$fpath."/nodes;\n";
   print OUT "mkdir ".$fpath."/relationships;\n";
   foreach my $class (keys %classes)
   {
      if (exists  $classes{$class}{'cut_command'})
      {
         print OUT  $classes{$class}{'cut_command'}.";\n";
         print OUT $classes{$class}{'sed_command'}.";\n";
      }
   }
   foreach my $class (keys %rels)
   {
      print OUT $rels{$class}{'cut_command'}.";\n";
      print OUT $rels{$class}{'sed_command'}.";\n";
   }
}
sub main
{
   my $fexac=$_[0];        chomp($fexac);    # the full tab separated exac file
   my $fset=$_[1];         chomp($fset);     # the file containing the instructions as to which columns belong to which classes
   my $ftemp=$_[2];        chomp($ftemp);    # the output filename temaplate
   my $frel=$_[3];         chomp($frel);     #file with relationships 
   my $fdel=$_[4];         if ($fdel) {chomp($fdel);}
                        else {$fdel="\t";}
   
   my %data=read_file_to_hash($fset,$fdel,"true");
  # print_2l_hash(\%data);
   my %rels=read_file_to_hash($frel,$fdel,"true");

   my $class_ref=get_classes(\%data);
   ($class_ref)=get_nline(\%data,$class_ref);
   ($class_ref)=generate_coms($class_ref,$ftemp,$fexac,\%data);
    my ($rel_ref)=generate_rel_coms(\%rels,$class_ref,$fexac,$ftemp);
     generate_script($class_ref,$fexac,$fset,$frel,$ftemp,$rel_ref);
}