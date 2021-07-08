#!/bin/bash

# Permission to copy and modify is granted under the Apache License 2.0 
# https://www.apache.org/licenses/LICENSE-2.0
# Last revised 23/06/2021
# Author: Zlatin Todorinski

# Best practices in shell scripting
set -o errexit -o nounset -o noclobber -o pipefail
shopt -s nullglob

if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

help="
Please provide at least 1 argument:

-n number of thread dumps
-p interval to sleep between thread dumps
-o thread dump output folder
-c catalina home dir
-i tomcat process id
-r restart service 'alfresco'

You can supply the number of thread dumps to take (-n) every X seconds (-p).
Additionaly, tomcat P(rocess) ID can be supplied (-i), as well as Catalina Home (-c) that will be used to detect a running tomcat instance.
One can also restart the service with name 'alfresco' by supplying (-r).

E.g. #1 Create 5 thread dumps, one every 3 seconds, and place it in /tmp:
| ./script.sh -n 5 -p 3s -o /tmp

E.g. #2 Use defaults for thread dump, sleep interval and output dir, but provide catalina home dir provided
| ./script.sh -c /usr/local/tomcat 

E.g. #3 Use defaults for thread dump, sleep interval and output dir, but provide tomcat PID and restart service 'alfresco'
| ./script.sh -i 1 -r
"

if [ "$1" == "--help" ] || [ $# -eq 0 ]
then
    echo "$help"
    exit 0
fi

numberOfDumps=""
period=""
outputDir=""
catalinaHome=""
tomcatPid=""
restart=false

while getopts n:p:o:c:i:r: flag
do
    case "${flag}" in
        n) numberOfDumps=${OPTARG};;
        p) period=${OPTARG};;
        o) outputDir=${OPTARG};;
	c) catalinaHome=${OPTARG};;
	i) tomcatPid=${OPTARG};;
	r) restart=true;;
	help) echo "$help" && exit 0;;
    esac
done

if test -z "$numberOfDumps"
then
    echo "Number of thread dumps not supplied, defaulting to 5"
    numberOfDumps=5
fi

if test -z "$period"
then
    echo "Period not supplied, defaulting to 3 seconds"
    period=3s
fi

if test -z "$outputDir"
then
    echo "Output dir not supplied, defaulting to /tmp"
    outputDir="/tmp"
fi

if test -z "$catalinaHome"
then
    if test -z "$CATALINA_HOME"
    then
        echo "Catalina Home dir not supplied, defaulting to /opt/pv/soft/tomcat/alfresco"
        catalinaHome="/opt/pv/soft/tomcat/alfresco"
    else
	echo "Extracting Catalina Home dir from environment variables..."
	catalinaHome="$CATALINA_HOME"
    fi
fi

if test -z "$tomcatPid"
then
    if test -z "$CATALINA_PID"
    then
        if [ -f /.dockerenv ]; then
	    echo "Docker environment detected, setting tomcat PID to 1!"
            tomcatPid=1
        else
	    echo "Tomcat PID not supplied, searching for tomcat instance in $catalinaHome"
            tomcatPid=`ps -aux  | grep "$catalinaHome" | grep -v "grep" | awk '{ print $2 }'`

	    if test -z "$tomcatPid"
            then
	        "Tomcat could not be found! Aborting!"
		exit -1;
	    else
	        echo "Tomcat instance detected with PID $tomcatPid!"
	    fi
        fi
    fi
fi

echo "Capturing $numberOfDumps thread dumps every $period seconds for Tomcat located in $catalinaHome with PID $tomcatPid and writing to $outputDir"

for (( i=1; i<=$numberOfDumps; i++ ))
do
  echo "Creating thread dump $i ..."
  jstack -l $tomcatPid > "$outputDir/thread.dump.`date '+%Y_%m_%d__%H_%M_%S'`.log"
  sleep $period
done

if test -z "$restart"
then
    echo "Restarting service alfresco"
    sudo systemctl restart alfresco
fi

