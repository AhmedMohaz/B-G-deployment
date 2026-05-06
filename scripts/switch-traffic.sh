#!/bin/bash
# =============================================================
# switch-traffic.sh
# Gradually shifts ALB traffic from Blue to Green.
# Supports weighted (gradual) or instant switching.
# Usage: ./switch-traffic.sh [gradual|instant]
# =============================================================

set -euo pipefail

ALB_LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:ACCOUNT_ID:listener/app/my-alb/xxxx/xxxx"
BLUE_TG_ARN="arn:aws:elasticloadbalancing:us-east-1:ACCOUNT_ID:targetgroup/blue-tg/xxxx"
GREEN_TG_ARN="arn:aws:elasticloadbalancing:us-east-1:ACCOUNT_ID:targetgroup/green-tg/xxxx"
MODE="${1:-gradual}"

switch_weights() {
  local BLUE_W=$1
  local GREEN_W=$2
  echo "  Setting Blue=$BLUE_W% / Green=$GREEN_W%..."
  aws elbv2 modify-listener \
    --listener-arn "$ALB_LISTENER_ARN" \
    --default-actions Type=forward,ForwardConfig="{
      TargetGroups=[
        {TargetGroupArn=$BLUE_TG_ARN,Weight=$BLUE_W},
        {TargetGroupArn=$GREEN_TG_ARN,Weight=$GREEN_W}
      ]
    }"
}

if [ "$MODE" == "gradual" ]; then
  echo "==> Gradual traffic shift: Blue→Green over 3 steps"
  switch_weights 90 10
  echo "  Monitoring for 60s at 10% Green..."
  sleep 60

  switch_weights 50 50
  echo "  Monitoring for 60s at 50% Green..."
  sleep 60

  switch_weights 0 100
  echo "==> 100% traffic now on Green."

elif [ "$MODE" == "instant" ]; then
  echo "==> Instant switch: 100% traffic to Green"
  switch_weights 0 100
  echo "==> Done."
else
  echo "Usage: $0 [gradual|instant]"
  exit 1
fi

echo "==> Monitor CloudWatch for 5xx errors and latency spikes."
echo "==> Run rollback.sh immediately if alarms trigger."
