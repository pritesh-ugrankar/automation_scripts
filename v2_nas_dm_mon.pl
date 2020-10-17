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
	
	
