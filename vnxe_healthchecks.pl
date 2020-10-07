######################################################################
use strict;
use warnings;
use Config::Tiny;
use IPC::Run3;
use Encode qw/decode/;
use Email::Stuffer;
use Email::Sender::Transport::SMTP ();
use Cwd;
#######################################################################

#######################################################################
#Script reads the username, password and email server from a separate 
#config file. Config::Tiny module is used for this purpose.
#
#Please install Config::Tiny like so:
#cpanm Config::Tiny
#Example of file is given below
#
#[params]
#vnxe_username = username 
#vnxe_passwd= password 
#vnxe_ip = 192.168.1.2
#Save the above file with the name vnxe_config.conf and ENSURE THAT
#THE ABSOLUTE PATH is provided in the script.
#Refer to Config::Tiny documentation for further details.
#######################################################################
my $array_creds = Config::Tiny->new();
$array_creds   = Config::Tiny->read('absolute\path\to\vnxe_config.conf');
my $mailserver = $array_creds->{params}->{smtp_server_name};
my $username   = $array_creds->{params}->{vnxe_username}; 
my $password   = $array_creds->{params}->{vnxe_passwd};
my $vnxe_ip   = $array_creds->{params}->{vnxe_ip};
######################################################################
my $aref_cmd_genhealth = ['uemcli','-d',$vnxe_ip,'-u',$username,'-p',$password, '/sys/general','show','-detail'];
my $aref_cmd_bat = ['uemcli', '-d', $vnxe_ip, '-u', $username, '-p', $password, '/env/bat', 'show', '-detail'];
my $aref_cmd_ps = ['uemcli', '-d', $vnxe_ip, '-u', $username, '-p', $password, '/env/ps', 'show', '-detail'];
my $aref_cmd_disks = ['uemcli', '-d', $vnxe_ip, '-u', $username, '-p', $password, '/env/disk', 'show', '-detail'];
my $aref_cmd_pools = ['uemcli', '-d', $vnxe_ip, '-u', $username, '-p', $password, '/stor/config/pool', 'show', '-detail'];
my $aref_cmd_dpe = ['uemcli', '-d', $vnxe_ip, '-u', $username, '-p', $password, '/env/dpe', 'show', '-detail'];
my $aref_cmd_ccard = ['uemcli', '-d', $vnxe_ip, '-u', $username, '-p', $password, '/env/ccard', 'show', '-detail'];
my $aref_cmd_dae = ['uemcli', '-d', $vnxe_ip, '-u', $username, '-p', $password, '/env/dae', 'show', '-detail'];
my $aref_cmd_iomod = ['uemcli', '-d', $vnxe_ip, '-u', $username, '-p', $password, '/env/iomodule', 'show', '-detail'];
my $aref_cmd_sp = ['uemcli', '-d', $vnxe_ip, '-u', $username, '-p', $password, '/env/sp', 'show', '-detail'];
my $aref_cmd_ssd = ['uemcli', '-d', $vnxe_ip, '-u', $username, '-p', $password, '/env/ssd', 'show', '-detail'];

######################################################################
#Use the run3 from IPC::Run3 so that the output will be captured
#in the \my $variable reference.This can be used later when the
#output is decoded from UTF 16 and written to a file.
#Why is this being done? - Because the uemcli output is in UTF16
#Format and does not render nicely in text files.
######################################################################
#TODO:- See if this can be done in a subroutine for DRY.
######################################################################
run3 $aref_cmd_genhealth, undef, \my $genhealth;
run3 $aref_cmd_bat, undef, \my $bat;
run3 $aref_cmd_ps, undef, \my $pow_sup;
run3 $aref_cmd_disks, undef, \my $disks;
run3 $aref_cmd_pools, undef, \my $pools;
run3 $aref_cmd_dpe, undef, \my $dpe;
run3 $aref_cmd_ccard, undef, \my $ccard;
run3 $aref_cmd_dae, undef, \my $dae;
run3 $aref_cmd_iomod, undef, \my $iomod;
run3 $aref_cmd_sp, undef, \my $sp;
run3 $aref_cmd_ssd, undef, \my $ssd;
######################################################################
#This is where the decoding and writing to file or variable starts.
######################################################################
#TODO:- See if this can be done in a subroutine for DRY.
######################################################################
my $genhealthfile = "genhealthfile.txt";
open (my $fh_genhealthfile, '+>', $genhealthfile) or die "Cannot open file.$!";
my $str_genhealth = decode('UTF-16', $genhealth, Encode::FB_CROAK);
print $fh_genhealthfile $str_genhealth;
close $fh_genhealthfile;
open ($fh_genhealthfile, '<', $genhealthfile) or die "Cannot open file.$!";
my $array_system;
my $array_model;
my $array_sn;
while (my $line = <$fh_genhealthfile>) {
	
	if ($line =~/System.*=\s(.*)/) {
		$array_system = $1;
	}
	if ($line =~/Model.*=\s(.*)/) {
		$array_model = $1;

	}
	if ($line =~/serial.*=\s(.*)/) {
		$array_sn = $1;
	}
}
close $fh_genhealthfile;
my $array = "$array_system "."$array_model "."$array_sn "; 
my $email_subject = $array."Health Check & Capacity"; 


my $batteries = "batteries.txt";
open (my $fh_batteries, '+>', $batteries) or die "Cannot open file.$!";
my $str_batt = decode('UTF-16', $bat, Encode::FB_CROAK);
print $fh_batteries $str_batt;
close $fh_batteries;

my $power_supply = "power_supply.txt";
open (my $fh_power_supply, '+>', $power_supply) or die "Cannot open file.$!";
my $str_power_supply = decode('UTF-16', $pow_sup, Encode::FB_CROAK);
print $fh_power_supply $str_power_supply;
close $fh_power_supply;


my $physical_disks = "physical_disks.txt";
open (my $fh_physical_disks, '+>', $physical_disks) or die "Cannot open file.$!";
my $str_phys_disks = decode('utf-16', $disks, Encode::FB_CROAK);
print $fh_physical_disks $str_phys_disks;
close $fh_physical_disks;

my $capacity = "capacity.txt";
open (my $fh_ph_disks, '+>', $capacity) or die "Cannot open file.$!";
my $str_ph_disks = decode('utf-16', $pools, Encode::FB_CROAK);
print $fh_ph_disks $str_ph_disks;
close $fh_ph_disks;
my $used_capacity;
{
	open ($fh_ph_disks, '+<', $capacity) or die "Cannot open file.$!";
	
	local $/ = "\n\n";

	while (<$fh_ph_disks>) {
		next if $_ =~/^(Storage|HTTPS)/;
		if ($_ !~ /Total space          = 0/) {
			$used_capacity = $_;
	}
	
	}
}

my $dpe_file = "dpe_file.txt";
open (my $fh_dpe_file, '+>', $dpe_file) or die "Cannot open file.$!";
my $str_dpe = decode('utf-16', $dpe, Encode::FB_CROAK);
print $fh_dpe_file $str_dpe;
close $fh_dpe_file;


my $ccard_file = "ccard_file.txt";
open (my $fh_ccard_file, '+>', $ccard_file) or die "Cannot open file.$!";
my $str_ccard = decode('utf-16', $ccard, Encode::FB_CROAK);
print $fh_ccard_file $str_ccard;
close $fh_ccard_file;

my $dae_file = "dae_file.txt";
open (my $fh_dae_file, '+>', $dae_file) or die "Cannot open file.$!";
my $str_dae = decode('utf-16', $dae, Encode::FB_CROAK);
print $fh_dae_file $str_dae;
close $fh_dae_file;

my $iomod_file = "iomod_file.txt";
open (my $fh_iomod_file, '+>', $iomod_file) or die "Cannot open file.$!";
my $str_iomod = decode('utf-16', $iomod, Encode::FB_CROAK);
print $fh_iomod_file $str_iomod;
close $fh_iomod_file;


my $sp_file = "sp_file.txt";
open (my $fh_sp_file, '+>', $sp_file) or die "Cannot open file.$!";
my $str_sp = decode('utf-16', $sp, Encode::FB_CROAK);
print $fh_sp_file $str_sp;
close $fh_sp_file;

my $ssd_file = "ssd_file.txt";
open (my $fh_ssd_file, '+>', $ssd_file) or die "Cannot open file.$!";
my $str_ssd = decode('utf-16', $ssd, Encode::FB_CROAK);
print $fh_ssd_file $str_ssd;
close $fh_ssd_file;
#################################################################
#Capture host and script location information.
my $hostname = `hostname`;
my $script_path = Cwd::abs_path($0);
#################################################################
#Email Body Content.
my $email_body = <<"EMAIL_BODY";
Host Name: $hostname
Script path: $script_path 

Please check the attached files if health state shows not ok.

================================================================
			Array Health
================================================================

$str_genhealth

================================================================
Capacity (Empty pools are not shown):
$used_capacity
EMAIL_BODY
#################################################################
#Create Email, insert email body content & Attachments.
Email::Stuffer
	->text_body($email_body)
	->subject($email_subject)
	->attach_file($batteries)
	->attach_file($power_supply)
	->attach_file($physical_disks)
	->attach_file($dpe_file)
	->attach_file($ccard_file)
	->attach_file($iomod_file)
	->attach_file($sp_file)
	->attach_file($ssd_file)
	->from('VNXe Array Name SN <VNXe-SN@email.com>')
	->transport(Email::Sender::Transport::SMTP->new({
				host => $mailserver,
			}))
	->to('Team DL<teamdl@email.com>')
	->send_or_die;


