#!/bin/bash
# =============================================================
# rollback.sh
# EMERGENCY: Immediately switches 100% traffic back to Blue.
# Run this the moment CloudWatch alarms fire on Green.
# =============================================================

set -euo pipefail

ALB_LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:ACCOUNT_ID:listener/app/my-alb/xxxx/xxxx"
BLUE_TG_ARN="arn:aws:elasticloadbalancing:us-east-1:ACCOUNT_ID:targetgroup/blue-tg/xxxx"
GREEN_TG_ARN="arn:aws:elasticloadbalancing:us-east-1:ACCOUNT_ID:targetgroup/green-tg/xxxx"

echo "==> ROLLBACK INITIATED at $(date)"
echo "==> Switching 100% traffic back to Blue immediately..."

aws elbv2 modify-listener \
  --listener-arn "$ALB_LISTENER_ARN" \
  --default-actions Type=forward,ForwardConfig="{
    TargetGroups=[
      {TargetGroupArn=$BLUE_TG_ARN,Weight=100},
      {TargetGroupArn=$GREEN_TG_ARN,Weight=0}
    ]
  }"

echo "==> ROLLBACK COMPLETE. Blue is now serving 100% of traffic."
echo "==> Action items:"
echo "    1. Check Green EC2 instance logs: /var/log/httpd/error_log"
echo "    2. Review CloudWatch alarm that triggered the rollback"
echo "    3. Fix the issue in Green before attempting re-deployment"
echo "    4. Do NOT decommission Blue until Green passes full validation"
