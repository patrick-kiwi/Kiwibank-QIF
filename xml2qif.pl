#!/usr/bin/perl

# Takes multiple Kiwibank XML statement files and merges all the transactions. 
# It then outputs QIF files which encompass all transactions,
# but are are sorted by bank account number!
# Great for for scraping bank records into GNUcash accountancy software
# Author: Patrick O'Connor (patrick_kiwi@protonmail.ch)

use XML::Simple qw(:strict);
use Finance::QIF;
use Data::Dumper;

my $xmldir = "./xmlfiles/"; #Specify XML directory location
opendir(DIR, "$xmldir");
my @FILES= readdir(DIR);
closedir(DIR);

foreach $file (@FILES) { 
if ($file ne "." && $file ne "..") {#file loop
#print "Loading $file\n";

my $config = XMLin("$xmldir$file", 
KeyAttr => { Account => 'MOD11Number' },
ForceArray => ['Account', 'Transaction', 'Line'],
SuppressEmpty => 1,
); #load XML transactions records into a data container

#print Dumper($config); #For debugging - show data container structure

foreach my $account_number (keys %{$config->{'Account'}}) { #AccountNumberLoop
	my $OUTQIF = Finance::QIF->new( file => ">>${account_number}.qif" ); #define QIF object
	#print "Processing transactions from $account_number\n";
	foreach $tran_ref 
	( @{$config->{'Account'}->{"$account_number"}->{'Transaction'}} ) 
	{ #Transactions (belongning to account number) loop
	my $amount = $tran_ref->{'Lines'}->{'Line'}->[0]->{'Amount'};
	my $date = $tran_ref->{'Date'};
	$date =~ s/(\d+)\-(\d+)\-(\d+)/$3\/$2\/$1/;
	my $memo1 = $tran_ref->{'Lines'}->{'Line'}->[0]->{'Description'};
	my $memo2 = $tran_ref->{'Lines'}->{'Line'}->[1]->{'Description'};

		my $record = { #load each transaction into a hash ref
    		header   	=> "Type:Bank", 
    		transaction   	=> "$amount",
    		memo     	=> "${memo1}; ${memo2}",
    		date     	=> "$date",
  		};
	
	$OUTQIF->header( $record->{header} );
  	$OUTQIF->write($record);
	%$record = (); #empty the hash ref

	}#Close Transactions (belongning to account number) loop
	
	$OUTQIF->close();
}##Close Account number loop
}##Close File loop
}
	
