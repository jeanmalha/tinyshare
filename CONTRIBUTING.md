# Contributing to tinyshare

## Design principles

Every feature must fit within the zero-server, zero-subscription model. Before proposing or implementing anything, check it against these rules.

### 1. No always-on infrastructure

No EC2, no containers, no persistent processes, no servers. Everything must be event-driven and pay-per-request. A feature that requires something running continuously is out of scope.

### 2. Two tiers of request handling — pick the lowest that fits

| Tier | Tool | When to use |
|---|---|---|
| **Stateless** | CloudFront Function | Pure validation: URL format, expiry timestamp, header checks. No I/O, no side effects. |
| **Stateful** | Lambda@Edge | When a request must read or mutate state: marking a link used, checking an access list, deleting an object after serving it. |

Do not jump to Lambda@Edge if a CloudFront Function can handle the logic. Do not introduce API Gateway or a standalone Lambda URL unless Lambda@Edge genuinely can't do the job (e.g. VPC access, runtimes beyond Node.js/Python, response body generation beyond 1 MB).

### 3. S3 is the state store

Behavioral state lives in S3 — as object tags, companion marker objects (`<expiry>/<token>/.used`), or small JSON blobs. Do not introduce DynamoDB, ElastiCache, Parameter Store, or any other database. S3 is already in the stack, it is cheap, and conditional writes (`If-None-Match: *`) provide enough atomicity for personal-scale usage.

### 4. No new always-on AWS services

Adding a service means adding cost, IAM surface, CloudFormation resources, and maintenance burden. The acceptable additions for stateful features are:

- A Lambda@Edge function (Node.js, attached to the existing distribution)
- An IAM role scoped to that function
- Companion S3 objects written at upload time

Anything beyond that needs a compelling justification in the issue before implementation starts.

### 5. The CLI is the only interface

`share` is the single entrypoint. There is no web dashboard, no admin UI, no webhook endpoint exposed to the internet. Features that require owner interaction (`share watch`, approval flows) poll or process data locally in the terminal.

### 6. Encode behavior in S3 metadata at upload time

Single-use, gated, or any other per-link behavioral flag must be set at upload time as an S3 tag or object attribute. Lambda@Edge reads the tag on each request to decide what to do. This keeps the CloudFront Function simple and avoids any central config store.

---

## Checklist for new features

- [ ] No always-on process or server required
- [ ] CloudFront Function used if logic is stateless; Lambda@Edge if state I/O is needed
- [ ] State stored in S3 (tags, companion objects) — no new database service
- [ ] `share list` / `share logs` / `share stats` updated if the feature adds observable state
- [ ] CloudFormation template updated (new Lambda, IAM role, CF association if needed)
- [ ] `share --help` / README updated

## Submitting changes

1. Fork the repo and work on a feature branch
2. Test against a real AWS account (`share setup` on a throwaway domain works fine)
3. Open a PR — reference the issue it closes

## Reporting issues

Use GitHub Issues. Include the output of `share` with `TINYSHARE_DEBUG=1` set if it's a runtime failure.
