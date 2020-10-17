#!/usr/bin/perl
use warnings;
use strict;
use Net::SSH2;
use MIME::Lite;
##########################################
# Try using subroutine for sending mail if dm fails.
# Use the /nas/sbin/serial in the output
#open a file in the subroutine and read it from there.
##########################################
MIME::Lite->send ("smtp", "mail.mgmt.sabre.com");

if (!open my $fh , "<" , "C:/Documents and Settings/ed856546/sabre_nas_array_ip_list.txt")
{
    my $msg = MIME::Lite->new
	      (
	      From    => 'pritesh.ugrankar@hp.com',
	      To      => 'pritesh.ugrankar@hp.com',
	      Data    => "Error:sabre_nas_array_ip_list.txt:$!.$^E\n",
	      Subject => "IP List File - sabre_nas_array_ip_list.txt - Not Found For $0 Script on $ENV{COMPUTERNAME}\n",
	      );

$msg->send ();
    
}
else {
	print "Now in the ELSE LOOP\n";
	print "Please wait. $0 script is being executed...\n";
	#open my $mailfh, ">", "C:/Documents and Settings/ed856546/dmcheck.txt";
	print  "\n###################################################################\n";
	print  "\nUser: $ENV{USERNAME} running $0 from $ENV{COMPUTERNAME}\n\n";
	print  "\nIf any DM appears as failed,please login to the specific\n";
	print  "\nnas array and re run the /nas/sbin/getreason command. If\n";
	print  "\nthe Data Mover still appears as failed, Open a Sev 1 IMMEDIATELY\n";
	print  "\nwith EMC by Phone (1800-782-4362) or log on to EMC Powerlink -\n";
	print  "\npowerlink.emc.com. portal and open a case through chat session. \n";
	print  "\nAlso, E-mail the Storage DL - sabre_storage_delivery\@hp.com\n";
	print  "\nand provide an update on the situation about the DM Failure.\n";
	print  "\n###################################################################\n";
	while (<$fh>)
	{
	    
	    next if ((/^#/));
	    print "Now in the WHILE LOOP for \$fh\n";
	    
	    my ($ipname, $ipaddr) = split /\t+|\s+/;
	    
	    my $username = 'nasadmin';
	    my $password = 'nasadmin';
	    
	    my $ssh2 = Net::SSH2->new();
	    
	    
	    
	    print "\n-----------------------------------------------------";
	    
	    print "\nData Mover Check For $ipname ($ipaddr)\n";
	    
	    print "-----------------------------------------------------\n";
	    $ssh2->connect("$ipaddr") || die "PROBELM - $!";
	    
	    $ssh2->auth_password("$username","$password") || die "Username/Password not right";
	    
	    my $chan = $ssh2->channel();
	    $chan->blocking(0);
	    $chan->exec('/nas/sbin/getreason');
	    sleep 3;
	  
	    while (<$chan>)
	    {
		chomp;
		
		print "Now in the beginning of while loop for chan of getreason\n";
		next if (/10 - slot_0 primary control station/);
		if ($_ =~ /contacted$/)
		{
		    print "Now in the beginning of IF loop for chan for getreason\n";
		    print "DM is OK: $_\n";
		    print "Now in the end of IF loop for chan for getreason\n";
		}
		else
		{
			print "Now in the beginning of ELSE loop for chan for getreason\n";
			print "/nas/sbin/getreason - POSSIBLE DM FAILURE:Please check $ipname ($ipaddr): $_ POSSIBLE DM FAILURE:\n";
			print "Now in the END of ELSE loop for chan for getreason\n";
		
		}
		print "Now in the END of while loop for chan of getreason\n";
	    }
		print "Now out of while loop for chan of getreason\n";
	    $chan->close();
	    my $ssh2_ns = Net::SSH2->new();	
	    my $nas_server_cmd_chan = $ssh2_ns->channel();
	    $nas_server_cmd_chan->blocking(0);
	    $nas_server_cmd_chan->exec('nas_server -l');
	    sleep 3;
	    
	    while (<$nas_server_cmd_chan>)
	    {
		print "Now in beginning of the while loop of chan for server -l command\n";
		chomp;
		print "Now in the beginning of while loop of chan for nas server -l command\n";
		if ($_=~ /fault/gi)
		{
		    print "Now in the beginning of if loop of chan for nas server -l command\n";
		    print "nas_server -l: POSSIBLE DM FAILURE:Please check $ipname ($ipaddr): $_ POSSIBLE DM FAILURE:\n";
		    print "Now in the end of if loop of chan for nas server -l command\n";
		}
		
		
		else
		{
		    print "Now in the beginning of ELSE loop of chan for nas server -l command\n";
		    print "DM is OK: $_\n";
		    print "Now in the END of ELSE loop of chan for nas server -l command\n";
		}
		print "Now in the end of the while loop of chan for server -l command\n";
		
	    }
	    $nas_server_cmd_chan->close ();
		print "Now out of the while loop of chan for server =l command\n";
	    my $ssh2_uptime = Net::SSH2->new();
	    my $nas_server_uptime_cmd_chan = $ssh2_uptime->channel();
	    $nas_server_uptime_cmd_chan->blocking(0);
	    $nas_server_uptime_cmd_chan->exec('nas_server -l');
	    sleep 3;
	    while (<$nas_server_uptime_cmd_chan>)
	    {
		print "Now in the beginning of while loop server uptime command\n";
		chomp;
		if ($_=~ /(^up)||(\b0 hours 0 min\b)/gi )
		{
		    print "Now in the beginning of the IF loop for chan for server uptime command\n";
		    print "server_uptime ALL - POSSIBLE DM REBOOT - $ipname ($ipaddr): $_  - POSSIBLE DM REBOOT\n";
		    print "Now in the end of the IF loop for chan for server uptime command\n";
		}
		
		else
		{
		    print "Now in the beginning of the ELSE loop for chan for server uptime command\n";
		    print "No recent Reboot: $_\n";
		    print "Now in the end of the IF loop for chan for server uptime command\n";
		}
		print "Now at the end of the while chan loop of server uptime command\n";
		
	    }
	    $nas_server_uptime_cmd_chan->close();
	    
	    
	    
	    
	    
	    
	    print "now at the END of the while loop for \$fh\n";
	    
	}
	
	#close $mailfh;
	#my $nasmailmsg = MIME::Lite->new(
	#	From		=>'pritesh.ugrankar@hp.com',
	#	To 		=> 'pritesh.ugrankar@hp.com',
	#	Subject 	=> "Automated Check For NAS DataMover Health.",
	#	Type	=> 'Multipart/mixed',
	#				    
	#				);
	#    
	#    $nasmailmsg->attach (
	#	Type		=> 'TEXT',
	#	Path		=> "dmcheck.txt",
	#	Filename	=> "dmcheck.txt",
	#	Disposition	=> 'inline',
	#			);
	#    $nasmailmsg->send;
	#    system "del dmcheck.txt";
	   					
    	print "$0 execution completed.Please check your mailbox for Mail Titled - \n\"Automated Check For NAS DataMover Health.\"\n";
	print "Now and the END OF ELSE LOOP\n";
}