#!/usr/bin/env bash
# Request an ACM certificate in us-east-1 and add DNS validation records to Route 53.
set -euo pipefail

DOMAIN="${1:-bytegone.app}"
PROFILE="${AWS_PROFILE:-personal}"

echo "▸ Requesting ACM certificate for ${DOMAIN} and www.${DOMAIN} …"
echo "   Profile: ${PROFILE}"
echo "   Region:  us-east-1 (required for CloudFront)"
echo ""

CERT_ARN=$(aws acm request-certificate \
  --domain-name "${DOMAIN}" \
  --subject-alternative-names "www.${DOMAIN}" \
  --validation-method DNS \
  --region us-east-1 \
  --profile "${PROFILE}" \
  --query 'CertificateArn' \
  --output text)

echo "✓ Certificate requested: ${CERT_ARN}"
echo ""

# Wait a moment for ACM to generate the validation records
sleep 5

echo "▸ Fetching DNS validation records …"
VALIDATION_RECORDS=$(aws acm describe-certificate \
  --certificate-arn "${CERT_ARN}" \
  --region us-east-1 \
  --profile "${PROFILE}" \
  --query 'Certificate.DomainValidationOptions[*].ResourceRecord' \
  --output json)

echo "   Validation records: ${VALIDATION_RECORDS}"
echo ""

# Get hosted zone ID
HOSTED_ZONE_ID=$(aws cloudformation list-exports \
  --profile "${PROFILE}" \
  --region ap-southeast-1 \
  --query "Exports[?Name=='HostedZoneId'].Value" \
  --output text)

if [[ -z "${HOSTED_ZONE_ID}" ]]; then
  echo "❌ Could not find HostedZoneId export. Run deploy-dns.sh first."
  exit 1
fi

echo "▸ Adding DNS validation records to hosted zone ${HOSTED_ZONE_ID} …"

# Build the changes JSON
CHANGES=$(echo "${VALIDATION_RECORDS}" | python3 -c '
import json, sys
records = json.load(sys.stdin)
changes = []
for r in records:
    changes.append({
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": r["Name"],
            "Type": r["Type"],
            "TTL": 300,
            "ResourceRecords": [{"Value": r["Value"]}]
        }
    })
print(json.dumps({"Changes": changes}))
')

aws route53 change-resource-record-sets \
  --hosted-zone-id "${HOSTED_ZONE_ID}" \
  --change-batch "${CHANGES}" \
  --profile "${PROFILE}" \
  --region ap-southeast-1

echo ""
echo "✓ Validation records added to Route 53."
echo ""
echo "Next steps:"
echo "  1. Wait for certificate validation (can take 5–30 minutes):"
echo "       aws acm describe-certificate --certificate-arn ${CERT_ARN} --region us-east-1"
echo "  2. Once status is ISSUED, deploy the full stack:"
echo "       scripts/deploy-stack.sh ${DOMAIN} ${CERT_ARN}"
echo ""
echo "Certificate ARN (save this):"
echo "   ${CERT_ARN}"
