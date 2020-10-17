################################################################
=begin
This script captures the data mover failover for EMC vnx.

Note - This script captures the data mover status.

There are 3 files required for this script.
1) the IP Address file: In the example, the file is named as nas_array_ip_list.txt.
###############################################################
#
#Lines beginning with "#" will be ignored by the script.
#
#This file contains the NAS IPs. 
#
#Please use tab or space to seperate the name and IP of the NAS Arrays.
#
###############################################################
VNXE-NAS-ARRAY-1 192.168.1.12 
VNXE-NAS-ARRAY-2 192.168.1.13 
VNXE-NAS-ARRAY-3 192.168.1.14 
VNXE-NAS-ARRAY-4 192.168.1.15 

2) The second file is the one that contains the smtp server name,
path to the 3par_array_ip_list file, the from and to email addresses,
the 3par command and username, password.
[params]
smtp_server_name = smtp.server.name.com
hp3par_array_list ="/home/pritesh/vnxe_array_ip_list.txt"
mail_from = from@email.com
mail_to = to@email.com
username = username
password = passwd
nas_command = /nas/sbin/getreason

3) The 3par script file (This script file)
=cut
##############################################################
#!/usr/bin/perl
use warnings;
use strict;
use Net::SSH2;
use MIME::Lite;
use Config::Tiny;


my $nasconfig = Config::Tiny->new();
$nasconfig = Config::Tiny->read ('nasconfig.txt');
my $mailserver = $nasconfig->{params}->{smtp_server_name};
my $nasarraylist = $nasconfig->{params}->{nas_array_list};
my $mailfrom = $nasconfig->{params}->{mail_from};
my $mailto = $nasconfig->{params}->{mail_to};
my $username = $nasconfig->{params}->{username};
my $password = $nasconfig->{params}->{password};
my $nascmd = $nasconfig->{params}->{nas_command};
my $mailtext = $nasconfig->{params}->{mail_text};
my $msg;
my $nas_ipfile_FH;
my $type = "";
my $mail_nas_FH;  #File handle for E-mail Alert.
my $nowtime = localtime;
my $ipfile_error_msg;
my $nasconfig_txt_FH;
my $nas_txt_msg;


MIME::Lite->send ("smtp", "$mailserver");



if (! -e "$nasarraylist" ) {
      $ipfile_error_msg = MIME::Lite->new(
				From    => $mailfrom,
				To      => $mailto,
				Data    => "$nasarraylist Not Found For $0 Script on $ENV{COMPUTERNAME}. $!. $^E\n",
				Subject => "Error: $nasarraylist file not found:\n",
				    
		);
    
    $ipfile_error_msg->send();
    
    
  exit (0);  
}
    
unlink "$mailtext" if -e "$mailtext";
open($mail_nas_FH,">", "$mailtext" ) or die "Cannot open file - $mailtext.$^E";
open($nas_ipfile_FH,"<","$nasarraylist") or die;

while (<$nas_ipfile_FH>)
    {
			    
    next if /^#/;
    my ($ipname, $ipaddr) = split /\s+/;
    
    #create a new SSH Variable
    
    print $mail_nas_FH "\n\n\n*#*#*#*#$ipname --- $ipaddr#*#*#*#*\n\n";
    my $ssh_cmd1 = Net::SSH2->new();
    $ssh_cmd1->connect("$ipaddr") or die "Cannot connect to $ipaddr. $!.$^E";
    $ssh_cmd1->auth_password("$username","$password") or die "Username/Password not correct for $ipname\n";
    
    #create a new channel.
    my $chan_cmd1 = $ssh_cmd1->channel();
    $chan_cmd1->blocking(0);
    $chan_cmd1->exec("$nascmd");
    sleep 15;
    print $mail_nas_FH "$_" while (<$chan_cmd1>);
    $chan_cmd1->close();			
    }
    
    
    close $mail_nas_FH;
    


    $nas_txt_msg = MIME::Lite->new(
            From    => $mailfrom,
            To      => $mailto,
            Subject => "Please check the mail - DM Status and Time Difference for EMC Celerra Arrays.",
            Type    => 'Multipart/mixed',

        );
    
	
        
	$nas_txt_msg->attach( Type        => 'TEXT',
		       
                      Path        => "$mailtext",
                      Filename    => "$mailtext",
                      Disposition => 'attachment', );
	$nas_txt_msg->attach( Type        => 'TEXT',
		       
			      Data 	  => "\nScript $0 on $ENV{COMPUTERNAME} auto run at $nowtime [U.S. C.S.T].\nPlease check the attachment for the status of the Data Movers and the time difference in the DMs.\n"
			      );
	
	
	$nas_txt_msg->send;
	
	
