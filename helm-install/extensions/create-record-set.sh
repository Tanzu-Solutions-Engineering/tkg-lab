#!/bin/bash -e

export AWS_ACCESS_KEY_ID=$(yq r $PARAM_FILE aws.access-key-id)
export AWS_SECRET_ACCESS_KEY=$(yq r $PARAM_FILE aws.secret-access-key)
export TMP_DNS_FILE=$RANDOM-temp.json
export DNS_FILE=$CLUSTER_NAME-$RANDOM.json

jq -c '.Changes[0].ResourceRecordSet.Name = $newVal' --arg newVal $DNS_NAME $RECORDSET_FILE > ./generated/$TMP_DNS_FILE
jq -c '.Changes[0].ResourceRecordSet.ResourceRecords[0].Value = $newVal' --arg newVal $IP ./generated/$TMP_DNS_FILE > ./generated/$DNS_FILE
rm ./generated/$TMP_DNS_FILE
aws route53 change-resource-record-sets --hosted-zone-id $(yq r $PARAM_FILE aws.dns.hosted-zone-id) --change-batch file://./generated/$DNS_FILE