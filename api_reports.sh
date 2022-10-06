#!/bin/bash
#-------------------------------------------------------------------------------------
#
# 		    www.datasentinel.io
# 			Performance monitoring tool for PostgreSQL
#
#-------------------------------------------------------------------------------------
# This script is an example on how to generate reports with the API 
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
PG_INSTANCE="pg-crm-0926@:9342"
PG_INSTANCE="bsdbl003s.cw0lawbqgzjv.eu-west-1.rds.amazonaws.com@pos_staging"
FROM_TIME="`date +'%Y-%m-%d'` 00:00:00"
TO_TIME="`date +'%Y-%m-%d %H'`:00:00"

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


#--------------------------------------------------------------------------------------
#  Generate a The top queries report as a PDF 
#  The example is done with the current day activity
#  The database pgbench is selected and queries are sorted by total_time limited to 20
#--------------------------------------------------------------------------------------
create_top_queries_pdf() {

display "Create top queries PDF"

TMP_JSON_FILE=/tmp/workload.json
PDF_FILE="top_queries_${PG_INSTANCE}.pdf"

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
      "database": "pgbench", 
      "by": "total_time", 
      "limit": 20
}
EOF

echo -e "\nDescription"
echo -e "\nThe report is generated with the current day activity"
echo -e "\nThe database pgbench is selected and queries are sorted by total_time limited to 20"
echo "----------------------------------------------------------------------------------------"
cat $TMP_JSON_FILE

curl -sk --header "user-token: $ACCESS_TOKEN" --header 'Content-Type: application/json' -X POST https://$DATASENTINEL_HOST/ds-api/activity/top-queries-report -d @$TMP_JSON_FILE -o $PDF_FILE

ls -l $PDF_FILE
}

#--------------------------------------------------------------------------------------
#  Send the report directly by email 
#  The example is done with the current day activity
#  All the databases are selected and queries are sorted by total_time limited to 20
#--------------------------------------------------------------------------------------
generate_top_queries_report_and_send_mail() {

display "Create top queries PDF"

TMP_JSON_FILE=/tmp/workload.json
PDF_FILE="top_queries_${PG_INSTANCE}.pdf"

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
      "by": "total_time", 
      "limit": 20,
      "report_type": "email",
      "subject": "[Datasentinel] Current day activity", 
      "recipients": ["contact@datasentinel.io"]
}
EOF

echo -e "\nDescription"
echo -e "\nThe report is generated and sent by email with the current day activity"
echo -e "\nAll the databases are selected and queries are sorted by total_time limited to 20"
echo "----------------------------------------------------------------------------------------"
cat $TMP_JSON_FILE

curl -sk --header "user-token: $ACCESS_TOKEN" --header 'Content-Type: application/json' -X POST https://$DATASENTINEL_HOST/ds-api/activity/top-queries-report -d @$TMP_JSON_FILE -o /dev/null
}


#--------------------------------------------------------------------------------------
#  Generate a the workload sessions report as a PDF 
#  The example is done with the current day activity
#  The database pgbench is selected and queries are sorted by application_name limited to 20
#--------------------------------------------------------------------------------------
create_workload_sessions_pdf() {

display "Create workload sessions PDF"

TMP_JSON_FILE=/tmp/workload.json
PDF_FILE="workload_sessions_${PG_INSTANCE}.pdf"

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
      "database": "pgbench", 
      "group": "application_name", 
      "sub_group": "database", 
      "limit": 20
}
EOF

echo -e "\nDescription"
echo -e "\nThe report is generated with the current day activity"
echo -e "\nThe database pgbench is selected and workload is computed by application_name, by user_name limited to 20 "
echo -e "\nin addition to the 2 dimensions always computed (by wait_event_type and by wait_event)"
echo "----------------------------------------------------------------------------------------"
cat $TMP_JSON_FILE

curl -sk --header "user-token: $ACCESS_TOKEN" --header 'Content-Type: application/json' -X POST https://$DATASENTINEL_HOST/ds-api/activity/sessions-workload-report -d @$TMP_JSON_FILE -o $PDF_FILE

ls -l $PDF_FILE
}

#--------------------------------------------------------------------------------------
#  Send the workload sessions report directly by email 
#  The example is done with the current day activity
#  All the databases are selected and worload is sorted by application_name limited to 20
#--------------------------------------------------------------------------------------
generate_workload_sessions_report_and_send_mail() {

display "Generate workload sessions report and send email"

TMP_JSON_FILE=/tmp/workload.json
PDF_FILE="top_queries_${PG_INSTANCE}.pdf"

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
      "group": "application_name", 
      "sub_group": "database", 
      "limit": 20,
      "report_type": "email",
      "subject": "[Datasentinel] Current day activity", 
      "recipients": ["contact@datasentinel.io"]
}
EOF

echo -e "\nDescription"
echo -e "\nThe report is generated and sent by email with the current day activity"
echo -e "\nAll the databases are selected and workload is computed by application_name, by database limited to 20"
echo -e "\nin addition to the 2 dimensions always computed (by wait_event_type and by wait_event)"
echo "----------------------------------------------------------------------------------------"
cat $TMP_JSON_FILE

curl -sk --header "user-token: $ACCESS_TOKEN" --header 'Content-Type: application/json' -X POST https://$DATASENTINEL_HOST/ds-api/activity/sessions-workload-report -d @$TMP_JSON_FILE -o /dev/null
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

check_python
check_inputs
generate_token
create_top_queries_pdf
generate_top_queries_report_and_send_mail
create_workload_sessions_pdf
generate_workload_sessions_report_and_send_mail