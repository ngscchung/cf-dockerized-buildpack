#!/bin/sh

set -e
set -u

cf login -a "$CF_API" -u "$CF_USER" -p "$CF_PASS" -o "$CF_ORG" -s "$CF_SPACE"
cf create-service s3 basic "${APP_NAME}-s3"
cf create-service-key "${APP_NAME}-s3" "${APP_NAME}-auth"

cf service-key "${APP_NAME}-s3" "${APP_NAME}-auth" | awk 'FNR > 1 { print }' > build/auth.json

cf push "${APP_NAME}" -o library/registry:2
cf set-env "${APP_NAME}" REGISTRY_STORAGE "s3"
cf set-env "${APP_NAME}" REGISTRY_STORAGE_S3_ACCESSKEY "$(jq -r .access_key_id < build/auth.json)"
cf set-env "${APP_NAME}" REGISTRY_STORAGE_S3_SECRETKEY "$(jq -r .secret_access_key < build/auth.json)"
cf set-env "${APP_NAME}" REGISTRY_STORAGE_S3_BUCKET "$(jq -r .bucket < build/auth.json)"
cf set-env "${APP_NAME}" REGISTRY_STORAGE_S3_REGION "$(jq -r .region < build/auth.json)"
cf set-env "${APP_NAME}" REGISTRY_STORAGE_MAINTENANCE_READONLY "enabled: true"
cf restage "${APP_NAME}"

cat <<EOF > build/registry-service-auth
REGISTRY_STORAGE=s3
REGISTRY_STORAGE_S3_ACCESSKEY="$(jq -r .access_key_id < build/auth.json)"
REGISTRY_STORAGE_S3_SECRETKEY="$(jq -r .secret_access_key < build/auth.json)"
REGISTRY_STORAGE_S3_BUCKET="$(jq -r .bucket < build/auth.json)"
REGISTRY_STORAGE_S3_REGION="$(jq -r .region < build/auth.json)"
EOF