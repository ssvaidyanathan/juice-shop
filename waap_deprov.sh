#!/bin/bash
# Copyright 2022 Google LLC.
# SPDX-License-Identifier: Apache-2.0

# NOTE: this script will deprovision all resources provisioned by the script found here:
#   https://github.com/ssvaidyanathan/juice-shop/blob/master/waap_prov.sh
# TODO: replace both with a Terraform script

read -p "This script will remove all of the WAAP demo resources from your GCP project and Apigee instance. Are you sure? (Y/N)" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

# GCP
gcloud compute --project=$PROJECT_ID addresses delete -q juiceshop-lb-ip --global
gcloud compute --project $PROJECT_ID firewall-rules delete -q "default-allow-http-3000"
gcloud compute --project $PROJECT_ID firewall-rules delete -q "default-allow-https"
gcloud compute --project $PROJECT_ID firewall-rules delete -q "default-allow-http"
gcloud compute --project $PROJECT_ID firewall-rules delete -q "allow-lb-health-check"
gcloud compute --project $PROJECT_ID firewall-rules delete -q "allow-all-egress-juiceshop-https"
gcloud compute --project $PROJECT_ID forwarding-rules delete -q https-content-rule --global
gcloud compute --project $PROJECT_ID target-https-proxies delete -q https-lb-proxy
gcloud compute --project $PROJECT_ID url-maps delete -q web-map-https
gcloud compute --project $PROJECT_ID backend-services delete -q juiceshop-be --global
gcloud compute --project $PROJECT_ID ssl-certificates delete -q juiceshop-lb-cert --global
gcloud compute --project="$PROJECT_ID" -q security-policies delete waap-demo-juice-shop
gcloud beta compute --project=$PROJECT_ID instance-groups managed delete -q juiceshop-demo-mig --zone=$ZONE
gcloud compute --project=$PROJECT_ID instance-templates delete -q juiceshop-demo-mig-template
gcloud compute --project $PROJECT_ID health-checks delete -q juiceshop-healthcheck
export RECAPTCHA_KEY=$(basename $(gcloud recaptcha keys list --format=json | jq -r -c '.[] | select(.displayName == "waap-demo")'.name))
gcloud recaptcha --project $PROJECT_ID keys delete -q $RECAPTCHA_KEY

# Apigee
function token { echo -n "$(gcloud config config-helper --force-auth-refresh | grep access_token | grep -o -E '[^ ]+$')" ; }
export ORG=$APIGEE_ORG
curl --silent -H "Authorization: Bearer $(token)" \
     -X DELETE "https://apigee.googleapis.com/v1/organizations/$APIGEE_ORG/developers/waapdemo@google.com/apps/waap-demo-app"
curl --silent -H "Authorization: Bearer $(token)" \
     -X DELETE "https://apigee.googleapis.com/v1/organizations/$APIGEE_ORG/developers/waapdemo@google.com"
curl --silent -H "Authorization: Bearer $(token)" \
     -X DELETE "https://apigee.googleapis.com/v1/organizations/$APIGEE_ORG/apiproducts/waap-demo-product" 
curl --silent -H "Authorization: Bearer $(token)" \
     -X DELETE "https://apigee.googleapis.com/v1/organizations/$APIGEE_ORG/environments/$APIGEE_ENV/apis/waap-proxy/revisions/1/deployments"
curl --silent -H "Authorization: Bearer $(token)" \
     -X DELETE "https://apigee.googleapis.com/v1/organizations/$APIGEE_ORG/apis/waap-proxy"
curl --silent -H "Authorization: Bearer $(token)" -X DELETE "https://apigee.googleapis.com/v1/organizations/$APIGEE_ORG/environments/$APIGEE_ENV/targetservers/waap-demo-ts"
