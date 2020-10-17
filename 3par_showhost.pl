################################################################
=begin
This script captures the host names of those hosts whose HBAs (1 or more) have
logged out from 3PAR. This script contains 3 parts:
1) the IP Address file: In the example, the file is named as 3par_array_ip_list.txt.
################################################################
#
#Lines beginning with "#" will be ignored by the script.
#
#This file contains the 3PAR IPs. 
#
#Please use tab or space to seperate the name and IP of the 3PAR Arrays.
#
###############################################################
3PARNAME-8400-DC-NAME 192.168.1.10  
3PARNAME-8200-DC-NAME 192.168.1.11
3PARNAME-8440-DC-NAME 192.168.1.12
3PARNAME-20800-DC-NAME 192.168.1.13
3PARNAME-20840-DC-NAME 192.168.1.14
##############################################################

2) The second file is the one that contains the smtp server name,
path to the 3par_array_ip_list file, the from and to email addresses,
the 3par command and username, password.
[params]
smtp_server_name = smtp.server.name.com
hp3par_array_list ="/home/pritesh/3par_array_ip_list.txt"
mail_from = from@email.com
mail_to = to@email.com
username = username
password = passwd
hp3par_command = showhost

3) The 3par script file (This script file)
=cut
##############################################################
#!/home/pritesh/.plenv/shims/perl5.32.0
use warnings;
use strict;
use Config::Tiny;
use Net::SSH2;
use MIME::Lite;

my $hp3parconfig = Config::Tiny->new();
$hp3parconfig = Config::Tiny->read('perl_3par_config.txt');
my $mailserver = $hp3parconfig->{params}->{smtp_server_name};
my $arraylist = $hp3parconfig->{params}->{hp3par_array_list};
my $mailfrom = $hp3parconfig->{params}->{mail_from};
my $mailto = $hp3parconfig->{params}->{mail_to};
my $username = $hp3parconfig->{params}->{username};
my $password = $hp3parconfig->{params}->{password};
my $hp3parcmd = $hp3parconfig->{params}->{hp3par_command};
my $hp3parlistfh; #file handle for the 3par name and ip list
my $ipfile_error_msg;
my $parafileFH;
my ($hp3par_name, $hp3par_ip);

MIME::Lite->send ("smtp", "$mailserver");
if (!open $hp3parlistfh, "<" , "3par_array_ip_list.txt")
{
    
    my $ipfile_error_msg = MIME::Lite->new(
				From    => $mailfrom,
				To      => $mailto,
				Data    => "IP List File Not Found For $0 Script on $ENV{COMPUTERNAME}. $!. $^E\n",
				Subject => "Error:$arraylist file not found:\n",
				    
		);
    
    $ipfile_error_msg->send();
    
    
  exit (0);  
    
}

unlink "para.txt" if -e "para.txt"; #Removes para.txt file if it already exists.
while (<$hp3parlistfh>)
{
    next if /^#/; #ignore the lines that begin with a #.
    ($hp3par_name, $hp3par_ip) = split /\s+/;
    
    #print "$hp3par_name:$hp3par_ip\n";
    
    my $ssh_3par = Net::SSH2->new();
    
   
    print $! unless $ssh_3par->connect("$hp3par_ip");
    
    
    $ssh_3par->auth_password("$username","$password") or die "Username/Password not right";
    
    my $chan_3par = $ssh_3par->channel();
   
    $chan_3par->blocking(0);
    
    $chan_3par->exec("$hp3parcmd");
    
    sleep 10;
    open $parafileFH, ">>" , "para.txt" or die "Error:$!. $^E";
    while (<$chan_3par>)
	
	{
		
	    next if /Id Name       Persona        -WWN\/iSCSI_Name- Port/;
	    
	    #print "$_";
	    s/^((\s+)?\p{Digit}{1,3}\s)/\n\n$1/;
            
	    print $parafileFH "$_";
     
		
	}
    
}

open(my $emailfile_FH, ">", "emailfile.txt") or die "Error $!.$^E";
{
local $/ = "\n\n";

open $parafileFH, "<" , "para.txt" or die "Error:$!. $^E";


while (<$parafileFH>)
{
    
	if ($_=~ /---/)
	{
			    print $emailfile_FH "\n\n###Please check below host on [$hp3par_name $hp3par_ip]:###\n\n\n$_";
			    
			    
	}		    
    
}



}
my $threeparmsg = MIME::Lite->new(
            From    => $mailfrom,
            To      => $mailto,
            Subject => "Please check the mail - Hosts Logged Out.",
            Type    => 'Multipart/mixed',

        );
    
	
        
	$threeparmsg->attach( Type        => 'TEXT',
		       
                      Path        => "emailfile.txt",
                      Filename    => "emailfile.txt",
                      Disposition => 'attachment', );
	$threeparmsg->attach( Type        => 'TEXT',
		       
			      Data 	  => "This is an Automated mail sent by $0.\nPlease see the attachment for a list of hosts which are currently logged out from the 3PAR Arrays. Please open a case with HP 3PAR Support if need be."
			      );
	
	close $emailfile_FH;
	$threeparmsg->send;
	close $parafileFH;
	
	unlink "emailfile.txt" or die "Cannot delete emailfile.txt.$!.$^E";
