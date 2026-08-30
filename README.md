# tinyshare

Upload a file, get a short time-limited URL on your own domain. No servers, no subscriptions — just S3 + CloudFront on your AWS account.

```
share report.pdf 7d
▶ Uploading 2.1M ...

  https://s.yourdomain.com/1754000000/aB3xKm9P
  Expires: 2026-09-05 14:32 UTC

  ↗ Copied to clipboard
```

## How it works

- Files are stored in a **private S3 bucket** (no public access)
- A **CloudFront distribution** serves them through your custom subdomain
- A **CloudFront Function** validates the expiry timestamp on every request — expired links return `410 Gone` server-side, even if someone has the URL cached
- S3 lifecycle rules **delete objects** shortly after their expiry, so you don't pay for stale files
- The URL format is `https://your.domain/{expiry-epoch}/{8-char-token}` — short and unguessable

Everything runs on AWS free tier / pay-as-you-go. No Lambda, no DynamoDB, no running processes.

## Requirements

- [AWS CLI](https://aws.amazon.com/cli/) configured with a profile that has permissions to create S3, CloudFront, ACM, and Route 53 resources
- A domain managed in Route 53
- `python3` (comes with macOS / most Linux distros)
- `bash` 3.2+ (the macOS default is fine)

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/jeanmalha/tinyshare/main/install.sh | bash
```

Or clone and install locally:

```bash
git clone https://github.com/jeanmalha/tinyshare.git
cd tinyshare
./install.sh
```

The script installs to `~/.local/bin/share` — no sudo needed.

## Setup

Run once to deploy the AWS infrastructure (CloudFormation):

```bash
share setup
```

You'll be prompted to select an AWS profile and a Route 53 domain, then choose a subdomain (e.g. `s.yourdomain.com`). CloudFormation deploys everything — S3 bucket, CloudFront distribution, ACM certificate with auto DNS validation, and Route 53 alias record. Takes ~10 minutes for the certificate and distribution to propagate.

## Usage

```bash
# Upload with default 24h expiry
share photo.jpg

# Upload with custom duration
share report.pdf 7d
share archive.zip 1h
share data.csv 30d

# List all shares and their status
share list

# Delete a share immediately
share revoke aB3xKm9P

# View raw access logs (who opened a link)
share logs
share logs aB3xKm9P   # filter by token

# Aggregate stats: hits, unique IPs, browsers, edge locations
share stats
share stats aB3xKm9P  # drill into one token
```

**Durations:** `1h` `6h` `24h` (default) `7d` `30d`

## Access logs & stats

CloudFront delivers access logs to a dedicated S3 bucket within ~1 hour of each request. `share logs` and `share stats` download and parse them locally — no dashboard, no third-party analytics.

```
$ share stats

  Total requests : 14
  Unique IPs     : 3
  Unique tokens  : 2

  TOKEN       HITS  UNIQ IPs  FIRST ACCESS         LAST ACCESS
  ────────────────────────────────────────────────────────────────────────────────
  aB3xKm9P      11         2  2026-08-29 14:03:11  2026-08-30 09:17:44
  kR7pQmNs       3         1  2026-08-30 07:55:02  2026-08-30 07:55:04

  HTTP statuses:
    200  OK                      13
    410  Gone (expired)           1

  Top edge locations (rough geography):
    CDG52              8
    JFK51              4
    LHR61              2

  Client breakdown:
    Chrome / macOS                 9
    Safari / iOS                   3
    curl / Unknown                 2
```

Each row in `share logs` shows: date/time (UTC), client IP, HTTP status, CloudFront edge location (e.g. `CDG` = Paris, `JFK` = New York), user agent, and path.

## Teardown

Remove all AWS resources:

```bash
share teardown
```

This empties the S3 bucket, deletes the CloudFormation stack (distribution, certificate, DNS record, bucket), and removes your local config. The log bucket is retained by default and you'll be asked whether to delete it too.

## Cost

For personal use this is effectively free:

| Resource | Cost |
|---|---|
| S3 storage | ~$0.023/GB/month (files auto-delete after expiry) |
| CloudFront | 1 TB/month free, then ~$0.0085/GB |
| S3 requests | ~$0.0004 per 1000 PUT, $0.00004 per 1000 GET |
| Route 53 | $0.50/month per hosted zone (if you already have one: $0) |

Sharing a 10 MB file 100 times costs less than $0.01.

## Infrastructure

All resources are deployed as a single CloudFormation stack in `us-east-1`:

- `AWS::S3::Bucket` — private file storage with tiered lifecycle rules
- `AWS::S3::BucketPolicy` — allows CloudFront OAC access only
- `AWS::CloudFront::OriginAccessControl` — signs requests from CloudFront to S3
- `AWS::CloudFront::Function` — validates expiry on every viewer request (viewer-request event, before cache)
- `AWS::CertificateManager::Certificate` — TLS cert with automatic DNS validation
- `AWS::CloudFront::Distribution` — global CDN with custom domain
- `AWS::Route53::RecordSet` — A alias pointing to the distribution
- `AWS::S3::Bucket` (log bucket) — CloudFront access logs, 90-day retention

## License

[MIT](LICENSE)
