# DB Health Monitor Auto Report

A PostgreSQL database health monitoring tool that runs automated health checks and generates reports stored locally or in AWS S3.

## What It Does

- Connects to a PostgreSQL database and checks:
  - Connection time (ms)
  - PostgreSQL version
  - Active connection count
- Generates reports in JSON and human-readable text formats
- Runs on a schedule via GitHub Actions (cloud) or cron (local)
- Uploads reports to S3 with timestamped folder structure

## Project Structure

```
├── src/
│   └── healthcheck.py              # Core health check logic
├── scripts/
│   ├── run_healthchecks.sh          # Local execution wrapper
│   ├── setup_cron.sh                # Local cron job installer
│   ├── deploy_aws.sh                # AWS infrastructure setup
│   └── teardown_aws.sh              # AWS infrastructure cleanup
├── .github/workflows/
│   └── healthcheck.yml              # GitHub Actions CI/CD pipeline
├── reports/                         # Local report output
├── .env.example                     # Environment variable template
└── requirements.txt                 # Python dependencies
```

## Setup

### Prerequisites

- Python 3.12+
- PostgreSQL database (local or AWS RDS)
- AWS account (for cloud deployment)
- GitHub repository (for CI/CD)

### 1. Clone and configure

```bash
git clone https://github.com/YOUR-USERNAME/DB-Health-Monitor-Auto-Report.git
cd DB-Health-Monitor-Auto-Report
cp .env.example .env
```

Fill in your `.env` with your database credentials and S3 bucket name.

### 2. Install dependencies

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 3. Run locally

```bash
chmod +x scripts/run_healthchecks.sh
./scripts/run_healthchecks.sh
```

Reports are saved to `reports/YYYY-MM-DD/HHMMSS/`.

## Cloud Deployment (GitHub Actions + AWS S3)

### 1. Deploy AWS resources

```bash
chmod +x scripts/deploy_aws.sh
./scripts/deploy_aws.sh
```

This creates an S3 bucket and IAM user, then prints the GitHub Secrets you need to add.

### 2. Add GitHub Secrets

Go to your repo > Settings > Secrets and variables > Actions, and add:

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | From deploy script output |
| `AWS_SECRET_ACCESS_KEY` | From deploy script output |
| `AWS_REGION` | Your AWS region |
| `S3_BUCKET_NAME` | Your S3 bucket name |
| `POSTGRES_HOST` | Database host |
| `POSTGRES_PORT` | Database port (default: 5432) |
| `POSTGRES_DB` | Database name |
| `POSTGRES_USER` | Database username |
| `POSTGRES_PASSWORD` | Database password |

### 3. Push and run

```bash
git push
```

The workflow runs daily at 6:00 AM UTC. You can also trigger it manually from the Actions tab.

Reports are uploaded to `s3://your-bucket/reports/YYYY-MM-DD/HHMMSS/`.

## Local Cron Setup (Optional)

```bash
chmod +x scripts/setup_cron.sh
./scripts/setup_cron.sh
```

Defaults to daily at 6:00 AM. Pass a custom schedule:

```bash
./scripts/setup_cron.sh "*/30 * * * *"   # every 30 minutes
```

## Teardown

To remove all AWS resources and avoid charges:

```bash
chmod +x scripts/teardown_aws.sh
./scripts/teardown_aws.sh
```

Then delete your RDS instance from the AWS Console if you created one.

## Report Format

### report.json

```json
{
  "meta": {
    "timestamp_utc": "2026-03-08T06:00:00+00:00",
    "hostname": "runner",
    "target": "postgres"
  },
  "status": "OK",
  "connect_ms": 45,
  "version": "PostgreSQL 16.x ...",
  "active_connections": 5,
  "errors": []
}
```

### report.txt

```
Postgres Health Report - 2026-03-08T06:00:00+00:00
Host: runner
Status: OK
Connect time: 45 ms
Version: PostgreSQL 16.x
Active connections: 5
```
