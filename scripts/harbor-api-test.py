#!/usr/bin/env python3

import json
import http.client, urllib.request, urllib.parse, urllib.error
import os
import base64
import sys
import ssl

class Controller:

  def do_create_project(self, name):
    existing = self.check(name)
    if existing:
        returnVal={"status": {"projectid": str(existing)}}
        return returnVal
    conn=http.client.HTTPSConnection(os.environ['HARBOR_HOST'].replace('\n', ''), context=ssl._create_unverified_context())
    userAndPass = base64.b64encode(f"{os.environ['HARBOR_USERNAME']}:{os.environ['HARBOR_PASSWORD']}".encode('UTF-8')).decode('UTF-8')
    headers = { "Authorization": f"Basic {userAndPass}", "Content-Type": "application/json", "Accept": "application/json" }
    # print(f"headers: {headers}")
    # print("Making harbor request")

    conn.request("POST", "/api/v2.0/projects", json.dumps({"project_name": name, "metadata": {"auto_scan": "true", "public": "true"}}), headers)
    r=conn.getresponse()
    responseStatus=r.status
    responseLocation=r.getheader("Location")
    responseBody = r.read()
    conn.close()
    returnVal={}
    # print(f"Got back {responseStatus} with location header {responseLocation} and body: {responseBody}")
    if(responseStatus == 201):
        returnVal={"status": {"projectid": responseLocation.rsplit('/', 1)[-1]}}
    else:
        respObj = json.loads(responseBody)
        returnVal={"status": {"error": respObj}}
    return returnVal

  def dump(self):
    conn=http.client.HTTPSConnection(os.environ['HARBOR_HOST'].replace('\n', ''), context=ssl._create_unverified_context())
    userAndPass = base64.b64encode(f"{os.environ['HARBOR_USERNAME']}:{os.environ['HARBOR_PASSWORD']}".encode('UTF-8')).decode('UTF-8')
    headers = { "Authorization": f"Basic {userAndPass}", "Content-Type": "application/json", "Accept": "application/json" }
    # print(f"headers: {headers}")
    # print("Making harbor request")
    conn.request("GET", "/api/v2.0/projects", {}, headers)
    r=conn.getresponse()
    print(r.read())

  def check(self, name):
    conn=http.client.HTTPSConnection(os.environ['HARBOR_HOST'].replace('\n', ''), context=ssl._create_unverified_context())
    userAndPass = base64.b64encode(f"{os.environ['HARBOR_USERNAME']}:{os.environ['HARBOR_PASSWORD']}".encode('UTF-8')).decode('UTF-8')
    headers = { "Authorization": f"Basic {userAndPass}", "Content-Type": "application/json", "Accept": "application/json" }
    # print(f"headers: {headers}")
    # print("Making harbor request")
    conn.request("GET", "/api/v2.0/projects", {}, headers)
    r=conn.getresponse()
    ret = json.loads(r.read())
    for x in ret: 
        if x["name"] == name: 
            # print(x["project_id"])
            return x["project_id"]
    return 0
    
if __name__ == "__main__":
    if sys.argv[1] == 'create':
        ret = Controller().do_create_project(sys.argv[2])
        print(json.dumps(ret))
        if 'status' in ret and 'projectid' in ret['status']:
            exit(0)
        else:
            exit(1)
    elif sys.argv[1] == 'dump':
        Controller().dump()
    elif sys.argv[1] == 'check':
        Controller().check(sys.argv[2])

