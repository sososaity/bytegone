#!/usr/bin/env bash
# Deploy the full CloudFormation stack (Phase 2) in Singapore region.
set -euo pipefail

DOMAIN="${1:-bytegone.app}"
CERT_ARN="${2:-}"
PROFILE="${AWS_PROFILE:-personal}"
REGION="ap-southeast-1"
STACK_NAME="bytegone-landing"

if [[ -z "${CERT_ARN}" ]]; then
  echo "Usage: $0 <DomainName> <CertificateArn>"
  echo ""
  echo "Example:"
  echo "  $0 bytegone.app arn:aws:acm:us-east-1:123456789012:certificate/xxxxx"
  echo ""
  echo "Request a certificate first with:"
  echo "  scripts/deploy-dns.sh ${DOMAIN}"
  echo "  scripts/request-certificate.sh ${DOMAIN}"
  exit 1
fi

echo "▸ Deploying CloudFormation stack: ${STACK_NAME}"
echo "   Domain:        ${DOMAIN}"
echo "   Certificate:   ${CERT_ARN}"
echo "   Profile:       ${PROFILE}"
echo "   Region:        ${REGION}"
echo ""

# --- Cost check ---
echo "▸ Checking estimated monthly cost …"
# Route 53 domain ~$14/yr + hosted zone $0.50/mo
# S3 ~$0.01, CloudFront ~$0–0.50 depending on traffic
ESTIMATED_COST=2.00
echo "   Estimated monthly: ~$${ESTIMATED_COST} USD"
echo "   (Domain ~$1.17 + Route53 zone $0.50 + S3 ~$0.01 + CloudFront ~$0–0.50)"
echo ""

aws cloudformation deploy \
  --stack-name "${STACK_NAME}" \
  --template-file infra/landing-stack.yaml \
  --parameter-overrides \
    DomainName="${DOMAIN}" \
    CertificateArn="${CERT_ARN}" \
  --capabilities CAPABILITY_IAM \
  --profile "${PROFILE}" \
  --region "${REGION}"

echo ""
echo "✓ Stack deployed."
echo ""

# Print outputs
echo "Outputs:"
aws cloudformation describe-stacks \
  --stack-name "${STACK_NAME}" \
  --profile "${PROFILE}" \
  --region "${REGION}" \
  --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
  --output table

echo ""
echo "Next steps:"
echo "  1. Update your domain registrar nameservers to the ones listed above."
echo "  2. Deploy the landing page:  scripts/deploy-landing.sh ${DOMAIN}"
