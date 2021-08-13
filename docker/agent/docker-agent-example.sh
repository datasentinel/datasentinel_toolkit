#!/bin/bash
#-------------------------------------------------------------------------------------
#
# 				www.datasentinel.io
# 			Performance monitoring tool for PostgreSQL
#
#-------------------------------------------------------------------------------------
# This script is an example on how to use the agent within Docker 
#
# 
# The Postgres cluster used in this example is preconfigured with pg_stats_statements, pg_store_plans and datasentinel extensions installed.
# pg_stat_statements is required by Datasentinel. The 2 others are optional.
#
# To use this example, you need a running Datasentinel platform either inside docker, on-premises or as a SaaS
# 
# https://www.datasentinel.io/documentation/
#set -x

# -------------------------------------------------------------------------------------
# Description
# -------------------------------------------------------------------------------------
usage ()
{
        echo " "
        echo "Usage: $0 -d HOST"
        echo " "
        echo " Parameters :"
        echo " "
        echo "     -d Datasentinel platform server"
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
# Datasentinel platform credentials
#--------------------------------
DATASENTINEL_HOST=""

#--------------------------------
# Datasentinel agent properties
#--------------------------------
DATASENTINEL_AGENT_HOST=`hostname`
DATASENTINEL_AGENT_PORT=8383
FAKE_TOKEN="eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE2Mjg1OTM5MDEsImlhdCI6MTYyODUwNzQ5NiwiZGF0YWJhc2UiOiJkcy1kYXRhIn0.zdf_qqQkoGsmPfsT1ZNY8el3V9VOJE_MnSJss_GtOac"

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
#  Pull and run an agent
#----------------------------------------------------------------------
install_agent() {

display "Install agent"

# Because the agent registers the server name and listening port to the platform, 
# you need to expose them externally and pass the values when running a new agent. This allows the platform to communicate with the agent.

docker run -d --name datasentinel-agent -p $DATASENTINEL_AGENT_PORT:$DATASENTINEL_AGENT_PORT -e DATASENTINEL_AGENT_HOST=$DATASENTINEL_AGENT_HOST -e DATASENTINEL_AGENT_PORT=$DATASENTINEL_AGENT_PORT datasentinel/datasentinel-agent
if [ $? -ne 0 ]
then
    echo -e "\nERROR Error running the agent\n"
    exit 1
fi
}

#----------------------------------------------------------------------
#  Pull and run postgres cluster
#----------------------------------------------------------------------
install_postgres_cluster() {

display "Install postgres cluster"

docker run -d --name postgres-1 datasentinel/postgres-template
if [ $? -ne 0 ]
then
    echo -e "\nERROR Error running the postgres cluster\n"
    exit 1
fi
}

#----------------------------------------------------------------------
#  Update Token (You need a valid license)
#----------------------------------------------------------------------
update_token() {

display "Update token"

TMP_JSON_FILE=/tmp/token.json

cat <<EOF >$TMP_JSON_FILE
{
    "value" : "$FAKE_TOKEN"
}
EOF

RESPONSE=$(curl -sk --header 'Content-Type: application/json' --request PUT "https://${DATASENTINEL_AGENT_HOST}:${DATASENTINEL_AGENT_PORT}/api/server/token" -d @$TMP_JSON_FILE)
STATUS=`echo "$RESPONSE" | python -c "$PYTHON_ERROR_PARSE"`
if [ $? -ne 0 ]
then
    echo -e "\nERROR update token:\n\n$RESPONSE\n"
    exit 1
fi
}

#----------------------------------------------------------------------
#  Set the platform server where to send metrics
#----------------------------------------------------------------------
set_platform_server() {

display "Set Platform Server"

TMP_JSON_FILE=/tmp/upload.json

cat <<EOF >$TMP_JSON_FILE
{
  "host": "$DATASENTINEL_HOST",
  "port": 443
}
EOF

RESPONSE=$(curl -sk --header "api-token: $FAKE_TOKEN" --header 'Content-Type: application/json' -X PUT https://${DATASENTINEL_AGENT_HOST}:${DATASENTINEL_AGENT_PORT}/api/server -d @$TMP_JSON_FILE)
STATUS=`echo "$RESPONSE" | python -c "$PYTHON_ERROR_PARSE"`
if [ $? -ne 0 ]
then
    echo -e "\nERROR update platform server:\n\n$RESPONSE\n"
    exit 1
fi

echo "$RESPONSE" | python -m json.tool
}

#----------------------------------------------------------------------
#  Add Postgres connection
#----------------------------------------------------------------------
add_connection() {

display "Add a connection"

TMP_JSON_FILE=/tmp/connection.json

cat > $TMP_JSON_FILE <<EOF
{
  "host": "$DATASENTINEL_AGENT_HOST",
  "port": 5432,
  "user": "datasentinel",
  "password": "postgres",
  "tags": "environment=docker,datacenter=london"
}
EOF

echo -e "\nDescription"
echo "-----------"
cat $TMP_JSON_FILE

RESPONSE=$(curl -sk --header "api-token: $FAKE_TOKEN" --header 'Content-Type: application/json' --request POST "https://${DATASENTINEL_AGENT_HOST}:${DATASENTINEL_AGENT_PORT}/api/connections/pg_docker_example" -d @$TMP_JSON_FILE)
STATUS=`echo "$RESPONSE" | python -c "$PYTHON_RESPONSE_PARSE"`
if [ $? -ne 0 ]
then
    echo -e "\nERROR creating new connection:\n\n$STATUS\n"
    exit 1
fi

echo "$RESPONSE" | python -m json.tool
}

#----------------------------------------------------------------------
#  Agent status
#----------------------------------------------------------------------
display_status() {

display "Display status"

curl -k https://${DATASENTINEL_AGENT_HOST}:${DATASENTINEL_AGENT_PORT}/api/agent/status
if [ $? -ne 0 ]
then
    echo -e "\nERROR getting agent status\n"
    exit 1
fi
}

#------------------------------------------------------------------------------
#  MAIN
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#  get parametres
#------------------------------------------------------------------------------
while getopts d: opt; do
 case $opt in
  d)  DATASENTINEL_HOST=$OPTARG;;
 esac
done

display "Datasentinel agent docker"

check_python
check_inputs
install_agent
install_postgres_cluster
echo -s "\nsleep 10 seconds waiting for the agent to be up"
sleep 10
update_token
set_platform_server
add_connection
display_status
