#!/usr/bin/env bash
set -euo pipefail

echo "======================================"
echo " deploy-green.sh starting"
echo " Cluster  : ${ECS_CLUSTER}"
echo " Image URI: ${IMAGE_URI}"
echo " Listener : ${ALB_LISTENER_ARN}"
echo "======================================"

# ── Step 1: Detect which slot is idle ─────────────────────────────────────────
echo "--- Detecting active slot..."

LISTENER_JSON=$(aws elbv2 describe-listeners \
  --listener-arns "${ALB_LISTENER_ARN}" \
  --output json)

echo "Listener config fetched"

# Extract the target group with weight 100
ACTIVE_TG=$(echo "${LISTENER_JSON}" \
  | jq -r '
      .Listeners[0].DefaultActions[0].ForwardConfig.TargetGroups[]
      | select(.Weight == 100)
      | .TargetGroupArn
    ')

echo "Active target group ARN: ${ACTIVE_TG}"

if [[ -z "${ACTIVE_TG}" ]]; then
  echo "ERROR: Could not find active target group with Weight=100"
  echo "Full listener JSON:"
  echo "${LISTENER_JSON}"
  exit 1
fi

# Determine slots
if [[ "${ACTIVE_TG}" == *"blue"* ]]; then
  DEPLOY_SLOT="green"
  IDLE_SLOT="blue"
else
  DEPLOY_SLOT="blue"
  IDLE_SLOT="green"
fi

TASK_FAMILY="aspnetapp-${DEPLOY_SLOT}"

echo "Active slot : ${IDLE_SLOT}"
echo "Deploy slot : ${DEPLOY_SLOT}"
echo "Task family : ${TASK_FAMILY}"

# ── Step 2: Fetch current task definition ─────────────────────────────────────
echo "--- Fetching task definition: ${TASK_FAMILY}..."

TASK_DEF_JSON=$(aws ecs describe-task-definition \
  --task-definition "${TASK_FAMILY}" \
  --query 'taskDefinition' \
  --output json)

if [[ -z "${TASK_DEF_JSON}" ]]; then
  echo "ERROR: Could not fetch task definition for ${TASK_FAMILY}"
  exit 1
fi

echo "Task definition fetched successfully"

# ── Step 3: Build new task definition JSON ────────────────────────────────────
echo "--- Building new task definition with image: ${IMAGE_URI}..."

# Write to a temp file to avoid shell quoting issues entirely
TASK_DEF_FILE=$(mktemp /tmp/task-def-XXXXXX.json)

echo "${TASK_DEF_JSON}" | jq \
  --arg IMAGE "${IMAGE_URI}" \
  '
    .containerDefinitions[0].image = $IMAGE
    | del(
        .taskDefinitionArn,
        .revision,
        .status,
        .requiresAttributes,
        .compatibilities,
        .registeredAt,
        .registeredBy
      )
  ' > "${TASK_DEF_FILE}"

echo "New task definition written to: ${TASK_DEF_FILE}"
echo "--- Validating JSON..."
cat "${TASK_DEF_FILE}" | jq . > /dev/null && echo "JSON is valid"

# ── Step 4: Register new task definition ──────────────────────────────────────
echo "--- Registering new task definition..."

NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
  --cli-input-json "file://${TASK_DEF_FILE}" \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

echo "Registered: ${NEW_TASK_DEF_ARN}"

# Cleanup temp file
rm -f "${TASK_DEF_FILE}"

# ── Step 5: Update ECS service ────────────────────────────────────────────────
echo "--- Updating svc-${DEPLOY_SLOT}..."

aws ecs update-service \
  --cluster "${ECS_CLUSTER}" \
  --service "svc-${DEPLOY_SLOT}" \
  --task-definition "${NEW_TASK_DEF_ARN}" \
  --force-new-deployment \
  --output json \
  --no-cli-pager > /dev/null

echo "Deployment started"

# ── Step 6: Wait for stable ───────────────────────────────────────────────────
echo "--- Waiting for svc-${DEPLOY_SLOT} to stabilise (up to 10 min)..."

aws ecs wait services-stable \
  --cluster "${ECS_CLUSTER}" \
  --services "svc-${DEPLOY_SLOT}"

echo "======================================"
echo " svc-${DEPLOY_SLOT} is stable"
echo " Task definition: ${NEW_TASK_DEF_ARN}"
echo "======================================"

# Export for downstream steps
echo "DEPLOY_SLOT=${DEPLOY_SLOT}" >> "${GITHUB_ENV}"
echo "IDLE_SLOT=${IDLE_SLOT}"     >> "${GITHUB_ENV}"