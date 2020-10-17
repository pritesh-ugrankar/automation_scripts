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
#######################################
#Regex construction for extracting disk
#fields and their corresponding values
#from the input. 
#######################################
my $regex_4_disk_fields_descr = qr {  
# The () around regex are used for capturing in the $1 or $2 etc.
^\s+		# If the line begins with one or more spaces.
([A-z ]+?)	# and is followed by alphabets - upper and lower case - and a space.Capture it in brackets.
\s+		# And then one or more spaces.
=		# followed by the = sign. 
\s		# followed by single space.
(.*)		# followed by anything.Capture it in brackets.
\s+		# followed by one or more spaces.
}x;	        # x allows to break the regex on multiple lines.
		
my $regex_4_disk_id_descr = qr {
# The () around regex are used for capturing in the $1 or $2 etc.
(^[0-9]+)       # If the line starts with a number,Capture it in brackets.
:		# followed by the : sign.
\s+		# followed by one or more spaces.
ID		# followed by the word "ID".
\s+		# followed by one or more spaces.
=	        #followed by the = sign.
\s		#followed by single space.
(.*)		# and some stuff after that,Capture it in brackets.
}x;		# x allows to break the regex on multiple lines.;

my @file_content = grep { ! /^$|(^storage.*|^https.*)/i } <$fh_pd>;
foreach my $line (@file_content) {
	if ($line =~/$regex_4_disk_id_descr/) {
		$id = $1;
	}

	if ($line =~/$regex_4_disk_fields_descr/) {		
		$subkey		= 	$1;
		$subvalue	=	$2;
	}
	$href_anon_diskhash->{$id}->{$subkey} = $subvalue;
}

foreach my $key (keys $href_anon_diskhash->%*){
	foreach my $inkey (keys $href_anon_diskhash->{$key}->%*){
		printf "%-40s    =>    %-40s\n",$inkey,$href_anon_diskhash->{$key}->{$inkey};
	}
}






