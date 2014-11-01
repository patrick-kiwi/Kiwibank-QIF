xmltoqif
========

xml2qif.pl converts multiple Kiwibank xml files into QIF ledgers.  Each new QIF file contains a summary of all transactions in the input xml files.  Great for scraping historical records, althought I've found that kiwibank misses a transaction every now and then.

mergeMort.pl source.qif mort_ledger.qif - Takes a kiwibank qif download and incorperates the mortgage ledger qif.  The output is a modified source.qif file wheere the mortgage payments have splits with interest and principal.  If you're inporting the file into GNUcash you can automatically allocate interest payments to increasing costs:mortgage and principal payments to decreasing mortgage liabilities.


