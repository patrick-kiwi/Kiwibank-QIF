#!/usr/bin/perl

# Takes a bunch of Kiwibank XML files and converts them into
# QIF files - one QIF file per bank account number!
# Good for scraping bank records into GNUcash accountancy software
# Author: Patrick O'Connor (patrick_kiwi@protonmail.ch)

use XML::Simple qw(:strict);
use Finance::QIF;
use Data::Dumper;

# Specify location of .xml files,
# (one directory up from perl executable)

my $xmldir = "./xmlfiles/";
opendir(DIR, "$xmldir");
my @FILES= readdir(DIR);
closedir(DIR);

#global variables
my $account_numbers; #array ref containing all account numbers

foreach $file (@FILES) { #File Loop
if ($file ne "." && $file ne "..") {#If real files loop
print "Processing $file\n";

 
my $config = XMLin("$xmldir$file", 
KeyAttr => { Account => 'MOD11Number' },
ForceArray => ['Account', 'Transaction', 'Line'],
SuppressEmpty => 1,
);

#print Dumper($config);

foreach ( keys %{$config->{'Account'}}) { #AccountNumberLoop
push @$account_numbers, $_;		  #load array ref again
}

foreach my $account_number (@$account_numbers) {
#print "$account_number\n";
my $qif = Finance::QIF->new( file => "+>>$account_number" );
	foreach $tran_ref 
	( @{$config->{'Account'}->{"$account_number"}->{'Transaction'}} ) 
	{ #Transaction (per account number) loop
	my $amount = $tran_ref->{'Lines'}->{'Line'}->[0]->{'Amount'};
	my $date = $tran_ref->{'Date'};
	$date =~ s/(\d+)\-(\d+)\-(\d+)/$3\/$2\/$1/;
	my $payee = $tran_ref->{'Lines'}->{'Line'}->[0]->{'Description'};
	my $memo = $tran_ref->{'Lines'}->{'Line'}->[1]->{'Description'};

		my $record = {
    		header   	=> "Type:Bank", 
    		transaction   	=> "$amount",
    		payee    	=> "$payee",
    		memo     	=> "$memo",
    		date     	=> "$date",
  		};
	$qif->header( $record->{header} );
  	$qif->write($record);
	}##Transaction (per account number) loop
$qif->close;
}##Account number loop
}###If real file loop
}##File loop	
	
