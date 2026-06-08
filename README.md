[![Terraform](https://img.shields.io/badge/Terraform-1.10+-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![FinOps](https://img.shields.io/badge/FinOps-Cost%20Optimization-00ADD8)](https://www.finops.org/)

---

# 🇬🇧 FinOps Platform — AWS Cost Monitoring & Optimization (V2)

Serverless platform that automatically detects AWS cost anomalies, scans for unused resources, and sends email alerts — fully automated with CI/CD via GitHub Actions OIDC.

> **V2 upgrade:** Modular Terraform structure + S3 remote state + CI/CD pipeline with OIDC authentication. No static AWS credentials anywhere.

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│                  EventBridge                     │
│   rate(6h) ──────────┐   cron(9am) ─────────────┤
└──────────────────────┼──────────────────────────┘
                       │
            ┌──────────┴──────────┐
            ▼                     ▼
   ┌─────────────────┐   ┌─────────────────┐
   │   Lambda #1     │   │   Lambda #2     │
   │ Cost Anomaly    │   │ Unused Resources│
   │   Detector      │   │    Scanner      │
   └────────┬────────┘   └────────┬────────┘
            │                     │
            ▼                     ▼
   ┌─────────────┐       ┌─────────────────┐
   │Cost Explorer│       │  EC2 / ELB /    │
   │     API     │       │  RDS APIs       │
   └──────┬──────┘       └────────┬────────┘
          │                       │
          └───────────┬───────────┘
                      ▼
             ┌─────────────────┐
             │    DynamoDB     │
             │  cost-history   │
             └────────┬────────┘
                      │
                      ▼
             ┌─────────────────┐
             │   SNS Topic     │──► 📧 Email Alerts
             └─────────────────┘

             ┌─────────────────┐
             │   CloudWatch    │
             │ Logs + Dashboard│
             │   + Alarms      │
             └─────────────────┘

CI/CD Pipeline:
┌──────────────────────────────────────────────┐
│  GitHub Actions (OIDC)                        │
│  PR → terraform plan                          │
│  push main → terraform plan + apply           │
└──────────────────────────────────────────────┘
```

---

## Infrastructure (Terraform Modules)

| Module | Resources |
|--------|-----------|
| `modules/notifications` | SNS Topic + Email Subscription |
| `modules/storage` | DynamoDB Table (TTL + PITR) |
| `modules/iam` | Lambda Role + GitHub Actions OIDC Role + Policies |
| `modules/monitoring` | CloudWatch Log Groups + Dashboard + Alarm |
| `modules/lambda` | 2× Lambda Functions + 2× EventBridge Rules |

**Remote state:** S3 bucket with file locking (`use_lockfile = true`)  
**Bootstrap:** Separate Terraform config in `bootstrap/` — run once to provision the state bucket and lock table.

---

## Lambda Functions

### Lambda #1 — Cost Anomaly Detector
- **Trigger:** Every 6 hours (`rate(6 hours)`)
- **Logic:** Queries Cost Explorer for today's costs vs. 7-day historical average per service. Fires alert if any service exceeds 30% above average.
- **Output:** Saves data to DynamoDB + SNS alert if anomalies found.

**Sample alert:**
```
🚨 COST ANOMALY ALERT

2 services with abnormal costs detected:

- Amazon ELB: $0.05 (↑150% vs avg $0.02)
- Amazon RDS: $0.02 (↑100% vs avg $0.01)

Threshold: 30% | Comparison period: last 7 days
```

### Lambda #2 — Unused Resources Scanner
- **Trigger:** Daily at 9:00 AM UTC (`cron(0 9 * * ? *)`)
- **Detects:** Unattached EBS volumes, unassigned Elastic IPs, idle Load Balancers, manual RDS snapshots older than 30 days.

**Sample alert:**
```
🗑️ UNUSED RESOURCES DETECTED

📦 Unattached EBS Volumes (2):
  • vol-013f3c944b957b44e — 1 GB gp2 — $0.10/mo
  • vol-0cdd0b0d59b205d9f — 1 GB gp2 — $0.10/mo

💰 Potential savings: $0.20/mo
```

---

## Project Structure

```
finops/
├── provider.tf                        # S3 backend + AWS provider
├── variables.tf                       # Root variables
├── outputs.tf                         # Root outputs
├── main.tf                            # Module calls
│
├── modules/
│   ├── notifications/                 # SNS
│   ├── storage/                       # DynamoDB
│   ├── iam/                           # IAM roles + OIDC
│   ├── monitoring/                    # CloudWatch
│   └── lambda/                        # Lambda + EventBridge
│
├── lambda_src/
│   ├── cost_anomaly/
│   │   └── lambda_cost_anomaly.py
│   └── unused_resources/
│       └── lambda_unused_resources.py
│
├── bootstrap/                         # One-time state backend setup
│   └── main.tf
│
├── docs/
│   └── screenshots/
│
└── .github/
    └── workflows/
        ├── terraform-validate.yml     # fmt + validate on PRs
        └── deploy.yml                 # plan + apply with OIDC
```

---

## CI/CD Pipeline

```
Pull Request
    │
    └── terraform-validate.yml
            ├── fmt check
            ├── validate
            └── plan (read-only)

Push to main
    │
    └── deploy.yml
            ├── Job 1: terraform-plan
            │       ├── OIDC → assume IAM role (no static credentials)
            │       ├── Package Lambda ZIPs
            │       ├── terraform init (S3 backend)
            │       ├── terraform fmt -check
            │       ├── terraform validate
            │       └── terraform plan → upload artifact
            │
            └── Job 2: terraform-apply (needs: plan)
                    ├── OIDC → assume IAM role
                    ├── Package Lambda ZIPs
                    ├── terraform init (S3 backend)
                    ├── Download plan artifact
                    └── terraform apply
```

**Authentication:** GitHub Actions assumes an IAM role via OIDC — no AWS access keys stored as secrets.

---

## Screenshots

### CI/CD Pipeline
![GitHub Actions](docs/screenshots/github-actions.png)

### Lambda Functions
![Lambda Functions](docs/screenshots/lambda-functions.png)

### CloudWatch Dashboard
![Dashboard](docs/screenshots/cloudwatch-dashboard.png)

### EventBridge Rules
![EventBridge](docs/screenshots/eventbridge-rules.png)

### S3 Remote State
![S3 State](docs/screenshots/s3-remote-state.png)

### IAM OIDC Role
![IAM Role](docs/screenshots/iam-oidc-role.png)

---

## Deployment

### Prerequisites
```bash
terraform version   # >= 1.10
aws sts get-caller-identity
python3 --version   # >= 3.11
```

### 1. Bootstrap (one time only)
```bash
cd bootstrap/
terraform init
terraform apply
```

### 2. Configure secrets
In GitHub → Settings → Secrets → Actions:
- `AWS_ROLE_ARN` — ARN of the GitHub Actions OIDC role (output from step 3)
- `ALERT_EMAIL` — email address for SNS alerts

### 3. Deploy
```bash
cd ..
terraform init
terraform apply
```

Confirm the SNS subscription email in your inbox.

### 4. Test manually
```bash
# Test Lambda #1
aws lambda invoke \
  --function-name finops-platform-cost-anomaly-detector \
  --region us-east-1 \
  response1.json && cat response1.json

# Test Lambda #2
aws lambda invoke \
  --function-name finops-platform-unused-resources-scanner \
  --region us-east-1 \
  response2.json && cat response2.json
```

### 5. Cleanup
```bash
terraform destroy
```

---

## Estimated Cost

| Service | Monthly Usage | Cost |
|---------|--------------|------|
| Lambda #1 | 120 invocations × 1s | $0.00 (free tier) |
| Lambda #2 | 30 invocations × 2s | $0.00 (free tier) |
| SNS | ~50 emails | $0.00 (free tier) |
| DynamoDB | on-demand, low volume | ~$1.00 |
| CloudWatch Logs | 7-day retention | ~$0.50 |
| CloudWatch Dashboard | 1 dashboard | ~$3.00 |
| Cost Explorer API | ~150 requests | ~$1.50 |
| **TOTAL** | | **~$6/mo** |

---

## Security

- IAM least-privilege (separate roles for Lambda and GitHub Actions)
- No static AWS credentials — OIDC only
- S3 state bucket: versioning + encryption + public access blocked
- DynamoDB: point-in-time recovery enabled
- CloudWatch logs for full audit trail
- DynamoDB TTL: auto-delete records after 60 days

---

## V1 → V2: What Changed and Why

| | V1 | V2 |
|---|---|---|
| Terraform structure | Flat (all `.tf` in root) | 5 modules with clear ownership |
| State management | Local `terraform.tfstate` | S3 remote state + file locking |
| Lambda packaging | Manual `package_lambda.sh` | `archive_file` data source — automatic |
| CI/CD | `validate` only (fmt + validate) | Full `plan` + `apply` pipeline |
| AWS authentication | Static credentials in `.env` | OIDC — zero stored credentials |
| IAM | Single shared role | Separate role per workload |
| Outputs | Scattered or missing | Centralized in root `outputs.tf` |

---

## Challenges Solved

| Problem | Root Cause | Solution |
|---------|-----------|----------|
| `use_lockfile` unsupported | Workflow used Terraform 1.7.0 | Upgraded to 1.10.0 |
| "No changes" with empty state | S3 backend was empty, no prior apply | Ran full `terraform apply` |
| `AccessDenied: ListOpenIDConnectProviders` | GitHub Actions role missing IAM OIDC read permissions | Added `iam:ListOpenIDConnectProviders` + `iam:GetOpenIDConnectProvider` to role policy |
| Lambda ZIPs missing in CI | `*.zip` in `.gitignore`, runner had no ZIPs | Added `Package Lambda functions` step to both pipeline jobs |
| `terraform fmt` check failing | Indentation issues in `modules/lambda/main.tf` | Ran `terraform fmt -recursive` locally |
| `git push` rejected | Remote had commits not in local | `git pull --rebase origin main` |

---

## Skills Demonstrated

**Infrastructure as Code**
- Modular Terraform with inter-module dependencies
- Remote state with S3 backend and file locking
- Bootstrap pattern for state infrastructure

**Serverless**
- Lambda with EventBridge scheduling (rate + cron expressions)
- Python + boto3 (Cost Explorer, EC2, ELB, RDS APIs)
- Automatic Lambda packaging via `archive_file`

**CI/CD & Security**
- GitHub Actions OIDC — no static credentials
- Two-job pipeline: plan (all branches) → apply (main only)
- Artifact passing between jobs (`tfplan`)

**Observability**
- CloudWatch Dashboard with Lambda + DynamoDB metrics
- CloudWatch Alarm → SNS on Lambda errors
- 7-day log retention

**FinOps**
- Cost anomaly detection with historical baseline
- Unused resource identification across EC2, ELB, RDS
- Estimated savings reporting

---

## Author

**Santiago Albi** — Cloud Engineer  
[GitHub](https://github.com/SantiagoAlbi) · [LinkedIn](https://linkedin.com/in/santiago-albi)

---
---

# 🇪🇸 FinOps Platform — Monitoreo y Optimización de Costos AWS (V2)

Plataforma serverless que detecta automáticamente anomalías de costos en AWS, escanea recursos sin usar y envía alertas por email — completamente automatizada con CI/CD via GitHub Actions OIDC.

> **Mejoras V2:** Estructura Terraform modular + estado remoto en S3 + pipeline CI/CD con autenticación OIDC. Sin credenciales AWS estáticas en ningún lado.

---

## Arquitectura

```
┌─────────────────────────────────────────────────┐
│                  EventBridge                     │
│   rate(6h) ──────────┐   cron(9am) ─────────────┤
└──────────────────────┼──────────────────────────┘
                       │
            ┌──────────┴──────────┐
            ▼                     ▼
   ┌─────────────────┐   ┌─────────────────┐
   │   Lambda #1     │   │   Lambda #2     │
   │ Detector de     │   │ Scanner de      │
   │ Anomalías       │   │ Recursos Unused │
   └────────┬────────┘   └────────┬────────┘
            │                     │
            ▼                     ▼
   ┌─────────────┐       ┌─────────────────┐
   │Cost Explorer│       │  EC2 / ELB /    │
   │     API     │       │  RDS APIs       │
   └──────┬──────┘       └────────┬────────┘
          │                       │
          └───────────┬───────────┘
                      ▼
             ┌─────────────────┐
             │    DynamoDB     │
             │  cost-history   │
             └────────┬────────┘
                      │
                      ▼
             ┌─────────────────┐
             │   SNS Topic     │──► 📧 Alertas por Email
             └─────────────────┘

             ┌─────────────────┐
             │   CloudWatch    │
             │ Logs + Dashboard│
             │   + Alarmas     │
             └─────────────────┘

Pipeline CI/CD:
┌──────────────────────────────────────────────┐
│  GitHub Actions (OIDC)                        │
│  PR → terraform plan                          │
│  push main → terraform plan + apply           │
└──────────────────────────────────────────────┘
```

---

## Infraestructura (Módulos Terraform)

| Módulo | Recursos |
|--------|----------|
| `modules/notifications` | SNS Topic + Suscripción Email |
| `modules/storage` | Tabla DynamoDB (TTL + PITR) |
| `modules/iam` | Role Lambda + Role GitHub Actions OIDC + Policies |
| `modules/monitoring` | CloudWatch Log Groups + Dashboard + Alarma |
| `modules/lambda` | 2× Lambda Functions + 2× EventBridge Rules |

**Estado remoto:** Bucket S3 con file locking (`use_lockfile = true`)  
**Bootstrap:** Configuración Terraform separada en `bootstrap/` — se ejecuta una sola vez para crear el bucket de estado y la tabla de locking.

---

## Funciones Lambda

### Lambda #1 — Detector de Anomalías de Costos
- **Trigger:** Cada 6 horas (`rate(6 hours)`)
- **Lógica:** Consulta Cost Explorer comparando costos de hoy vs. promedio histórico de 7 días por servicio. Dispara alerta si algún servicio supera el 30% del promedio.
- **Output:** Guarda datos en DynamoDB + alerta SNS si hay anomalías.

**Ejemplo de alerta:**
```
🚨 ALERTA DE ANOMALÍA DE COSTOS

Se detectaron 2 servicios con costos anormales:

- Amazon ELB: $0.05 (↑150% vs promedio $0.02)
- Amazon RDS: $0.02 (↑100% vs promedio $0.01)

Umbral: 30% | Período de comparación: últimos 7 días
```

### Lambda #2 — Scanner de Recursos Sin Usar
- **Trigger:** Diario a las 9:00 AM UTC (`cron(0 9 * * ? *)`)
- **Detecta:** EBS volumes sin attachar, Elastic IPs sin asignar, Load Balancers sin targets, snapshots RDS manuales mayores a 30 días.

**Ejemplo de alerta:**
```
🗑️ RECURSOS SIN USAR DETECTADOS

📦 EBS Volumes sin attachar (2):
  • vol-013f3c944b957b44e — 1 GB gp2 — $0.10/mes
  • vol-0cdd0b0d59b205d9f — 1 GB gp2 — $0.10/mes

💰 Ahorro potencial: $0.20/mes
```

---

## Estructura del Proyecto

```
finops/
├── provider.tf                        # Backend S3 + provider AWS
├── variables.tf                       # Variables raíz
├── outputs.tf                         # Outputs raíz
├── main.tf                            # Llamadas a módulos
│
├── modules/
│   ├── notifications/                 # SNS
│   ├── storage/                       # DynamoDB
│   ├── iam/                           # Roles IAM + OIDC
│   ├── monitoring/                    # CloudWatch
│   └── lambda/                        # Lambda + EventBridge
│
├── lambda_src/
│   ├── cost_anomaly/
│   │   └── lambda_cost_anomaly.py
│   └── unused_resources/
│       └── lambda_unused_resources.py
│
├── bootstrap/                         # Setup único del estado remoto
│   └── main.tf
│
├── docs/
│   └── screenshots/
│
└── .github/
    └── workflows/
        ├── terraform-validate.yml     # fmt + validate en PRs
        └── deploy.yml                 # plan + apply con OIDC
```

---

## Pipeline CI/CD

```
Pull Request
    │
    └── terraform-validate.yml
            ├── fmt check
            ├── validate
            └── plan (solo lectura)

Push a main
    │
    └── deploy.yml
            ├── Job 1: terraform-plan
            │       ├── OIDC → asumir rol IAM (sin credenciales estáticas)
            │       ├── Empaquetar ZIPs de Lambda
            │       ├── terraform init (backend S3)
            │       ├── terraform fmt -check
            │       ├── terraform validate
            │       └── terraform plan → subir artefacto
            │
            └── Job 2: terraform-apply (needs: plan)
                    ├── OIDC → asumir rol IAM
                    ├── Empaquetar ZIPs de Lambda
                    ├── terraform init (backend S3)
                    ├── Descargar artefacto del plan
                    └── terraform apply
```

**Autenticación:** GitHub Actions asume un rol IAM via OIDC — sin access keys de AWS almacenadas como secrets.

---

## Screenshots

### Pipeline CI/CD
![GitHub Actions](docs/screenshots/github-actions.png)

### Funciones Lambda
![Lambda Functions](docs/screenshots/lambda-functions.png)

### CloudWatch Dashboard
![Dashboard](docs/screenshots/cloudwatch-dashboard.png)

### EventBridge Rules
![EventBridge](docs/screenshots/eventbridge-rules.png)

### Estado Remoto S3
![S3 State](docs/screenshots/s3-remote-state.png)

### Rol IAM OIDC
![IAM Role](docs/screenshots/iam-oidc-role.png)

---

## Deployment

### Prerequisitos
```bash
terraform version   # >= 1.10
aws sts get-caller-identity
python3 --version   # >= 3.11
```

### 1. Bootstrap (solo una vez)
```bash
cd bootstrap/
terraform init
terraform apply
```

### 2. Configurar secrets en GitHub
En GitHub → Settings → Secrets → Actions:
- `AWS_ROLE_ARN` — ARN del rol OIDC de GitHub Actions (output del paso 3)
- `ALERT_EMAIL` — email para recibir alertas SNS

### 3. Deploy
```bash
cd ..
terraform init
terraform apply
```

Confirmar la suscripción SNS desde el email recibido.

### 4. Probar manualmente
```bash
# Probar Lambda #1
aws lambda invoke \
  --function-name finops-platform-cost-anomaly-detector \
  --region us-east-1 \
  response1.json && cat response1.json

# Probar Lambda #2
aws lambda invoke \
  --function-name finops-platform-unused-resources-scanner \
  --region us-east-1 \
  response2.json && cat response2.json
```

### 5. Cleanup
```bash
terraform destroy
```

---

## Costo Estimado

| Servicio | Uso Mensual | Costo |
|---------|-------------|-------|
| Lambda #1 | 120 ejecuciones × 1s | $0.00 (free tier) |
| Lambda #2 | 30 ejecuciones × 2s | $0.00 (free tier) |
| SNS | ~50 emails | $0.00 (free tier) |
| DynamoDB | on-demand, bajo volumen | ~$1.00 |
| CloudWatch Logs | retención 7 días | ~$0.50 |
| CloudWatch Dashboard | 1 dashboard | ~$3.00 |
| Cost Explorer API | ~150 requests | ~$1.50 |
| **TOTAL** | | **~$6/mes** |

---

## Seguridad

- IAM least-privilege (roles separados para Lambda y GitHub Actions)
- Sin credenciales AWS estáticas — solo OIDC
- Bucket S3: versionado + encriptación + acceso público bloqueado
- DynamoDB: point-in-time recovery habilitado
- CloudWatch logs para auditoría completa
- TTL en DynamoDB: auto-delete de registros a los 60 días

---

## V1 → V2: Qué Cambió y Por Qué

| | V1 | V2 |
|---|---|---|
| Estructura Terraform | Flat (todos los `.tf` en root) | 5 módulos con responsabilidad clara |
| Estado | Local `terraform.tfstate` | Estado remoto S3 + file locking |
| Empaquetado Lambda | Script manual `package_lambda.sh` | Data source `archive_file` — automático |
| CI/CD | Solo `validate` (fmt + validate) | Pipeline completo `plan` + `apply` |
| Autenticación AWS | Credenciales estáticas en `.env` | OIDC — cero credenciales almacenadas |
| IAM | Un rol compartido para todo | Rol separado por workload |
| Outputs | Dispersos o inexistentes | Centralizados en `outputs.tf` raíz |

---

## Problemas Resueltos

| Problema | Causa Raíz | Solución |
|---------|-----------|----------|
| `use_lockfile` no soportado | Workflow usaba Terraform 1.7.0 | Actualizar a 1.10.0 |
| "No changes" con estado vacío | Backend S3 vacío, sin apply previo | Ejecutar `terraform apply` completo |
| `AccessDenied: ListOpenIDConnectProviders` | Rol de GitHub Actions sin permisos de lectura OIDC | Agregar `iam:ListOpenIDConnectProviders` + `iam:GetOpenIDConnectProvider` |
| ZIPs de Lambda faltantes en CI | `*.zip` en `.gitignore`, runner sin ZIPs | Agregar step de empaquetado en ambos jobs del pipeline |
| `terraform fmt` fallando | Indentación incorrecta en `modules/lambda/main.tf` | `terraform fmt -recursive` local antes del push |
| `git push` rechazado | Remote con commits que no estaban en local | `git pull --rebase origin main` |

---

## Skills Demostrados

**Infrastructure as Code**
- Terraform modular con dependencias entre módulos
- Estado remoto con backend S3 y file locking
- Patrón bootstrap para infraestructura de estado

**Serverless**
- Lambda con EventBridge scheduling (rate + cron expressions)
- Python + boto3 (Cost Explorer, EC2, ELB, RDS APIs)
- Empaquetado automático de Lambda via `archive_file`

**CI/CD & Seguridad**
- GitHub Actions OIDC — sin credenciales estáticas
- Pipeline de dos jobs: plan (todas las ramas) → apply (solo main)
- Transferencia de artefactos entre jobs (`tfplan`)

**Observabilidad**
- CloudWatch Dashboard con métricas de Lambda + DynamoDB
- CloudWatch Alarm → SNS en errores de Lambda
- Retención de logs 7 días

**FinOps**
- Detección de anomalías de costos con baseline histórico
- Identificación de recursos sin usar en EC2, ELB, RDS
- Reporte de ahorro potencial estimado

---

## Autor

**Santiago Albi** — Cloud Engineer  
[GitHub](https://github.com/SantiagoAlbi) · [LinkedIn](https://www.linkedin.com/in/santiagoalbisetti/)
