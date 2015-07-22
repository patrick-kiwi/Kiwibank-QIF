#!/usr/bin/perl

## Author Patrick O'Connor patrick_kiwi@protonmail.ch

## KiwiBank QIF mortgage statements -> GNUcash
## USAGE: mergeSplits.pl BANK_ACCOUNT.qif MORTGAGE_LEDGER.qif
## where BANK_ACCOUNT.qif is the KiwiBank qif download for where the mortgage payments came from
## and MORTGAGE_LEDGER is the KiwiBank mortgage ledger qif summary for the same time period
## This script merges the two files into a single qif file containing correct splits of
## interest and principal.  Note Transaction memo on line 22 is hard coded  

use Finance::QIF;
sub getInterest;

my $INchecque = Finance::QIF->new( file => "$ARGV[0]", autodetect => 1 );
my $out = Finance::QIF->new( file => ">output.qif");

my $header = "";
my $mortTran; #0=date 1=total 2=interest 3=principal

while ( my $record = $INchecque->next() ) { #RecordLoop		
	if ($record->{'memo'} =~ /8166516/ ) { #MatchMortgageDeduction
	$mortTran->[1] = $record->{'transaction'};
	$mortTran->[0] = $record->{'date'};
	&getInterest;	
	$mortTran->[3] =$mortTran->[1] - $mortTran->[2];

	$record->{'splits'} = [
		{ 	'category'	=>	'Liabilities:Mortgages:8CP',
			'memo'		=>	'Principal Payment'
		},
		{	'category'	=>	'Expenses:8CP:Mortgage',
			'memo'		=>	'Interest Payment'
		}];

	$record->{'splits'}->[0]->{'amount'} = "$mortTran->[3]";
	$record->{'splits'}->[1]->{'amount'} = "$mortTran->[2]"; 
} #MatchMortgageDeduction

if ( $header ne $record->{header} ) { #SetHeader
        $out->header( $record->{header} );
        $header = $record->{header};
    } #SetHeader
    $out->write($record);

} #RecordLoop
 
$INchecque->close();
$out->close();


sub getInterest { #SearchMortgageLedger
   		my $INmort = Finance::QIF->new( file => "$ARGV[1]", autodetect => 1 );				
		while ( my $rec = $INmort->next() ) {		
		if ($rec->{'date'} eq $mortTran->[0] and
		$rec->{'memo'} =~ /INTEREST/ ) {
		$mortTran->[2] = $rec->{'transaction'};
				} 
			}
		$INmort->close();
		} #SearchMortgageLedger
