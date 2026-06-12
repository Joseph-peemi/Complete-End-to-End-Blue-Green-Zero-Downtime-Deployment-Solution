#!/usr/bin/env bash
set -euo pipefail

ALARM_NAMES=(
  "aspnetapp-5xx-rate"
  "aspnetapp-latency-p99"
  "aspnetapp-unhealthy-hosts"
)

echo "Monitoring CloudWatch alarms for ${WATCH_SECS}s..."
echo "Will rollback to ${IDLE_SLOT} if any alarm fires"

elapsed=0

while [[ $elapsed -lt $WATCH_SECS ]]; do
  ALARM_STATE=$(aws cloudwatch describe-alarms \
    --alarm-names "${ALARM_NAMES[@]}" \
    --state-value ALARM \
    --query 'MetricAlarms[*].AlarmName' \
    --output text)

  if [[ -n "$ALARM_STATE" ]]; then
    echo "ALARM TRIGGERED: $ALARM_STATE"
    echo "Rolling back to ${IDLE_SLOT}..."

    # Restore previous traffic weights
    if [[ "$IDLE_SLOT" == "blue" ]]; then
      RESTORE_ARN=$TG_BLUE_ARN
      STANDBY_ARN=$TG_GREEN_ARN
    else
      RESTORE_ARN=$TG_GREEN_ARN
      STANDBY_ARN=$TG_BLUE_ARN
    fi

    aws elbv2 modify-listener \
      --listener-arn "$ALB_LISTENER_ARN" \
      --default-actions "Type=forward,ForwardConfig={
        TargetGroups=[
          {TargetGroupArn=${RESTORE_ARN},Weight=100},
          {TargetGroupArn=${STANDBY_ARN},Weight=0}
        ]
      }"

    echo "Rollback complete — ${IDLE_SLOT} restored to 100% in $(date +%T)"
    exit 1    # fail the job → GitHub marks deployment as failed
  fi

  echo "[$(date +%T)] All alarms OK (${elapsed}s / ${WATCH_SECS}s)"
  sleep $POLL_SECS
  elapsed=$((elapsed + POLL_SECS))
done

echo "Monitoring complete — deployment is stable"
exit 0