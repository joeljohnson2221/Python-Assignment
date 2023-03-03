#!/bin/bash

# sudo apt-get update -yqq
# sudo apt-get install wget -yqq

function setup() {
if [ ! -f sqlite3 ]; then
    wget -q https://github.com/CompuRoot/static-sqlite3/releases/download/3.37.0/sqlite3
    chmod a+rx sqlite3
fi
SQLITE3="./sqlite3"
DB_NAME="db.sqlite3"
BASE_URL="https://query1.finance.yahoo.com/v7/finance/download"
COMPANY="$1"
START_TIME="period1=$(date -d "$2 12:00:00" +%s)"
END_TIME="period2=$(date -d "$3 12:00:00" +%s)"
INTERVAL="interval=1d"
EVENTS="events=history"
ADJUSTED_CLOSE_ON="includeAdjustedClose=true"
curl -s "$BASE_URL/$COMPANY?$START_TIME&$END_TIME&$INTERVAL&$EVENTS&$ADJUSTED_CLOSE_ON" > data.csv
COMPANY_LCASE=$(tr "[:upper:]" "[:lower:]" <<< "$COMPANY")
}

function main() {
# MAIN TABLE
$SQLITE3 $DB_NAME "drop table if exists $COMPANY_LCASE;"
CREATE_MAIN_TBL=$(head -n1 < data.csv |\
    sed "s/[[:space:]]/_/g;
        s/,/ varchar, /g;
        s/$/ varchar\\)\;/g;
        s/^/create table if not exists $COMPANY_LCASE \\(/g" |\
            tr "[:upper:]" "[:lower:]")

$SQLITE3 $DB_NAME "$CREATE_MAIN_TBL"

$SQLITE3 $DB_NAME <<EOF
.mode csv
.import data.csv $COMPANY_LCASE
EOF

echo -e "\nTBL: $COMPANY_LCASE BEFORE UPDATIONS"
$SQLITE3 $DB_NAME "select * from $COMPANY_LCASE"
echo -e "\n"
}

function temp() {
# TEMP TABLE
echo -e "2023-01-03,1,1,1,1,1,1
2023-01-04,1,1,1,1,1,1
2023-01-05,1,1,1,1,1,1
2023-01-06,1,1,1,1,1,1
1970-01-01,1,1,1,1,1,1
1970-02-01,1,1,1,1,1,1
1970-03-01,1,1,1,1,1,1
1970-04-01,1,1,1,1,1,1" > temp.csv

$SQLITE3 $DB_NAME "drop table if exists temp;"
IMPORT_TEMP_TBL=$(head -n1 < data.csv |\
    sed "s/[[:space:]]/_/g;
        s/,/ varchar, /g;
        s/$/ varchar\\)\;/g;
        s/^/create table if not exists temp \\(/g" |\
            tr "[:upper:]" "[:lower:]")

$SQLITE3 $DB_NAME "$IMPORT_TEMP_TBL"

$SQLITE3 $DB_NAME <<EOF
.mode csv
.import temp.csv temp
EOF

echo -e "\nTBL: temp"
$SQLITE3 $DB_NAME "select * from temp"

$SQLITE3 $DB_NAME <<EOF
insert into $COMPANY_LCASE
    select * from temp
        where not exists (
            select * from $COMPANY_LCASE where $COMPANY_LCASE.date = temp.date
        );
EOF

ROWS=$($SQLITE3 $DB_NAME "SELECT name FROM PRAGMA_TABLE_INFO('$COMPANY_LCASE');" |\
        tr '\n' ',' |\
            sed "s/,$/\n/g")
TEMP_Q=$($SQLITE3 $DB_NAME "SELECT name FROM PRAGMA_TABLE_INFO('$COMPANY_LCASE');" |\
            sed "s/\(.*\)/temp.\1/g" |\
                tr '\n' ','|\
                    sed "s/,$/\n/g")
$SQLITE3 $DB_NAME <<EOF
update $COMPANY_LCASE
set ($ROWS) = ($TEMP_Q)
from temp
where temp.date = $COMPANY_LCASE.date
EOF
echo -e "\n"
}

single() {
echo -e "\nCOMPANY DATA FOR $1 ON $2"
$SQLITE3 $DB_NAME "select * from $1 where $1.date like '%$2%'"
echo -e "\n"
}

all() {
echo -e "\nALL COMPANY DATA FOR $1"
$SQLITE3 $DB_NAME "$($SQLITE3 $DB_NAME ".tables" |\
                         column -t |\
                             sed "s/  /,/g" |\
                                tr ',' '\n' |\
                                    grep -v temp |\
                                        sed "s/^/select * from /g;
                                             s/$/ where date like '%$1%'\\nunion all/g" |\
                                                head -n-1)" |\
                                                     grep -v Date
echo -e "\n"
}
# setup
# main
# temp
# single
# all