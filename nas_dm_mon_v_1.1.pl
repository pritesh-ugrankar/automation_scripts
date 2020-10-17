#!/usr/bin/perl
use warnings;
use strict;
use Net::SSH2;
use MIME::Lite;
use Config::Tiny;


my $nasconfig = Config::Tiny->new();
$nasconfig = Config::Tiny->read ('nasconfig');
my $mailserver = $nasconfig->{params}->{smtp_server_name};
my $nasarraylist = $nasconfig->{params}->{nas_array_list};
my $mailfrom = $nasconfig->{params}->{mail_from};
my $mailto = $nasconfig->{params}->{mail_to};
my $username = $nasconfig->{params}->{username};
my $password = $nasconfig->{params}->{password};
my $nascmd = $nasconfig->{params}->{nas_command};
my $mailtext = $nasconfig->{params}->{mail_text};
my $msg;
my $type = "";
my $ipfilefh;#File handle for NAS IP File.
my $mailfh;  #File handle for E-mail Alert.
my $nowtime = localtime;

MIME::Lite->send ("smtp", "$mailserver");

sub email_alert()
{
    open $mailfh, ">>", "$mailtext" or die "Cannot open $mailtext in sub email_alert. $!. $^E";
    $type = shift @_;
	
	if ( $type eq "ip_list_error" )
	    {
	
		$msg = MIME::Lite->new(
				From    => $mailfrom,
				To      => $mailto,
				Data    => "Error:nas_array_ip_list.txt:$!.$^E\n",
				Subject => "IP List File Not Found For $0 Script on 

$ENV{COMPUTERNAME}\n",
				    
		);
	
				    $msg->send;
	
	    }

	elsif ( $type eq "all_ok" )
	    {
		
		print $mailfh "DM is OK:$_\n";
	    }
    
        elsif ( $type eq "fault" )
	    {
		print $mailfh "Possible DM Failure: $_:Possible DM Failure\n";
	    }
	    
        elsif ( $type eq "unsure" )
	    {
		print $mailfh "Unknown Status: $_\n";
	    }
	else
	    {
		die "email_alert - bad type: $type\n";
	    }

}




if (!open $ipfilefh , "<" , "$nasarraylist")
{
    &email_alert("ip_list_error");
    die "Cannot open $nasarraylist:$!.$^E";
    exit (0);
}





open $mailfh, ">", "$mailtext" or die "Cannot open $mailtext. $!. $^E";
print $mailfh
'##########################################################################################################################################################';
print $mailfh "\nScript $0 on $ENV{COMPUTERNAME} auto run at $nowtime [$ENV{COMPUTERNAME} Time]\n";
print $mailfh "\n";
print $mailfh 'If any DM appears as failed or output is not displayed in the mail,
please login to the specific nas array and re run the /nas/sbin/getreason command.
If the Data Mover still appears as failed, Please do the following IMMEDIATELY:

1) Open a Sev 1 IMMEDIATELY with EMC by Phone (1800-782-4362) or log on to EMC Powerlink -
powerlink.emc.com. portal and open a case through chat session.

2) E-mail the Storage DL - sabre_storage_delivery@hp.com and provide an update on
the situation about the DM Failure.
##########################################################################################################################################################';

while (<$ipfilefh>)
	{
	    next if /^#/;
	    
	    my ($ipname, $ipaddr) = split /\s+/;
	    
	  
	    
	    my $ssh2 = Net::SSH2->new();
	    
	    
	    print $mailfh "\n-------------------------------------------------------------";
	    
	    print $mailfh "\nData Mover Check For $ipname ($ipaddr)\n";
	    
	    print $mailfh "-------------------------------------------------------------\n";
	    
	    
	    print $mailfh $! unless $ssh2->connect("$ipaddr");
	    
	    $ssh2->auth_password("$username","$password") or die "Username/Password not right";
	    
	    my $chan = $ssh2->channel();
	    
	    $chan->blocking(0);
	    
	    $chan->exec('/nas/sbin/getreason');
	    
	    sleep 10;
	    
	    while (<$chan>)
	    {
		chomp;
		next if (/10 - slot_0 primary control station/);
		if ($_=~ /contacted$/ig)
		{
		    &email_alert("all_ok");
		}
		
		elsif ($_=~ /fault/ig)
		{
		    &email_alert("fault");
		}
		
		else
		{
		    &email_alert("unsure");
		}
	    }
	    
	    
	    $chan->close();
	     
	}
	close $mailfh;
	
	my $nasmsg = MIME::Lite->new(
            From    => $mailfrom,
            To      => $mailto,
            Subject => "Automated Check For NAS DataMover Health.",
            Type    => 'Multipart/mixed',

        );
    
	
        
	$nasmsg->attach( Type        => 'TEXT',
                      Path        => "$mailtext",
                      Filename    => "$mailtext",
                      Disposition => 'inline', );
	
	
	$nasmsg->send;
	
	unlink $mailtext or die "Cannot delete $mailtext.$!.$^E";
	
	
	
	
	   					
    	
	
