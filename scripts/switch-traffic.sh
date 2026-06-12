#!/usr/bin/env bash
set -euo pipefail

echo "Switching traffic: 100% → ${DEPLOY_SLOT}, 0% → ${IDLE_SLOT}"

if [[ "$DEPLOY_SLOT" == "green" ]]; then
  NEW_TG_ARN=$TG_GREEN_ARN
  OLD_TG_ARN=$TG_BLUE_ARN
else
  NEW_TG_ARN=$TG_BLUE_ARN
  OLD_TG_ARN=$TG_GREEN_ARN
fi

aws elbv2 modify-listener \
  --listener-arn "$ALB_LISTENER_ARN" \
  --default-actions "Type=forward,ForwardConfig={
    TargetGroups=[
      {TargetGroupArn=${NEW_TG_ARN},Weight=100},
      {TargetGroupArn=${OLD_TG_ARN},Weight=0}
    ]
  }"

echo "Traffic switched — ${DEPLOY_SLOT} is now live"