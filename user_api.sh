#!/bin/bash
#-------------------------------------------------------------------------------------
#
# 				www.datasentinel.io
# 			Performance monitoring tool for PostgreSQL
#
#-------------------------------------------------------------------------------------
# This script is an example on how to manage Users and ROLES with API, 
# and how to assign a role to a user to enable the Role Based Access feature
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
# Role and User properties
#--------------------------------
ROLE_NAME="MyNewRole"
USER_EMAIL="stephane.jambut@sfr.fr"
EXAMPLE_TAG="datacenter"
EXAMPLE_TAG_VALUE="paris"

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
#  Create a new role
#----------------------------------------------------------------------
create_role() {

display "Create a new Role"

TMP_JSON_FILE=/tmp/role.json

cat > $TMP_JSON_FILE <<EOF
{
    "access": [
        {
            "filters": [
                {
                    "tag": "$EXAMPLE_TAG",
                    "value": "$EXAMPLE_TAG_VALUE"
                }
            ]
        }
    ]
}
EOF

echo -e "\nDescription"
echo "-----------"
cat $TMP_JSON_FILE

RESPONSE=$(curl -sk --header "user-token: $ACCESS_TOKEN" --header 'Content-Type: application/json' -X POST https://$DATASENTINEL_HOST/ds-api/roles/$ROLE_NAME -d @$TMP_JSON_FILE)
STATUS=`echo "$RESPONSE" | python -c "$PYTHON_RESPONSE_PARSE"`
if [ $? -ne 0 ]
then
    echo -e "\nERROR creating new role:\n\n$STATUS\n"
    exit 1
fi

echo -e "\nStatus"
echo "------"
echo "$RESPONSE" | python -m json.tool
}

#----------------------------------------------------------------------
#  Display role
#----------------------------------------------------------------------
display_role() {

display "Display role"

RESPONSE=$(curl -sk --header "user-token: $ACCESS_TOKEN" -X GET https://$DATASENTINEL_HOST/ds-api/roles/$ROLE_NAME)
STATUS=`echo "$RESPONSE" | python -c "$PYTHON_ERROR_PARSE"`
if [ $? -ne 0 ]
then
    echo -e "\nERROR getting role:\n\n$RESPONSE\n"
    exit 1
fi

echo "$RESPONSE" | python -m json.tool
}

#----------------------------------------------------------------------
#  Display user
#----------------------------------------------------------------------
display_user() {

display "Display user"

RESPONSE=$(curl -sk --header "user-token: $ACCESS_TOKEN" -X GET https://$DATASENTINEL_HOST/ds-api/users/$USER_EMAIL)
STATUS=`echo "$RESPONSE" | python -c "$PYTHON_ERROR_PARSE"`
if [ $? -ne 0 ]
then
    echo -e "\nERROR getting user:\n\n$RESPONSE\n"
    exit 1
fi

echo "$RESPONSE" | python -m json.tool
}

#----------------------------------------------------------------------
#  Update role (change tags for example)
#----------------------------------------------------------------------
update_role() {

display "Update role"

TMP_JSON_FILE=/tmp/role.json

cat > $TMP_JSON_FILE <<EOF
    {
        "access": [
            {
                "filters": [
                    {
                        "tag": "provider",
                        "value": "aws"
                    }
                ]
            }
        ]
    }
EOF

RESPONSE=$(curl -sk --header "user-token: $ACCESS_TOKEN" --header 'Content-Type: application/json' -X PUT https://$DATASENTINEL_HOST/ds-api/roles/$ROLE_NAME -d @$TMP_JSON_FILE)
STATUS=`echo "$RESPONSE" | python -c "$PYTHON_ERROR_PARSE"`
if [ $? -ne 0 ]
then
    echo -e "\nERROR update role:\n\n$RESPONSE\n"
    exit 1
fi

echo "$RESPONSE" | python -m json.tool
}

#----------------------------------------------------------------------
#  Create a user
#----------------------------------------------------------------------
create_user() {

display "Create a new User"

TMP_JSON_FILE=/tmp/user.json

cat > $TMP_JSON_FILE <<EOF
    {
        "password": "myPassword",
        "privilege": "admin",
        "profile": "data admin",
        "live_360": 1,
        "role": "$ROLE_NAME"
    }
EOF

echo -e "\nDescription"
echo "-----------"
cat $TMP_JSON_FILE

RESPONSE=$(curl -sk --header "user-token: $ACCESS_TOKEN" --header 'Content-Type: application/json' -X POST https://$DATASENTINEL_HOST/ds-api/users/$USER_EMAIL -d @$TMP_JSON_FILE)
STATUS=`echo "$RESPONSE" | python -c "$PYTHON_RESPONSE_PARSE"`
if [ $? -ne 0 ]
then
    echo -e "\nERROR creating new user:\n\n$STATUS\n"
    exit 1
fi

echo -e "\nStatus"
echo "------"
echo "$RESPONSE" | python -m json.tool
}

#----------------------------------------------------------------------
#  Delete user
#----------------------------------------------------------------------
delete_user() {

display "Delete user"

RESPONSE=$(curl -sk --header "user-token: $ACCESS_TOKEN" --header 'Content-Type: application/json' -X DELETE https://$DATASENTINEL_HOST/ds-api/users/$USER_EMAIL)
STATUS=`echo "$RESPONSE" | python -c "$PYTHON_ERROR_PARSE"`
if [ $? -ne 0 ]
then
    echo -e "\nERROR deleting user:\n\n$RESPONSE\n"
    exit 1
fi

echo "$RESPONSE" | python -m json.tool
}

#----------------------------------------------------------------------
#  Delete role
#----------------------------------------------------------------------
delete_role() {

display "Delete role"

RESPONSE=$(curl -sk --header "user-token: $ACCESS_TOKEN" --header 'Content-Type: application/json' -X DELETE https://$DATASENTINEL_HOST/ds-api/roles/$ROLE_NAME)
STATUS=`echo "$RESPONSE" | python -c "$PYTHON_ERROR_PARSE"`
if [ $? -ne 0 ]
then
    echo -e "\nERROR deleting role:\n\n$RESPONSE\n"
    exit 1
fi

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
create_role
display_role
update_role
create_user
display_user
delete_user
delete_role
