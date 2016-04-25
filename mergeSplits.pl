#!/usr/bin/perl

## Author Patrick O'Connor patrick_kiwi@protonmail.ch

## KiwiBank QIF mortgage statements -> GNUcash
## USAGE: mergeSplits.pl SOURCE_BANK_ACCOUNT.qif
## where SOURCE_BANK_ACCOUNT.qif is a qif download of the account from which the mortgage payments came.
## For the script to work you also need to have in the same directory the 
## qif downloads of the mortgage ledger accounts covering the same time period
## This script merges the interest and principal into a single qif file containing propper splits.

use strict;
use warnings;
use Finance::QIF;
use Time::Piece;
sub getInterest;


## This info has to be manually set up.  The AP (automatic payment) numbers have to associate with some details about each mortgage 
## The "details" are threefold.  Firstly, the house or asset each mortgage is associated with.  Secondly,
## the bank account number of mortgage ledger - (this will be different to the bank
## account number of where the mortgage payments are coming from).  Thridly a personalised name to identify each mortgage to GNU cash.

my %APmap = ( '8165516' 	=> 	['8 Dowse Drive','38-9015-0882706-00','50K10Year'],
	      '10555042'	=>	['203 Kohimamama Road','38-9015-0488706-06','50K30Year'],
	      '15547034'	=> 	['203 Kohimarama Road','38-9015-0488706-05','117K30Year'],
	      '15547028'	=>	['203 Kohimarama Road','38-9015-0488706-04','160K30Year'],
              '15547025'	=>	['203 Kohimarama Road','38-9015-0488706-03','160K30Year'],
);

my $INchecque = Finance::QIF->new( file => "$ARGV[0]", autodetect => 1 );
my $out = Finance::QIF->new( file => ">output.qif");
my $seen;

my $header = "";
my $mortTran; #0=date 1=total 2=interest 3=principal

while ( my $record = $INchecque->next() ) { #RecordLoop		
	if ($record->{'memo'} =~ /AP#(\d+)/ ) { 	#MatchMortgageDeduction
	my $apNumber = $1; 				#reccord ap number
	my $property = $APmap{$apNumber}->[0];		#property associated with mortgage payment
	my $mortLedger = $APmap{$apNumber}->[1];	#Bank account Number of the mortgage ledger
	my $mortID = $APmap{$apNumber}->[2];		#Personal comment to ID for each mortgage
	$mortTran->[1] = $record->{'transaction'}; 	#record transaction amount
	$mortTran->[0] = $record->{'date'};		#reccord date
	&getInterest($apNumber); 			#pass the subroutine the apNumber	
	$mortTran->[3] =$mortTran->[1] - $mortTran->[2];#Calculate principal

	$record->{'splits'} = [
		{ 	'category'	=>	"Liabilities:Mortgages:$property:$mortLedger",
			'memo'		=>	"Principal Payment $mortID"
		},
		{	'category'	=>	"Expenses:$property:Mortgage:$mortLedger",
			'memo'		=>	"Interest Payment $mortID"
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
my $apNum = shift;
my $format = "%d/%m/%y";
my $d1 = Time::Piece->strptime($mortTran->[0], $format);
my $mortAccount = $APmap{$apNum}->[1];
my $INmort = Finance::QIF->new( file => glob("$mortAccount*"), autodetect => 1 );				
		while ( my $rec = $INmort->next() ) {
			my $d2 = Time::Piece->strptime($rec->{'date'}, $format);		
			if (abs($d1-$d2) <= 345600 and $rec->{'memo'} =~ /INTEREST/ ) {
				$mortTran->[2] = $rec->{'transaction'};
			} 
		}
		$INmort->close();
} #SearchMortgageLedger

