#!/usr/bin/env python3
import json
import sys

blank_template = {
    "name":"sample-gns",
    "display_name":"Auto-Created GNS",
    "domain_name":"sample.app.com",
    "description":"Auto-Created GNS",
    "mtls_enforced":True,
    "ca_type":"PreExistingCA",
    "ca":"default",
    "version":"1.0",
    "match_conditions":[]
}

def main():
    # print("in main")
    # print(sys.argv[1])
    gns_def = json.loads(sys.argv[1])
    
    gns_name = sys.argv[2]
    gns_domain = sys.argv[3]
    namespace = sys.argv[4]
    cluster_name = sys.argv[5]
    all_cluster_ids = sys.argv[6]

    # bit of a hack...
    cluster_id = None
    all_cluster_ids = json.loads(all_cluster_ids)["ids"]
    
    for cid in all_cluster_ids:
        if cid.startswith(cluster_name):
            cluster_id = cid
            break

    if not cluster_id:
        print("Unable to find cluster id")
        exit(1)
    

    if "code" in gns_def and gns_def['code'] == 404:
        gns = blank_template
        gns['name'] = gns_name
        gns['domain_name'] = gns_domain
    elif "name" in gns_def and "match_conditions" in gns_def and len(gns_def['match_conditions']) >= 1:
        gns = gns_def
    else:
        print("Could not make sense of the GNS definition passed in")
        exit(1)    
    gns['match_conditions'].append({'namespace': {'match': namespace, 'type': 'EXACT'}, 'cluster': {'match': cluster_id, 'type': 'EXACT'}})    
    
    print(json.dumps(gns))  



if __name__=='__main__':
    main()