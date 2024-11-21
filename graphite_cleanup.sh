#!/bin/bash
 
# delete data with no entry in last 90 days
find /opt/graphite/storage/whisper/ -mtime +90 -type f -exec rm -f {} \;
 
#debug: echo "delete data with no entry in the last 90 days is done."
 
# delete empty folders
find /opt/graphite/storage/whisper/ -type d -empty -prune -exec rmdir {} \;
 
# delete carbon-cache log older than 90 days
find /opt/graphite/storage/log/carbon-cache/carbon-cache-a/ -mtime +90 -type f -name '*.log.*' -exec rm -f {} \;
 
# delete graphite webapp log older than 90 days
find /opt/graphite/storage/log/webapp/ -mtime +90 -type f -name '*.log.*' -exec rm -f {} \;
