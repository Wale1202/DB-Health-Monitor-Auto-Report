import json
import os
from datetime import datetime, timezone

import boto3
from healthcheck import run_healthcheck, format_report_text


def lambda_handler(event, context):
    """Aws Lambda entry point."""
    bucket = os.environ["S3_BUCKET_NAME"]

    result = run_healthcheck()

    now = datetime.now(timezone.utc)
    prefix = now.strftime("reports/%Y-%m-%d/%H%M%S")

    s3 = boto3.client("s3")

    s3.put_object(
        Bucket=bucket,
        Key=f"{prefix}/report.json",
        Body=json.dumps(result, indent=2),
        ContentType="application/json",
    )
    s3.put_object(
        Bucket=bucket,
        Key=f"{prefix}/report.txt",
        Body=format_report_text(result),
        ContentType="text/plain",
    )

    print(f"Wrote report to s3://{bucket}/{prefix}")

    return{
        "statusCode": 200 if result["status"] == "OK" else 500,
        "body": json.dumps(result, indent=2),
    }
