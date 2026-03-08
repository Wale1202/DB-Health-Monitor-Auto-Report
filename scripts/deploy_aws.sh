#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing .env — copy .env.example to .env and fill it in"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

BUCKET_NAME="${S3_BUCKET_NAME}"
IAM_USER="db-health-monitor-ci"
REGION="$(aws configure get region || echo "us-east-1")"

echo "=== Creating S3 bucket ==="
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "Bucket $BUCKET_NAME already exists"
else
  if [[ "$REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
  echo "Created bucket: $BUCKET_NAME"
fi

echo "=== Creating IAM user for GitHub Actions ==="
aws iam create-user --user-name "$IAM_USER" 2>/dev/null || echo "User $IAM_USER already exists"

S3_POLICY="{
  \"Version\": \"2012-10-17\",
  \"Statement\": [{
    \"Effect\": \"Allow\",
    \"Action\": [\"s3:PutObject\"],
    \"Resource\": \"arn:aws:s3:::${BUCKET_NAME}/*\"
  }]
}"

aws iam put-user-policy --user-name "$IAM_USER" \
  --policy-name "s3-write" \
  --policy-document "$S3_POLICY"

echo "Creating access keys..."
KEYS=$(aws iam create-access-key --user-name "$IAM_USER" --output json)

ACCESS_KEY=$(echo "$KEYS" | python3 -c "import sys,json; print(json.load(sys.stdin)['AccessKey']['AccessKeyId'])")
SECRET_KEY=$(echo "$KEYS" | python3 -c "import sys,json; print(json.load(sys.stdin)['AccessKey']['SecretAccessKey'])")

echo ""
echo "=== Done ==="
echo ""
echo "Add these as GitHub Secrets (Settings > Secrets and variables > Actions):"
echo ""
echo "  AWS_ACCESS_KEY_ID:       $ACCESS_KEY"
echo "  AWS_SECRET_ACCESS_KEY:   $SECRET_KEY"
echo "  AWS_REGION:              $REGION"
echo "  S3_BUCKET_NAME:          $BUCKET_NAME"
echo "  POSTGRES_HOST:           $POSTGRES_HOST"
echo "  POSTGRES_PORT:           ${POSTGRES_PORT:-5432}"
echo "  POSTGRES_DB:             $POSTGRES_DB"
echo "  POSTGRES_USER:           $POSTGRES_USER"
echo "  POSTGRES_PASSWORD:       (use the password from your .env)"
echo ""
echo "IMPORTANT: Save these keys now — the secret key cannot be retrieved again."
