# Rollback Plan

## Trigger conditions
Rollback is initiated when **any** of the following CloudWatch alarms fire:
- `Green-5xx-ErrorRate` — more than 10 HTTP 5xx errors in 60 seconds
- `Green-HighLatency` — average response time above 2 seconds for 3 consecutive minutes
- `Green-UnhealthyHosts` — any Green instance fails the ALB health check

## Manual rollback (fastest — use this first)
```bash
./scripts/rollback.sh
```
This command takes effect in under 30 seconds.

## Automated rollback
EventBridge rule `RollbackOnAlarm` listens for the SNS alarm topic and
triggers the Lambda function in `lambda-rollback/handler.py`, which calls
the same ALB listener modification automatically.

## Post-rollback steps
1. Confirm Blue is serving traffic: check ALB metrics in CloudWatch
2. SSH into Green instances and review `/var/log/httpd/error_log`
3. Fix the identified issue on Green
4. Re-run `scripts/health-check.sh` after the fix
5. Only retry `scripts/switch-traffic.sh` after health check passes
6. Do NOT terminate Blue instances until Green is stable for 24 hours

## Key principle
Blue environment is never decommissioned until the deployment cycle is complete.
It serves as the immediate fallback at all times.
