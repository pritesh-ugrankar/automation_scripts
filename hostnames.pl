#!C:\Dwimperl\perl\bin\perl.exe
use warnings;
use strict;
use Cwd 'abs_path';

my @hostnames;
my ($identifier,$nodename);
my $symmid;

#The script will extact the servernames/pWWNs from the symmask list logins output.

while (<>)
{
	
	if ($_=~/^Symmetrix ID/)
	{
		
		chomp ($symmid = (split /:\s+/)[1]);
		
	}
	
	next if $_ !~ /fibre/gi;
	
	($identifier,$nodename)= (split /\s+/)[0,2];
	
	if ($nodename eq "NULL")
	{
		$nodename=$identifier;
		
		
		push @hostnames, $nodename;
	}
	
	else
	{
		
		unshift @hostnames, uc $nodename;
		
	}
}
my $filename = "hostlist_${0}_${symmid}.txt";

unlink "$filename" if -e "$filename" && print "\nDeleting existing \"$filename\". A new one will be created.\n";



open(my $hostnamefile_fh, ">" ,"$filename" ) or die "Cannot open file.$!.$^E";	
my %repeated;
	
	my @uniqhostlist = grep {! $repeated{$_}++}  sort @hostnames;
	print $hostnamefile_fh "Host List for Symmetrix ID: $symmid\n";
	print $hostnamefile_fh "$_\n"foreach (@uniqhostlist);
	print "\n*****************************************************************************************\n";
	print "Please Check the file - [ " ,abs_path($filename), " ].\n";
	print "NULLs are replaced with corresponding pWWNs.\n";
	print "*****************************************************************************************\n";
