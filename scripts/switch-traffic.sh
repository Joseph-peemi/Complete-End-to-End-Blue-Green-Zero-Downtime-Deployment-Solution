#!/usr/bin/env bash
set -euo pipefail

echo "======================================"
echo " switch-traffic.sh starting"
echo " Deploy slot : ${DEPLOY_SLOT}"
echo " Idle slot   : ${IDLE_SLOT}"
echo " Listener ARN: ${ALB_LISTENER_ARN}"
echo " TG Blue ARN : ${TG_BLUE_ARN}"
echo " TG Green ARN: ${TG_GREEN_ARN}"
echo "======================================"

# ── Validate all required variables are set ───────────────────────────────────
if [[ -z "${DEPLOY_SLOT}"      ]]; then echo "ERROR: DEPLOY_SLOT is not set";      exit 1; fi
if [[ -z "${IDLE_SLOT}"        ]]; then echo "ERROR: IDLE_SLOT is not set";        exit 1; fi
if [[ -z "${ALB_LISTENER_ARN}" ]]; then echo "ERROR: ALB_LISTENER_ARN is not set"; exit 1; fi
if [[ -z "${TG_BLUE_ARN}"      ]]; then echo "ERROR: TG_BLUE_ARN is not set";      exit 1; fi
if [[ -z "${TG_GREEN_ARN}"     ]]; then echo "ERROR: TG_GREEN_ARN is not set";     exit 1; fi

# ── Resolve which ARN gets 100% and which gets 0% ─────────────────────────────
if [[ "${DEPLOY_SLOT}" == "green" ]]; then
  NEW_TG_ARN="${TG_GREEN_ARN}"
  OLD_TG_ARN="${TG_BLUE_ARN}"
else
  NEW_TG_ARN="${TG_BLUE_ARN}"
  OLD_TG_ARN="${TG_GREEN_ARN}"
fi

echo "New live TG : ${NEW_TG_ARN}"
echo "Standby TG  : ${OLD_TG_ARN}"

# ── Switch ALB weights ─────────────────────────────────────────────────────────
echo "--- Switching ALB listener weights..."

aws elbv2 modify-listener \
  --listener-arn "${ALB_LISTENER_ARN}" \
  --default-actions "[
    {
      \"Type\": \"forward\",
      \"ForwardConfig\": {
        \"TargetGroups\": [
          {\"TargetGroupArn\": \"${NEW_TG_ARN}\", \"Weight\": 100},
          {\"TargetGroupArn\": \"${OLD_TG_ARN}\", \"Weight\": 0}
        ],
        \"TargetGroupStickinessConfig\": {
          \"Enabled\": false,
          \"DurationSeconds\": 1
        }
      }
    }
  ]"

echo "======================================"
echo " Traffic switched successfully"
echo " ${DEPLOY_SLOT} is now receiving 100% of traffic"
echo " ${IDLE_SLOT} is now at 0%"
echo "======================================"