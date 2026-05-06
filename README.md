cat > README.md << 'EOF'
# Blue-Green Deployment — Nairobi Telco Web Application

Zero-downtime deployment strategy for a three-tier web application running on AWS.

## Architecture

![Architecture](docs/architecture.png)

**Components:**
- **ALB** — routes traffic between Blue and Green target groups using weighted listener rules
- **Blue target group** — current live version (v1.0), initially receives 100% of traffic
- **Green target group** — new version (v2.0), deployed and validated before any traffic is sent
- **Amazon RDS (MySQL)** — shared data tier accessed by both environments
- **CloudWatch** — monitors 5xx error rate, latency, and unhealthy host count
- **EventBridge + Lambda** — auto-triggers rollback when alarms fire

## Deployment steps

### 1. Deploy Green environment
```bash
./scripts/deploy-green.sh
```

### 2. Validate Green health
```bash
./scripts/health-check.sh
```
Do not proceed until this exits with code 0 (all healthy).

### 3. Switch traffic
```bash
# Gradual (recommended): 10% → 50% → 100% over ~2 minutes
./scripts/switch-traffic.sh gradual

# Instant (emergency use only)
./scripts/switch-traffic.sh instant
```

### 4. Rollback (if needed)
```bash
./scripts/rollback.sh
```
Restores 100% traffic to Blue in under 30 seconds.

## Monitoring
- CloudWatch alarm definitions: `monitoring/cloudwatch-alarms.json`
- Key metrics: `HTTPCode_Target_5XX_Count`, `TargetResponseTime`, `UnHealthyHostCount`
- SNS topic `rollback-alert` notifies the on-call engineer and triggers the Lambda

## Rollback plan
See `docs/rollback-plan.md` for full rollback procedure, trigger conditions, and post-rollback steps.

## Folder structure