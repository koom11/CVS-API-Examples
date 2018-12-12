#!/bin/bash

# Enter your data here or put it into .env file
export CVS_ACCESS_KEY_ID='your_access_key'
export CVS_SECRET_ACCESS_KEY='your_secret_key'
export CVS_API_URL='https://your_API_endpoint:8080/v1/'
export CVS_DEFAULT_REGION='your_CVS_region'

# Above variables can be sourced from a .env file
if [ -f .env ]; then
    source .env
fi

# List all volumes
echo "Show all volumes"
curl -s -H accept:application/json -H "Content-type: application/json" -H api-key:$CVS_ACCESS_KEY_ID -H secret-key:$CVS_SECRET_ACCESS_KEY \
 -X GET ${CVS_API_URL}FileSystems| jq   # use jq '.[].fileSystemId' for one line per volume

# Create a new volume
echo "Create new volume"
python3 template.py > cmd.json
newvol=$(curl -s -H accept:application/json -H "Content-type: application/json" -H api-key:$CVS_ACCESS_KEY_ID -H secret-key:$CVS_SECRET_ACCESS_KEY -X POST ${CVS_API_URL}FileSystems --data @cmd.json)
# remember fsid for later use
fsid=$(echo $newvol | jq -r .fileSystemId)

# Wait until volume is available
state="x"
until [ "$state" == "available" ]; do
echo -n "."
sleep 2
state=$(curl -s -H accept:application/json -H "Content-type: application/json" -H api-key:$CVS_ACCESS_KEY_ID -H secret-key:$CVS_SECRET_ACCESS_KEY \
 -X GET ${CVS_API_URL}FileSystems/${fsid} | jq -r '.lifeCycleState')
done
echo " done. VolumeID is $fsid"

# Create a snapshot
echo -n "Create snapshot for created volume. Snapshot ID is "
curl -s -H accept:application/json -H "Content-type: application/json" -H api-key:$CVS_ACCESS_KEY_ID -H secret-key:$CVS_SECRET_ACCESS_KEY \
 -X POST ${CVS_API_URL}FileSystems/${fsid}/Snapshots -d '{
  "name": "Backups",
  "region": "IDontKnowWhyThisIsHere",
  "jobs": [
    {}
  ]
}' | jq '.snapshotId'

# List snapshots for our volume
echo "List snapshots for created volume"
curl -s -H accept:application/json -H "Content-type: application/json" -H api-key:$CVS_ACCESS_KEY_ID -H secret-key:$CVS_SECRET_ACCESS_KEY \
 -X GET ${CVS_API_URL}FileSystems/${fsid}/Snapshots | jq

# TODO: Update SLA level or Quota

# ToDo: Create clone

# Cleanup

# Delete the volume we created
echo "Delete volume"
curl -s -H accept:application/json -H "Content-type: application/json" -H api-key:$CVS_ACCESS_KEY_ID -H secret-key:$CVS_SECRET_ACCESS_KEY \
 -X DELETE ${CVS_API_URL}FileSystems/$fsid | jq '.lifeCycleState'

