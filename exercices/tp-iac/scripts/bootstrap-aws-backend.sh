#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

: "${TF_STATE_BUCKET:?Définissez TF_STATE_BUCKET avec un nom S3 globalement unique.}"
AWS_REGION="${AWS_REGION:-eu-west-3}"

if [[ "$AWS_REGION" == "us-east-1" ]]; then
    aws s3api create-bucket \
        --bucket "$TF_STATE_BUCKET" \
        --region "$AWS_REGION"
else
    aws s3api create-bucket \
        --bucket "$TF_STATE_BUCKET" \
        --region "$AWS_REGION" \
        --create-bucket-configuration "LocationConstraint=$AWS_REGION"
fi

aws s3api put-public-access-block \
    --bucket "$TF_STATE_BUCKET" \
    --public-access-block-configuration \
    'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'

aws s3api put-bucket-versioning \
    --bucket "$TF_STATE_BUCKET" \
    --versioning-configuration 'Status=Enabled'

aws s3api put-bucket-encryption \
    --bucket "$TF_STATE_BUCKET" \
    --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'

printf 'Backend AWS prêt : bucket=%s région=%s\n' "$TF_STATE_BUCKET" "$AWS_REGION"
