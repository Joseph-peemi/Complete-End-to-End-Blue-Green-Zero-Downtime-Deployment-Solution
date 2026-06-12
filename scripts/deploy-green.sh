#!/usr/bin/env bash
set -euo pipefail

echo "=== deploy-green.sh starting ==="
echo "Image URI : $IMAGE_URI"
echo "ECS Cluster: $ECS_CLUSTER"
echo "ALB Listener: $ALB_LISTENER_ARN"

# ── Step 1: Detect which slot is idle ─────────────────────────────────────────
ACTIVE_TG=$(aws elbv2 describe-listeners \
  --listener-arns "$ALB_LISTENER_ARN" \
  --query 'Listeners[0].DefaultActions[0].ForwardConfig.TargetGroups' \
  --output json \
| jq -r '.[] | select(.Weight == 100) | .TargetGroupArn')

if [[ -z "$ACTIVE_TG" ]]; then
  echo "ERROR: Could not determine active target group"
  exit 1
fi

if [[ "$ACTIVE_TG" == *"blue"* ]]; then
  DEPLOY_SLOT="green"
  IDLE_SLOT="blue"
else
  DEPLOY_SLOT="blue"
  IDLE_SLOT="green"
fi

echo "Active slot : $IDLE_SLOT (receiving 100% traffic)"
echo "Deploy slot : $DEPLOY_SLOT (currently idle)"

# ── Step 2: Fetch current task definition and swap image ──────────────────────
CURRENT_TASK_DEF=$(aws ecs describe-task-definition \
  --task-definition "${var.project_name}-${DEPLOY_SLOT}" \
  --query 'taskDefinition' \
  --output json)

  NEW_TASK_JSON=$(echo "$CURRENT_TASK_DEF" \
| jq --arg IMAGE "$IMAGE_URI" '
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
')

# ── Step 3: Register new task definition revision ─────────────────────────────
NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
  --cli-input-json "$NEW_TASK_JSON" \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

echo "Registered new task definition: $NEW_TASK_DEF_ARN"

# ── Step 4: Update the idle service ──────────────────────────────────────────
aws ecs update-service \
  --cluster "$ECS_CLUSTER" \
  --service "svc-${DEPLOY_SLOT}" \
  --task-definition "$NEW_TASK_DEF_ARN" \
  --force-new-deployment \
  --output json \
  --no-cli-pager > /dev/null

echo "Deployment started on svc-${DEPLOY_SLOT}"

# ── Step 5: Wait for the service to stabilise ─────────────────────────────────
echo "Waiting for svc-${DEPLOY_SLOT} to reach stable state..."

aws ecs wait services-stable \
  --cluster "$ECS_CLUSTER" \
  --services "svc-${DEPLOY_SLOT}"

echo "svc-${DEPLOY_SLOT} is stable with new task definition"
echo "=== deploy-green.sh complete ==="

