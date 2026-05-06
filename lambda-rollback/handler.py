"""
handler.py
Lambda function triggered by EventBridge when CloudWatch
5xx alarm fires. Automatically rolls back traffic to Blue.
"""

import boto3
import os
import json
from datetime import datetime

elbv2 = boto3.client("elbv2")

LISTENER_ARN  = os.environ["LISTENER_ARN"]
BLUE_TG_ARN   = os.environ["BLUE_TG_ARN"]
GREEN_TG_ARN  = os.environ["GREEN_TG_ARN"]

def lambda_handler(event, context):
    print(f"[{datetime.utcnow()}] Auto-rollback triggered by alarm.")
    print(f"Event: {json.dumps(event)}")

    try:
        elbv2.modify_listener(
            ListenerArn=LISTENER_ARN,
            DefaultActions=[{
                "Type": "forward",
                "ForwardConfig": {
                    "TargetGroups": [
                        {"TargetGroupArn": BLUE_TG_ARN,  "Weight": 100},
                        {"TargetGroupArn": GREEN_TG_ARN, "Weight": 0},
                    ]
                }
            }]
        )
        msg = "ROLLBACK SUCCESS: 100% traffic restored to Blue."
        print(msg)
        return {"statusCode": 200, "body": msg}

    except Exception as e:
        print(f"ROLLBACK FAILED: {e}")
        raise
