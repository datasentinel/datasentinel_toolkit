#!/bin/bash
#-------------------------------------------------------------------------------------
#
# 				www.datasentinel.io
# 			Performance monitoring tool for PostgreSQL
#
#-------------------------------------------------------------------------------------
# This script is an example on how to manage PostgreSQL connections with API
# It uses the Agentless feature of Datasentinel
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

#--------------------------------
# Datasentinel credentials
#--------------------------------
DATASENTINEL_HOST=""
DATASENTINEL_USER="datasentinel"
DATASENTINEL_PASSWORD=""

#--------------------------------
# PostgreSQL connection
#--------------------------------
PG_NAME="crm-production"
PG_HOST="51.15.246.7"
PG_PORT=9342
PG_USER="datasentinel"
PG_PASSWORD="sentinel"
PG_TAGS="datacenter=paris,provider=aws,environment=production"


# -------------------------------------------------------------------------------------
# Display step
# -------------------------------------------------------------------------------------
display()
{
echo -e "\n\n- $1"
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

RESPONSE=$(curl -s -k https://51.158.105.50/ds-api/)
if [ $? -ne 0 ] 
then
   echo -e "ERROR: Datasentinel API status on $DATASENTINEL_HOST NOT OK\n"
   exit 1
fi
echo "$RESPONSE" | python -m json.tool

}

#----------------------------------------------------------------------
#  Generate a valid token
#----------------------------------------------------------------------
generate_token() {

display "Generate an access token"

RESPONSE=$(curl -sk -u $DATASENTINEL_USER:$DATASENTINEL_PASSWORD -X POST https://$DATASENTINEL_HOST/ds-api/user-token)
ACCESS_TOKEN=`echo "$RESPONSE" | python -c "$PYTHON_TOKEN_PARSE"`
if [ $? -ne 0 ]
then
    echo -e "\nERROR getting the access token\n$TOKEN\n"
    exit 1
fi

echo "OK"
}


#----------------------------------------------------------------------
#  submit a new connection to Datasentinel
#----------------------------------------------------------------------
create_connection() {

display "Create a new connection"

TMP_JSON_FILE=/tmp/connection.json

cat > $TMP_JSON_FILE <<EOF
{
  "host": "$PG_HOST",
  "port": $PG_PORT,
  "user": "$PG_USER",
  "password": "$PG_PASSWORD",
  "tags": "$PG_TAGS"
}
EOF

cat $TMP_JSON_FILE

RESPONSE=$(curl -sk --header "user-token: $ACCESS_TOKEN" --header 'Content-Type: application/json' -X POST https://$DATASENTINEL_HOST/ds-api/pool/pg-instances/$PG_NAME -d @$TMP_JSON_FILE)
STATUS=`echo "$RESPONSE" | python -c "$PYTHON_RESPONSE_PARSE"`
if [ $? -ne 0 ]
then
    echo -e "\nERROR creating new connection:\n\n$STATUS\n"
    exit 1
fi

echo "OK"
echo "$RESPONSE" | python -m json.tool
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

display "Datasentinel toolkit"

check_python
check_inputs
generate_token
create_connection