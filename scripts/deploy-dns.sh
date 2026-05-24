#!/usr/bin/env bash
# Deploy Phase 1: Create Route 53 hosted zone for DNS validation.
set -euo pipefail

DOMAIN="${1:-bytegone.app}"
PROFILE="${AWS_PROFILE:-personal}"
REGION="ap-southeast-1"
STACK_NAME="bytegone-dns"

echo "▸ Phase 1 — Creating Route 53 hosted zone for ${DOMAIN} …"
echo "   Profile: ${PROFILE}"
echo "   Region:  ${REGION}"
echo ""

aws cloudformation deploy \
  --stack-name "${STACK_NAME}" \
  --template-file infra/dns-stack.yaml \
  --parameter-overrides DomainName="${DOMAIN}" \
  --profile "${PROFILE}" \
  --region "${REGION}"

echo ""
echo "✓ Hosted zone created."
echo ""

# Print outputs
aws cloudformation describe-stacks \
  --stack-name "${STACK_NAME}" \
  --profile "${PROFILE}" \
  --region "${REGION}" \
  --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
  --output table

echo ""
echo "Next steps:"
echo "  1. Request the ACM certificate:  scripts/request-certificate.sh ${DOMAIN}"
