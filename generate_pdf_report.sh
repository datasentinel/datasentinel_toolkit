#!/bin/bash
#-------------------------------------------------------------------------------------
#
# 				www.datasentinel.io
# 			Performance monitoring tool for PostgreSQL
#
#-------------------------------------------------------------------------------------
# This script is an example on how to generate a workload report as a PDF file 
#
#set -x

# -------------------------------------------------------------------------------------
# Description
# -------------------------------------------------------------------------------------
usage ()
{
        echo " "
        echo "Usage: $0 -u USER -p PASSWORD -d HOST"
        echo " "
        echo " Parameters :"
        echo " "
        echo "     -u Datasentinel user"
        echo "     -p Datasentinel password"
        echo "     -d Datasentinel host"
        echo " "
exit 1
}
PYTHON_VERSION=3
PYTHON_TOKEN_PARSE="$(cat <<EOF
import sys, json
token=json.load(sys.stdin)
if 'error' in token: 
    print(token['error'])
    sys.exit(1)
else:
    print(token['user-token'])
    sys.exit(0)
EOF
)"
PYTHON_RESPONSE_PARSE="$(cat <<EOF
import sys, json
resp=json.load(sys.stdin)
if 'error' in resp: 
    print(resp['error'])
    sys.exit(1)
elif len(resp) > 1:
    print(resp)
    sys.exit(1)
else:
    print(resp['status'])
    sys.exit(0)
EOF
)"

PYTHON_ERROR_PARSE="$(cat <<EOF
import sys, json
resp=json.load(sys.stdin)
if 'error' in resp: 
    print(resp['error'])
    sys.exit(1)
else:
    sys.exit(0)
EOF
)"

#--------------------------------
# Datasentinel credentials
#--------------------------------
DATASENTINEL_HOST=""
DATASENTINEL_USER="datasentinel"
DATASENTINEL_PASSWORD=""

#--------------------------------
# PostgreSQL parameters
#--------------------------------
PG_INSTANCE="pg-crm-2031@:9342"
FROM_TIME="`date +'%Y-%m-%d'` 00:00:00"
TO_TIME="`date +'%Y-%m-%d'` 06:00:00"

# -------------------------------------------------------------------------------------
# Display step
# -------------------------------------------------------------------------------------
display()
{
echo -e "\n- $1"
echo "----------------------------------------------------------------------------------"
}

#----------------------------------------------------------------------
#  define python scripts
#----------------------------------------------------------------------
check_python() {

type python >/dev/null 2>&1 || { echo >&2 "Python is not installed!"; exit 1; }

pyv="$(python -V 2>&1)"
if [[ "$pyv" =~ "Python 2" ]] 
then 
    PYTHON_VERSION=2
fi
echo -e "Python version: $PYTHON_VERSION\n"
}

#----------------------------------------------------------------------
#  check input parameters
#----------------------------------------------------------------------
check_inputs() {
if [ "$DATASENTINEL_HOST" = "" ]
then
    echo "ERROR: Datasentinel host must be set"
    usage
fi

if [ "$DATASENTINEL_USER" = "" ]
then
    echo "ERROR: Datasentinel user must be set"
    usage
fi

if [ "$DATASENTINEL_PASSWORD" = "" ]
then
    echo "ERROR: Datasentinel password must be set"
    usage
fi

ping -c 1 $DATASENTINEL_HOST >/dev/null 2>&1
if [ $? -ne 0 ] 
then
   echo -e "ERROR: The host $DATASENTINEL_HOST does not ping\n"
   exit 1
fi
curl -sf -k https://$DATASENTINEL_HOST/ds-api/ >/dev/null 2>&1
if [ $? -ne 0 ] 
then
   echo -e "ERROR: Datasentinel API KO on server $DATASENTINEL_HOST\n"
   exit 1
fi

RESPONSE=$(curl -s -k https://$DATASENTINEL_HOST/ds-api/)
echo "$RESPONSE" | python -m json.tool

}

#----------------------------------------------------------------------
#  Generate a valid token
#----------------------------------------------------------------------
generate_token() {

display "Generate an access token"

RESPONSE=$(curl -sku  $DATASENTINEL_USER:$DATASENTINEL_PASSWORD -X POST https://$DATASENTINEL_HOST/ds-api/user-token)
ACCESS_TOKEN=`echo "$RESPONSE" | python -c "$PYTHON_TOKEN_PARSE"`
if [ $? -ne 0 ]
then
    echo -e "\nERROR getting the access token\n$TOKEN\n"
    exit 1
fi

echo "OK"
}


#--------------------------
#  generate a pdf workload
# The example is done with last hour
#--------------------------
create_pdf() {

display "Create a new workload PDF"

TMP_JSON_FILE=/tmp/workload.json
PDF_FILE="workload_${PG_INSTANCE}.pdf"

cat > $TMP_JSON_FILE <<EOF
{
    "utc_time": false,
    "from": "$FROM_TIME",
    "to": "$TO_TIME",
    "filters": [
        {
        "tag": "pg_instance",
        "value": "$PG_INSTANCE"
        }
    ],
    "sections": [
        "pg_instance",
        "top_queries",
        "top_segments",
        "data_size",
        "sessions_workload",
        "parameters"
    ]          
}
EOF

echo -e "\nWorkload Description"
echo "-----------"
cat $TMP_JSON_FILE

curl -sk --header "user-token: $ACCESS_TOKEN" --header 'Content-Type: application/json' -X POST https://$DATASENTINEL_HOST/ds-api/activity/workload-report -d @$TMP_JSON_FILE -o $PDF_FILE

ls -l $PDF_FILE
}


#------------------------------------------------------------------------------
#  MAIN
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#  get parametres
#------------------------------------------------------------------------------
while getopts u:p:d: opt; do
 case $opt in
  u)  DATASENTINEL_USER=$OPTARG;;
  p)  DATASENTINEL_PASSWORD=$OPTARG;;
  d)  DATASENTINEL_HOST=$OPTARG;;
 esac
done

display "Datasentinel PDF workload"

check_python
check_inputs
generate_token
create_pdf
