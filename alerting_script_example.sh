#!/bin/bash
#-------------------------------------------------------------------------------------
#
# 				www.datasentinel.io
# 			Performance monitoring tool for PostgreSQL
#
#-------------------------------------------------------------------------------------
#  This is an example of a script that can be executed at each notification.
#  See Alerting documentation for more details
#
#  Parameters received 
#
# $1 - Event time
# $2 - Notificaiton type
# $3 - Postgresql instance
# $4 - Check name
# $5 - State
# $6 - Message
#
# This script simply writes parameters in a log file
#set -x

echo "$1 - $2 - $3 - $4 - $5 - $6 " >> ~/datasentinel_notifications.log