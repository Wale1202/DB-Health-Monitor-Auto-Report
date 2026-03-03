import argparse
import json
import os
import socket
import time
from datetime import datetime, timezone
import sys
from typing import Optional

import psycopg


## def env(name: str, default: str | None = None) -> str:

def env(name:str, default:Optional[str] = None) -> str:
    val = os.getenv(name, default)
    if val is None:
        raise ValueError(f"Missing env var: {name}") 
    return val

def ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)

def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()

def run_healthcheck() -> dict:
    """Run a healthcheck and return the result as a dictionary"""
    timeout_s = int(env("CONNECT_TIMEOUT_SECONDS", "5"))

    host = env("POSTGRES_HOST")
    port = int(env("POSTGRES_PORT", "5432"))
    db = env("POSTGRES_DB")
    user = env("POSTGRES_USER")
    pwd = env("POSTGRES_PASSWORD")

    result = {
        "meta": {
            "timestamp_utc": utc_now_iso(),
            "hostname": socket.gethostname(),
            "target": "postgres",
        },
        "status": "OK",
        "connect_ms" : None,
        "version": None,
        "active_connections" : None,
        "errors": [],
    }

    conn = None
    t0 = time.time()

    try:
        conn = psycopg.connect(
            host=host,
            port=port,
            dbname=db,
            user=user,
            password=pwd,
            connect_timeout=timeout_s,
        )
        conn.autocommit = True
        result["connect_ms"] = int((time.time() - t0) *1000)

        with conn.cursor() as cur:
            cur.execute("SELECT version();")
            result["version"] = cur.fetchone()[0]

        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM pg_stat_activity;")
            result["active_connections"] = cur.fetchone()[0]

    except Exception as e:
        result["status"] = "CRIT"
        result["errors"].append(str(e))


    finally:
        if conn:
            try:
                conn.close()
            except Exception:
                pass

    return result


def format_report_text(result: dict) -> str:
    """Format the result dict as a human-readable text report"""
    text = (
        f"Postgres Health Report - {result['meta']['timestamp_utc']}\n"
        f"Host: {result['meta']['hostname']}\n"
        f"Status: {result['status']}\n"
        f"Connect time: {result['connect_ms']} ms\n"
        f"Version: {str(result['version']).splitlines()[0] if result['version'] else 'n/a'}\n"
        f"Active connections: {result['active_connections'] if result['active_connections'] is not None else 'n/a'}\n"
    )

    if result["errors"]:
        text += "Errors:\n" + "\n".join([f" - {x}" for x in result ["errors"]]) + "\n"

    return text

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--outdir", required = True)
    args = parser.parse_args()

    ensure_dir(args.outdir)

    result = run_healthcheck()
    json_path = os.path.join(args.outdir, "report.json")
    txt_path = os.path.join(args.outdir, "report.txt")

    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2)

    with open(txt_path, "w", encoding="utf-8") as f:
        f.write(format_report_text(result))

    print(f"Wrote {json_path}")
    print(f"Wrote {txt_path}")

    return 0 if result["status"] == "OK" else 2

if __name__ == "__main__":
    sys.exit(main())
