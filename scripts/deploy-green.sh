#!/bin/bash
# =============================================================
# deploy-green.sh
# Launches Green EC2 instances and registers them to Green
# target group. Run AFTER Blue is confirmed healthy.
# =============================================================

set -euo pipefail

# ---------- CONFIG (edit these values) ----------
AMI_ID="ami-0c02fb55956c7d316"          # Amazon Linux 2 AMI (us-east-1)
INSTANCE_TYPE="t2.micro"
KEY_NAME="your-key-pair-name"           # Your existing EC2 key pair
SECURITY_GROUP_ID="sg-xxxxxxxxxxxxxxxxx" # Same SG as Blue
SUBNET_ID="subnet-xxxxxxxxxxxxxxxxx"     # Same subnet as Blue
GREEN_TG_ARN="arn:aws:elasticloadbalancing:us-east-1:ACCOUNT_ID:targetgroup/green-tg/xxxx"
INSTANCE_COUNT=2
APP_VERSION="v2.0"
# ------------------------------------------------

echo "==> Deploying Green environment ($APP_VERSION)..."

INSTANCE_IDS=()

for i in $(seq 1 $INSTANCE_COUNT); do
  echo "  Launching Green instance $i of $INSTANCE_COUNT..."
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --subnet-id "$SUBNET_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=green-instance-$i},{Key=Environment,Value=green},{Key=Version,Value=$APP_VERSION}]" \
    --user-data '#!/bin/bash
      yum update -y
      yum install -y httpd
      systemctl start httpd
      systemctl enable httpd
      echo "<h1>Green Environment - '"$APP_VERSION"'</h1>" > /var/www/html/index.html
      echo "healthy" > /var/www/html/health' \
    --query "Instances[0].InstanceId" \
    --output text)

  echo "  Instance $INSTANCE_ID launched."
  INSTANCE_IDS+=("$INSTANCE_ID")
done

echo "==> Waiting for instances to reach running state..."
aws ec2 wait instance-running --instance-ids "${INSTANCE_IDS[@]}"
echo "  All Green instances are running."

echo "==> Registering instances to Green target group..."
TARGETS=$(printf "Id=%s " "${INSTANCE_IDS[@]}")
aws elbv2 register-targets \
  --target-group-arn "$GREEN_TG_ARN" \
  --targets $TARGETS

echo "==> Green instances registered: ${INSTANCE_IDS[*]}"
echo "==> Next step: run health-check.sh before switching traffic."
