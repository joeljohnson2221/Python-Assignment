#!/bin/bash
# source main script
source main.sh
# get stock from ibm and tesla
setup IBM 2023-01-01 2023-01-07 && main
setup TSLA 2023-01-01 2023-01-07 && main
# get all stocks for all time
all %
# get all stocks for 2023-01-05
all 2023-01-05
# get single company data for all time
single ibm %
single tsla %
# get single company data for 2023-01-05
single ibm 2023-01-05
single tsla 2023-01-05
# update ibm table from temp.csv
setup IBM 2023-01-01 2023-01-07 && temp
# get ibm company data for all time
single ibm %