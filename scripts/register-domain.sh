#!/usr/bin/env bash
# Register the domain via Route 53 and update nameservers.
set -euo pipefail

DOMAIN="${1:-bytegone.app}"
PROFILE="${AWS_PROFILE:-personal}"
REGION="ap-southeast-1"

echo "▸ Fetching hosted zone nameservers for ${DOMAIN} …"
HOSTED_ZONE_ID=$(aws cloudformation list-exports \
  --profile "${PROFILE}" \
  --region "${REGION}" \
  --query "Exports[?Name=='bytegone-zone-id'].Value" \
  --output text)

if [[ -z "${HOSTED_ZONE_ID}" ]]; then
  echo "❌ Could not find HostedZoneId export. Deploy the CloudFormation stack first."
  exit 1
fi

NAMESERVERS=$(aws route53 get-hosted-zone \
  --profile "${PROFILE}" \
  --id "${HOSTED_ZONE_ID}" \
  --query 'DelegationSet.NameServers' \
  --output text)

echo "   Hosted Zone: ${HOSTED_ZONE_ID}"
echo "   Nameservers: ${NAMESERVERS}"
echo ""

echo "▸ Checking domain registration status …"
if aws route53domains get-domain-detail \
     --profile "${PROFILE}" \
     --domain-name "${DOMAIN}" >/dev/null 2>&1; then
  echo "   Domain ${DOMAIN} is already registered."
else
  echo "   Domain ${DOMAIN} is NOT registered."
  echo ""
  echo "Register it manually via the AWS console or CLI:"
  echo ""
  echo "  aws route53domains register-domain \\"
  echo "    --profile ${PROFILE} \\"
  echo "    --domain-name ${DOMAIN} \\"
  echo "    --duration-in-years 1 \\"
  echo "    --auto-renew \\"
  echo "    --admin-contact file://contact.json \\"
  echo "    --registrant-contact file://contact.json \\"
  echo "    --tech-contact file://contact.json \\"
  echo "    --privacy-protect-admin-contact \\"
  echo "    --privacy-protect-registrant-contact \\"
  echo "    --privacy-protect-tech-contact"
  echo ""
  echo "Then update the domain's nameservers at your registrar to:"
  for ns in ${NAMESERVERS}; do
    echo "    ${ns}"
  done
fi

echo ""
echo "Done."
