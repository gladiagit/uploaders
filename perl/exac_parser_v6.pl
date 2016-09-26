#!/usr/bin/perl
use warnings;
use strict;
my $first=0;         #to be used to print the headers 
#program assumptions
# if there is a 
if (($#ARGV<2) || ($ARGV[0]eq '-h') || ($ARGV[0] eq 'help'))
{
   print "perl $0 input_file output_file delimitator full/split:settings file\n\n";
   print "input_file:\t Input EXAC VCF file\n";
   print "output_file:\t Output filename/filename template if the option is for split\n";
   print "delimitator:\t output file column separator \n";
   print "split/full:\t separate the different columns into different files\n";
}
else
{
   &main(\@ARGV);
}


# a function to retrieve all possible headers from the VCF, based on the assumption that the each type of value is
# ##INFO <ID=.... / ##FORMAT <ID=.....

sub get_headers
{
   my $file=$_[0];      chomp($file);
   my %headers;
   
   open(HEAD,"<$file") || die "could not open $file for reading $!\n";
      
  # while ((my $line=<HEAD>) && (substr($line,0,1) eq '#'))
  my $nhead=0;       # just for testing, to count the number of rows with comments
  my $nlines=0;
  
  while (my $line=<HEAD>) 
   {
      chomp($line);
      if (substr($line,0,2) eq '##')
      {
         if ((substr($line,0,7) eq '##INFO=')||(substr($line,0,9) eq '##FORMAT='))
         {
#            print $line ."\n";
            my @temp=split/=/, $line;
#            print "we have:".$#temp." vals\n";
#            for (my $i=0;$i<=$#temp;$i++)
#            {
#               print $nlines.": temp[$i]=".$temp[$i]."\n";
#            }
               my @temp2=split/,/, $temp[2];
 #              print $temp2[0]," column\n";
 #           print"\n";
            if ((! exists($headers{$temp2[0]})) &&($temp2[0] ne 'CSQ'))
            {
               $headers{$temp2[0]}=1;
            }
            elsif ($temp2[0] eq 'CSQ')
            {
               $temp[5]=~ s/"|\s|>//g;
               my @temp3a=split /:/,$temp[5];
               my @temp3b=split/\|/, $temp3a[1];
               for (my $i=0;$i<=$#temp3b;$i++)
               {
                 # print "temp3b[$i]=".$temp3b[$i]."\n";
                  if (!exists($headers{'CSQ'}{$temp3b[$i]}))
                  {
                     $headers{'CSQ'}{$temp3b[$i]}=$i;  
                  }
                  else
                  {
                     print $temp3b[$i]." header already present\n";
                  }
               }
            }
            $nhead++;
         }
         #print substr($line,0,2)."\n";
      }
      
         else
      {
    #     print "in the get_headers function, we have $nhead headers\n";
    #     print "we went through $nlines lines\n";

         return %headers;
      }
      $nlines++;
   }

}

# a function that returns the alleles and calculates their length 
sub get_alleles
{
   my $string=$_[0];        chomp($string);
   my %alleles;
   my @temp=split/,/, $string;
  # print "we have ".($#temp+1)." alleles in ".$string."\n";
   for (my $i=0;$i<=$#temp;$i++)
   {
      if (! exists ($alleles{$temp[$i]}))
      {
         $alleles{$temp[$i]}{'length'}=length($temp[$i]);
         $alleles{$temp[$i]}{'order'}=$i;
      }
   }
   return %alleles;
}
sub get_dpos
{
   my $s1=$_[0];                chomp($s1);
   my $s2=$_[1];                chomp($s2);
   my $pos=0;
   my $mask = $s1 ^ $s2;
   my $first=0;
   
   while ($mask =~ /[^\0]/g)
   {
      if (!$first)
      {
         $pos=$-[0];
         $first=1; 
         }
   }
   return $pos;
}
# a function that returns the type of variant
sub get_var_type
{
   my $var=$_[0];                  chomp($var);
   my $ref=$_[1];                  chomp($ref);
   my $type='';
   my $callele=$var;                     # for the case when the alternative allele has to be corrected
   my $pvar=-1;                     #the position in the variant where its actually different from reference - to be used when calculating real ins/del postion         
#   print "comparing : $var (var) and $ref (ref) \n";
   
   if (($ref eq '.') && ($var ne '.'))
   {
      $type="insertion";
   }
   elsif (($ref ne '.') && ($var eq '.'))
   {
      $type="deletion";
   }
   elsif (($ref ne '.') && ($var ne '.'))  # most often this will be the case
   {
      if ((length($var)==length($ref)) &&($ref ne $var))          # the alt and ref have the same length but not the same value 
      {
         if (length($var)==1)
            {$type="SNP";}
         else
            {$type="delins";}
         $pvar=&get_dpos($var,$ref);
 #        print $var."-".$ref." ($pvar)\n";
      }
      elsif (length($var)>length($ref))
      {
         $type='insertion';
         $pvar=&get_dpos($var,$ref);
      }
      elsif (length($var)<length($ref))
      {
         $type='deletion';
         $pvar=length($ref)-length($var);
        # $pvar=&get_dpos($ref,$var);
       #  print "pvar=".$pvar."\n";
      }
   }
   if (($pvar>0)&& ($type ne 'deletion'))       # for deletions, pvar shuould have the length of ref getting deleted
   {
#      print "************************************\n";
      $callele=substr($var,$pvar,length($var)-1);
   }
   elsif ($type eq 'deletion')
   {
      $callele='.';
   }
   return $type,$callele,$pvar;
}
# a function to retrieve the INFO fields
sub split_info
{
   my $info=$_[0];                  chomp($info);
   my $n=$_[1]; 
   my @temp=split/;/,$info;         chomp(@temp);
   my %info;
   
   for(my $i=0;$i<=$#temp;$i++)
   {
      my @temp2=split/=/,$temp[$i];
 #     print "temp[$i]=".$temp[$i]." - ".($#temp2+1)."\n";
      if (!exists($info{$temp2[0]}))
      {
         if ($temp2[0]=~ m/_TRAIN_SITE/g)
         {
            $info{$temp2[0]}=1;
         }
         else
         {
            my @temp3=split/,/,$temp2[1];
            if ($#temp3>=1)
            {
               $info{$temp2[0]}=$temp3[$n];
            }
            else
            {
               $info{$temp2[0]}=$temp2[1];
            }
         }
      }
      
   }
#   print "\n";
   return %info;
}
#a  function that calculates the notation
sub calculate_notation
{
   my $var=$_[0];                   chomp($var);
   my $ref=$_[1];                   chomp($ref);
   my $start=$_[2];
   my $end=$_[3];
   my $type=$_[4];                  chomp($type);
   my $chrom=$_[5];         
   my $notation="chr".$chrom.":g.".$start;
   
   if ($type eq 'SNP')
   {
      $notation.=$ref.">".$var;
   }
   elsif ($type eq 'delins')
   {
      $notation.="_".$end.$ref.$type.$var
   }
   elsif ($type eq "deletion")
   {
      $notation.="_".$end."del".$ref;
   }
   elsif ($type eq "insertion")
   {
      $notation.="_".$end."ins".$var;
   }
   return $notation;
}
sub calculate_coordinates
{
   my $var=$_[0];                   chomp($var);
   my $ref=$_[1];                   chomp($ref);
   my $pos=$_[2];
   my $type=$_[3];                  chomp($type);
   my $pvar=$_[4];
   my $start=-1;
   my $end=-1;
   
   if (($type eq "SNP") || ($type eq "delins"))
   {
      $start=$pos;
      $end=$pos;
   }
   else
   {
      if ($type eq 'insertion')
      {
         if (length($ref)==1)
         {
            $start=$pos;
            $end=$start+1;
         }
         else
         {
            $start=$pos+length($ref);
            $end=$start+1;
         }
      }
      elsif ($type eq 'deletion')
      {
         $start=$pos+1;
         $end=$start+$pvar;
      }
   }
   return $start,$end;
}
# A Ffunction to print out the exac information
sub print_data
{
   my $bhash_ref=$_[0];             chomp($bhash_ref);
   my %basic=%{$bhash_ref};
   my $ihash_ref=$_[1];             chomp($ihash_ref);
   my %info=%{$ihash_ref};
   my $opt=$_[2];                   chomp($opt);
   my $dopt=$_[3];                  chomp($dopt);
   my $ofile=$_[4];                 chomp($ofile);
   my $hhash_ref=$_[5];             chomp($hhash_ref);
   my %headers=%{$hhash_ref};
   my $delim='';
   my @headers=&order_header();     chomp(@headers);
   
   if ($dopt eq 'csv')
      {$delim=',';}
   else
      {$delim="\t";}
   if ($opt=~ /full/ig )
   {
      open(OUT,">>$ofile")|| die "could not open $ofile for writing due to $!\n";
      if ($first==0)
      {
         foreach my $col (@headers)
         {
            print OUT $col.$delim;
         }
         foreach my $col2 (keys %headers)
         {
            print OUT $col2.$delim;
         }
            print  OUT "\n";
         $first=1;
      }
      foreach my $allele (keys %basic)
      {
       #  print $allele.$delim;  
         foreach my $col (@headers)
         {
            if ($basic{$allele}{$col}!= "")
            {
               print OUT $basic{$allele}{$col}.$delim;
            }
            else
            {
               print OUT $delim;
            }
         }
         foreach my $col2 (sort keys %headers)
         {
            if ((exists $info{$col2}) && ($info{$col2}!=""))
               {print OUT $info{$col2}.$delim;}
               else
               {print OUT $delim;}
         }
         print  OUT "\n";
      }
   }
}
# function that places the first 10 columns of the file in a certain order
sub order_header  
{
   my @oheader;
   push(@oheader,"notation");
   push(@oheader,"coordinate");
   push(@oheader,"chromosome");
   push(@oheader,"start");
   push(@oheader,"end");
   push(@oheader,"referenceNT");
   push(@oheader,"alternativeNT");
   push(@oheader,"rsID");
   push(@oheader,"qScore");
   push(@oheader,"filter");
   return @oheader;
}
# a function for generating the end coordinate of the 
sub parser
{
   my $arg_ref=$_[0];               chomp($arg_ref);
   my @arg=@{$arg_ref};             chomp(@arg);
   my $infile=$arg[0];                chomp($infile);
   my $head_ref=$_[1];              chomp($head_ref);
   my %headers=%{$head_ref};
   open(EXAC,"<$infile") || die "could not open $infile for reading $!\n";
   my $nlines=0;
   my %notations;
   while (my $line=<EXAC>) 
   {chomp($line);
      if (substr($line,0,1) ne '#')
      {
         my @temp=split/\t/,$line;
         
         my %alleles=&get_alleles($temp[4]);
        # print "we have ".(keys %alleles)." alleles\n";
         foreach my $allele (keys %alleles)
         {
            my %info=&split_info($temp[7],$alleles{$allele}{'order'});
            my ($type,$callele,$pvar)=&get_var_type($allele,$temp[3]);
            
            if ($allele ne $callele)
            {
               $alleles{$allele}{'alternativeNT'}=$callele;             #while technically the allele was changed it doesnt really matter for the run of the program since that value doesnt get printed
            }
            else
            {
               $alleles{$allele}{'alternativeNT'}=$allele;
            }
            $alleles{$allele}{'type'}=$type;
            $alleles{$allele}{'position'}=$pvar;
            if ($type eq 'insertion')
            {
               $alleles{$allele}{'referenceNT'}=".";
            }
            elsif ($type eq 'deletion')
            {
               $alleles{$allele}{'referenceNT'}=substr($temp[3],1,length($temp[3])-1);                    
            }
            else
            {
               $alleles{$allele}{'referenceNT'}=$temp[3];
            }
               ($alleles{$allele}{'start'},$alleles{$allele}{'end'})=&calculate_coordinates($alleles{$allele}{'alternativeNT'},$alleles{$allele}{'referenceNT'},$temp[1],$type,$pvar);
               my($notation)=&calculate_notation($alleles{$allele}{'alternativeNT'},$alleles{$allele}{'referenceNT'},$alleles{$allele}{'start'},$alleles{$allele}{'end'},$type,$temp[0]);

               if (! exists $notations{$notation})
               {
                  $alleles{$allele}{'notation'}=$notation;
                  $notations{$notation}=1;
               }
               else
               {
                  $alleles{$allele}{'notation'}=$notation.$notations{$notation};
                  $notations{$notation}++;
               }
               $alleles{$allele}{'chromosome'}="chr".$temp[0];
               $alleles{$allele}{'coordinate'}="chr".$temp[0].":".$alleles{$allele}{'start'};
               $alleles{$allele}{'qScore'}=$temp[5];
               $alleles{$allele}{'filter'}=$temp[6];
               $alleles{$allele}{'rsID'}=$temp[2];
            #foreach my $info (keys %info)
#            print "allele: ".$allele."\n\t";
            if ($first==0)
            {
               foreach my $key (sort keys %{$alleles{$allele}})
               {
 #              print $key."=".$alleles{$allele}{$key}."\t";
                  print $key."\t";
               }
               foreach my $col (sort keys %headers)
               {
                  if ($col ne 'CSQ')
                  {
                     print $col."\t";
                  }
                  else
                  {
                     foreach my $csq (sort {$headers{'CSQ'}{$a}<=> $headers{'CSQ'}{$b} } keys %{$headers{'CSQ'}})
                     {
                        print $csq."\t";
                     }
                  }
               }
               print "\n";
               $first=1;
            }
            foreach my $key (sort keys %{$alleles{$allele}})
            {
 #              print $key."=".$alleles{$allele}{$key}."\t";
               print $alleles{$allele}{$key}."\t";
            }
            foreach my $col (sort keys %headers)
            {
               if ( (exists($info{$col})) && ($col ne 'CSQ'))
               {
                  print $info{$col}."\t";
               }
               elsif ($col eq 'CSQ')
               {
                  $info{'CSQ'}=~ s/"|\s|>//g;
                  my @temp3b=split/\|/, $info{$col};
                
#                  print "n csq".($#temp3b+1)."\n";
                  for (my $i=0;$i<=$#temp3b;$i++)
                  {
                     if ($temp3b[$i] ne '')
                     {
                        print $temp3b[$i]."\t";
                     }
                     else
                     {
                        print "\t";
                     }
                  }
                  if ($#temp3b+1<59)
                  {
                     print "\t";
                  }
               }
               elsif ( (!exists($info{$col})) && ($col ne 'CSQ'))
               {
                  print "\t";
               }
            }
#            print "\n\n";
            print "\n";
            #{
            #   if (! exists $alleles{$allele}{$info})
            #   {
            #      $alleles{$allele}{$info}=$info{$info};
            #   }
           # }
        #    print $temp[3]."\t".$allele."\t".$alleles{$allele}{'length'}."\t".$alleles{$allele}{'type'}."\n";
         }
#                          print " now we have ".(keys %alleles)." alleles\n";
        #&print_data(\%alleles,\%info,$arg[3],$arg[2],$arg[1],$head_ref);
      }
      $nlines++;
   }
#   print "we have $nlines in total in file (headers + values)\n";
}
sub main
{
   my $arg_ref=$_[0];
   my @arguments=@{$arg_ref};       chomp(@arguments);

   my %headers=&get_headers($arguments[0]);
   &parser(\@arguments,\%headers);
 #  print "we have ".(keys %headers)." columns\n";
#   foreach $column (keys %headers)
#   {
#      print $column."\n";
#   }
}