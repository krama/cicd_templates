# CI/CD Pipeline Documentation

## Overview
An automated pipeline for building and deploying applications with matrix build support, security scanning, and Kubernetes deployment capabilities.

## Structure
```
.
├── .github/
│   ├── workflows/
│   │   └── workflow.yml      # Main workflow
│   ├── scripts/
│   │   └── setup_env.sh      # Validation script
│   └── config/
│       └── env.json          # Environment configuration
```

## CI/CD Process

### 1. Validate Job
- Verifies branch rules and environments
- Determines build matrix
- Generates Docker image tags
- Checks utils requirements

### 2. Build Job
Matrix build for each context:
- Docker image build
- Security vulnerability scan
- Image squashing
- Registry publication

### 3. Deploy Job
Matrix deployment per environment:
- AWS authentication
- EKS cluster deployment
- Deployment status verification

## Branch Rules
- `feature/*`, `fix/*` → `development`
- `development` → `staging`
- `staging` → `main`
- Special rules for `affiliates`

## Configuration
env.json defines:
- Branch rules
- Build matrices
- Environments and clusters
- Utils integration

## Docker Tags
- `latest`: main branch
- `staging`: staging branch
- `develop`: development branch
- `feature-*`: feature branches

## Security
- Image scanning
- Secure credential storage
- Vulnerability checks
- Action logging

## Monitoring
- Deployment status
- Telegram alerts
- Build artifacts

Logic schema

```mermaid
graph TD
    A[Pull Request] --> B[validate job]
    B -->|Parse Config| C[Load env.json]
    C --> D{Check Branch Rules}
    D -->|Valid| E[Generate Tags]
    D -->|Invalid| F[Stop Pipeline]
    E --> G{Need Utils?}
    G -->|Yes| H[Checkout Utils]
    G -->|No| I[Skip Utils]
    H --> J[Build Job]
    I --> J
    J -->|Matrix Build| K[Docker Build]
    K --> L[Image Scan]
    L --> M[Image Squash]
    M --> N[Push Image]
    N --> O{Deploy?}
    O -->|Yes| P[Deploy Job]
    O -->|No| Q[End Pipeline]
    P -->|Matrix Deploy| R[AWS Auth]
    R --> S[EKS Deploy]
    S --> T{Success?}
    T -->|Yes| U[End Success]
    T -->|No| V[Send Alert]
```