#!/usr/bin/perl -w

package esmith::FormMagick::Panel::raidstatus;

use strict;
use warnings;
use esmith::FormMagick;
use esmith::cgi;
use esmith::util;
use File::Basename;
use Exporter;
use Carp qw(verbose);
use Getopt::Long;
use esmith::ConfigDB;

our @ISA = qw(esmith::FormMagick Exporter);
our @EXPORT = qw(
              apply
              );

our $configdb = esmith::ConfigDB->open(); 

sub new {
shift;
my $self = esmith::FormMagick->new();
$self->{calling_package} = (caller)[0];
bless $self;
return $self;
}


sub print_raidstatus {

    	my $self = shift;
    	my $q = $self->{cgi};
    ##we start to read the raidstatus key to retrieve properties 
        my $rec = $configdb->get('raidstatus');
         if ($rec) {
            $q->param(-name=>'mailto',-value=>
                 $rec->prop('mailto'));
          }

    	print "  <tr>\n    <td>\n      ";
	print $q->start_table ({-CLASS => "sme-border", width=>"700"});
    	print $q->Tr(
			esmith::cgi::genSmallCell($q, $self->localise('STATUS'),"header"),	
			esmith::cgi::genSmallCell($q, $self->localise('RAID'),"header"),	
			esmith::cgi::genSmallCell($q, $self->localise('DEVICECOUNT'),"header"),	
			esmith::cgi::genSmallCell($q, $self->localise('ACTIVEDEVICES'),"header"),
			esmith::cgi::genSmallCell($q, $self->localise('FAILDDEVICES'),"header"),
			esmith::cgi::genSmallCell($q, $self->localise('SPAREDEVICES'),"header"));

    ##Start to check linux raid status    
    my $Raidcheck = `/bin/cat /proc/mdstat`;
    if ( $Raidcheck =~ "raid"){
	
		my $file = "/proc/mdstat";
		my $device = "all";

		# Get command line options.
		GetOptions ('file=s' => \$file,
		'device=s' => \$device,
		'help' => sub { &usage() } );

		## Strip leading "/dev/" from --device in case it has been given
		$device =~ s/^\/dev\///;

		## Return codes for Nagios
		my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

		## This is a global return value - set to the worst result we get overall
		my $retval = 0;

		my (%active_devs, %failed_devs, %spare_devs);

		open FILE, "< $file" or die "Can't open $file : $!";
		while (<FILE>) {
			next if ! /^(md\d+)+\s*:/;
			next if $device ne "all" and $device ne $1;
			my $dev = $1;
			my @array = split(/ /);
			for $_ (@array) {
				next if ! /(\w+)\[\d+\](\(.\))*/;
                if (defined $2){
				if ($2 eq "(F)") {
					$failed_devs{$dev} .= "$1,";
				}
				elsif ($2 eq "(S)") {
					$spare_devs{$dev} .= "$1,";
				}}
				else {
					$active_devs{$dev} .= "$1,";
				}
			}
			if (! defined($active_devs{$dev})) { $active_devs{$dev} = "none"; }
				else { $active_devs{$dev} =~ s/,$//; }
			if (! defined($spare_devs{$dev}))  { $spare_devs{$dev}  = "none"; }
				else { $spare_devs{$dev} =~ s/,$//; }
			if (! defined($failed_devs{$dev})) { $failed_devs{$dev} = "none"; }
				else { $failed_devs{$dev} =~ s/,$//; }
			$_ = <FILE>;
			/\[(\d+)\/(\d+)\]\s+\[(.*)\]$/;
			my $devs_total = $1;
			my $devs_up = $2;
			my $stat = $3;
			my $result = "OK";
			if ($devs_total > $devs_up or $failed_devs{$dev} ne "none") {
				$result = "CRITICAL";
				$retval = $ERRORS{"CRITICAL"};
			}
			my $active=$active_devs{$dev};	
			my $failed=$failed_devs{$dev};
			my $spare=$spare_devs{$dev};
			my @raidstatus = "$result - $dev [$stat] has $devs_up of $devs_total devices active (active=$active_devs{$dev} failed=$failed_devs{$dev} spare=$spare_devs{$dev})\n";
			foreach my $raid (@raidstatus)
			{
				if ( $raid =~ ("CRITICAL" && "failed=none") ){
					if ( $raid =~ "CRITICAL" ){
						print $q->Tr(
									$q->td({class=>"sme-border-center", bgcolor=>"orange", align=>"center", width=>"60"}, $result),
									$q->td({class=>"sme-border-center", width=>"100"}, $dev . " [ " . $stat . " ]"),
									$q->td({class=>"sme-border-center"}, $devs_up),
									$q->td({class=>"sme-border-center"}, $active),
									$q->td({class=>"sme-border-center"}, $failed),
									$q->td({class=>"sme-border-center"}, $spare),
							);
					}
					else
					{
						print $q->Tr(
									$q->td({class=>"sme-border-center", bgcolor=>"#32CD32", align=>"center", width=>"60"}, $result),
									$q->td({class=>"sme-border-center", width=>"100"}, $dev . " [ " . $stat . " ]"),
									$q->td({class=>"sme-border-center"}, $devs_up),
									$q->td({class=>"sme-border-center"}, $active),
									$q->td({class=>"sme-border-center"}, $failed),
									$q->td({class=>"sme-border-center"}, $spare),
							);
					}
				}
				elsif ( $raid =~ ("CRITICAL" && "_") ){
					if ( $raid =~ "CRITICAL" ){
						print $q->Tr(
									$q->td({class=>"sme-border-center", bgcolor=>"red", align=>"center", width=>"60"}, $result),
									$q->td({class=>"sme-border-center", width=>"100"}, $dev . " [ " . $stat . " ]"),
									$q->td({class=>"sme-border-center"}, $devs_up),
									$q->td({class=>"sme-border-center"}, $active),
									$q->td({class=>"sme-border-center"}, $failed),
									$q->td({class=>"sme-border-center"}, $spare),
							);
					}
					else
					{
						print $q->Tr(
									$q->td({class=>"sme-border-center", bgcolor=>"#32CD32", align=>"center", width=>"60"}, $result),
									$q->td({class=>"sme-border-center", width=>"100"}, $dev . " [ " . $stat . " ]"),
									$q->td({class=>"sme-border-center"}, $devs_up),
									$q->td({class=>"sme-border-center"}, $active),
									$q->td({class=>"sme-border-center"}, $failed),
									$q->td({class=>"sme-border-center"}, $spare),
							);
					}
				}
			}
		}
		print $q->end_table;
    		print "<br><br>\n";
			
		print $q->start_table ({-CLASS => "sme-border", width=>"700"});
		print $q->Tr(
			$q->td({class=>"sme-border", bgcolor=>"#32CD32", align=>"center", width=>"60"}),
			$q->td({class=>"sme-border"}, $self->localise('DESCRIPTIONGREEN')),
			);
		print $q->Tr(
			$q->td({class=>"sme-border", bgcolor=>"orange", align=>"center", width=>"60"}),
			$q->td({class=>"sme-border"}, $self->localise('DESCRIPTIONORANGE')),
			);
		print $q->Tr(
			$q->td({class=>"sme-border", bgcolor=>"red", align=>"center", width=>"60"}),
			$q->td({class=>"sme-border"}, $self->localise('DESCRIPTIONRED')),
			);
		print $q->end_table;
                print "<br><br>\n";

	}
	else 		
	{
		print $q->h3 ($self->localise('NORAID'));
		print $q->end_table;
	}
	return "";
}

    ##this routine is to save the properties
    sub apply {
       my ($self) = @_;
       my $q = $self->{cgi};
       $configdb->set_prop('raidstatus', 'mailto', $q->param("mailto"));
       
       return $self->success('SUCCESS','First');
   } 
1;

