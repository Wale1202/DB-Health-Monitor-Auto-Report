#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing .env"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

BUCKET_NAME="${S3_BUCKET_NAME}"
IAM_USER="db-health-monitor-ci"

echo "=== Tearing down AWS resources ==="

echo "Deleting IAM user access keys..."
for KEY_ID in $(aws iam list-access-keys --user-name "$IAM_USER" --query "AccessKeyMetadata[].AccessKeyId" --output text 2>/dev/null); do
  aws iam delete-access-key --user-name "$IAM_USER" --access-key-id "$KEY_ID"
done
echo "Done"

echo "Deleting IAM user policy..."
aws iam delete-user-policy --user-name "$IAM_USER" --policy-name "s3-write" 2>/dev/null || true
echo "Done"

echo "Deleting IAM user..."
aws iam delete-user --user-name "$IAM_USER" 2>/dev/null || true
echo "Done"

echo "Emptying and deleting S3 bucket..."
aws s3 rm "s3://$BUCKET_NAME" --recursive 2>/dev/null || true
aws s3api delete-bucket --bucket "$BUCKET_NAME" 2>/dev/null || true
echo "Done"

echo ""
echo "=== All resources deleted ==="
echo "Remember to also delete your RDS instance from the AWS Console if you created one."
