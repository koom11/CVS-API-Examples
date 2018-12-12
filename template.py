#!env python3
# Simple script to put to some substitution in JSON string below
# use whatever template engine (sed?) you prefer

from string import Template
import uuid
import json
from os import environ

# Minimal json template for creating a volume
t = '''
{
    "region": "none",
    "creationToken": "",
    "exportPolicy": {
      "rules": [
        {
          "allowedClients": "0.0.0.0/0",
          "cifs": false,
          "nfsv3": true,
          "nfsv4": false,
          "ruleIndex": 1,
          "unixReadOnly": false,
          "unixReadWrite": true
        }
      ]
    },
    "timezone": "CET",
    "quotaInBytes": 1000000000000,
    "serviceLevel": "standard"
  }
'''

payload = json.loads(t)

# create unique token. required
payload['creationToken'] = 'cvs' + str(uuid.uuid4())
# set region
payload['region'] = environ.get('CVS_DEFAULT_REGION','none')
# set volume size
payload['quotaInBytes'] = 1000000000000
# set service level (standard|premium|extreme)
payload['serviceLevel'] = "standard"

print(json.dumps(payload))