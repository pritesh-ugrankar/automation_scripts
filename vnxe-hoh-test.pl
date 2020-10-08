use strict;
use warnings;
use 5.030;
#######################################
#Test if the vnxe disk details can be 
#converted to Hash of Hashes on the fly.
#Implementing this in script will depend
#on successful output.
#######################################

open my $fh_pd, '<', "physical_disks.txt" or die "Cannot open file.$!";
my $href_anon_diskhash;
my $id;
my $subkey;
my $subvalue;
{
	while (my $line = <$fh_pd>) {
		next if $line =~/^(storage|https)/i;
		next if $line =~/^$/i;
		
		if ($line =~/	        #The () around regex are used for capturing in the $1 or $2 etc.
			^([0-9]+)       #If the line starts with a number,
			(.*)		#and some stuff after that,
			/x		#/x allows to break the regex on multiple lines.
		   ) 
		
		{
			$id = $1;
				}
		if ($line =~/	        #The () around regex are used for capturing in the $1 or $2 etc.
			^\s+		# If the line begins with one or more spaces.
			([A-z ]+?)	# and is followed by alphabets - upper and lower case - and a space.
			\s+		# And then one or more spaces,
			=		# followed by the = sign 
			\s		# followed by single space
			(.*)		#followed by anything
			\s+		#followed by one or more spaces
			/x		#/x allows to break the regex on multiple lines.
		   ) {		
			$subkey = $1;
			$subvalue = $2;
		}
		$href_anon_diskhash->{$id}->{$subkey} = $subvalue;
   }
}

foreach my $key (keys $href_anon_diskhash->%*){
	foreach my $inkey (keys $href_anon_diskhash->{$key}->%*){
		{
			print "$inkey=>$href_anon_diskhash->{$key}->{$inkey}\n";
		}
	}

}




