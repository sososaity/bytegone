#!/usr/bin/env bash
# Deploy landing page files to S3 and invalidate the CloudFront cache.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${PROJECT_ROOT}"

PROFILE="${AWS_PROFILE:-personal}"
REGION="ap-southeast-1"
DOMAIN="${1:-bytegone.app}"
BUCKET="${DOMAIN}"

echo "▸ Resolving CloudFront Distribution ID …"
DISTRIBUTION_ID=$(aws cloudformation list-exports \
  --profile "${PROFILE}" \
  --region "${REGION}" \
  --query "Exports[?Name=='bytegone-distribution-id'].Value" \
  --output text)

if [[ -z "${DISTRIBUTION_ID}" ]]; then
  echo "❌ Could not find CloudFront Distribution ID export."
  echo "   Deploy the CloudFormation stack first:"
  echo "       scripts/deploy-stack.sh ${DOMAIN} <CertificateArn>"
  exit 1
fi

echo "   Distribution: ${DISTRIBUTION_ID}"
echo ""

echo "▸ Copying landing.html → index.html …"
cp landing.html index.html

echo "▸ Syncing to s3://${BUCKET} …"
aws s3 sync . "s3://${BUCKET}/" \
  --profile "${PROFILE}" \
  --exclude "*" \
  --include "index.html" \
  --include "landing.html" \
  --include "dist/Bytegone.zip" \
  --include "og-image.png" \
  --cache-control "max-age=3600" \
  --delete

rm -f index.html

echo ""
echo "▸ Invalidating CloudFront cache …"
aws cloudfront create-invalidation \
  --profile "${PROFILE}" \
  --distribution-id "${DISTRIBUTION_ID}" \
  --paths "/*" \
  --query 'Invalidation.Id' \
  --output text

echo ""
echo "✓ Deployed to https://${DOMAIN}/"
