# GitHub Actions Workflows

## Overview

This directory contains CI/CD workflows for the Smart Trip Planner project, covering both backend (Django) and frontend (Flutter) components.

---

## Workflows

### 1. Backend CI (`backend-ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches (backend changes only)
- Pull requests to `main` or `develop` (backend changes only)

**Jobs:**

#### Lint
- **Purpose**: Code quality checks
- **Steps**:
  1. Set up Python
  2. Install dependencies
  3. Run flake8 (linting)
  4. Check code formatting with black
  5. Check import sorting with isort
  6. Run mypy (type checking, optional)

**Fail Fast**: ✅ Yes - stops on first failure

#### Test
- **Purpose**: Run backend tests
- **Services**:
  - PostgreSQL 15 (test database)
  - Redis 7 (for channels)
- **Steps**:
  1. Set up Python
  2. Install dependencies
  3. Run migrations
  4. Run tests with coverage
  5. Upload coverage to Codecov

**Fail Fast**: ✅ Yes - stops on first failure

#### Docker Build
- **Purpose**: Validate Docker image builds
- **Dependencies**: Requires lint and test to pass
- **Steps**:
  1. Set up Docker Buildx
  2. Build Docker image
  3. Test Docker image

**Fail Fast**: ✅ Yes - stops on first failure

---

### 2. Backend Deploy (`backend-deploy.yml`)

**Triggers:**
- Push to `main` branch (backend changes only)
- Manual workflow dispatch (with environment selection)

**Jobs:**

#### Build and Push
- **Purpose**: Build and push Docker image to GitHub Container Registry
- **Steps**:
  1. Set up Docker Buildx
  2. Log in to Container Registry
  3. Extract metadata (tags)
  4. Build and push Docker image
  5. Output image tag and digest

**Image Tags:**
- Branch name
- SHA hash
- `latest` (for main branch)
- Semantic version (if tagged)

#### Deploy Staging
- **Purpose**: Deploy to staging environment
- **Trigger**: Push to `main` or manual with `staging` environment
- **Steps**:
  1. Deploy using image tag from build job
  2. Uses staging secrets from GitHub environment

#### Deploy Production
- **Purpose**: Deploy to production environment
- **Trigger**: Manual workflow dispatch with `production` environment
- **Steps**:
  1. Deploy using image tag from build job
  2. Uses production secrets from GitHub environment

---

### 3. Frontend CI (`frontend-ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches (frontend changes only)
- Pull requests to `main` or `develop` (frontend changes only)

**Jobs:**

#### Analyze
- **Purpose**: Code quality checks
- **Steps**:
  1. Set up Flutter
  2. Get dependencies
  3. Run Flutter analyze
  4. Check code formatting

**Fail Fast**: ✅ Yes - stops on first failure

#### Build Android
- **Purpose**: Validate Android builds
- **Dependencies**: Requires analyze to pass
- **Steps**:
  1. Set up Flutter and Java
  2. Get dependencies
  3. Build APK (debug)
  4. Build APK (release)
  5. Upload APK artifact

**Fail Fast**: ✅ Yes - stops on first failure

#### Build iOS
- **Purpose**: Validate iOS builds
- **Dependencies**: Requires analyze to pass
- **Runs on**: macOS (required for iOS builds)
- **Steps**:
  1. Set up Flutter
  2. Get dependencies
  3. Build iOS (debug)
  4. Build iOS (release)

**Fail Fast**: ✅ Yes - stops on first failure

#### Build Web
- **Purpose**: Validate Web builds
- **Dependencies**: Requires analyze to pass
- **Steps**:
  1. Set up Flutter
  2. Get dependencies
  3. Build Web (release)
  4. Upload Web build artifact

**Fail Fast**: ✅ Yes - stops on first failure

#### Test
- **Purpose**: Run Flutter tests
- **Dependencies**: Requires analyze to pass
- **Steps**:
  1. Set up Flutter
  2. Get dependencies
  3. Run tests with coverage
  4. Upload coverage to Codecov

**Fail Fast**: ✅ Yes - stops on first failure

---

### 4. CI (`ci.yml`)

**Purpose**: Orchestrate all CI workflows

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`

**Jobs:**
- Runs backend CI workflow
- Runs frontend CI workflow

---

## GitHub Secrets

### Required Secrets

#### Backend

- `GITHUB_TOKEN` (automatically provided)
  - Used for: Container Registry authentication

#### Deployment (Optional - add as needed)

- `STAGING_URL`
  - Used for: Staging deployment URL
  - Set in: GitHub Environment `staging`

- `PRODUCTION_URL`
  - Used for: Production deployment URL
  - Set in: GitHub Environment `production`

- `STAGING_KUBECONFIG` (if using Kubernetes)
  - Used for: Staging cluster access
  - Set in: GitHub Environment `staging`

- `PRODUCTION_KUBECONFIG` (if using Kubernetes)
  - Used for: Production cluster access
  - Set in: GitHub Environment `production`

### Setting Up Secrets

1. Go to repository Settings → Secrets and variables → Actions
2. Add repository secrets for shared secrets
3. Add environment secrets for environment-specific secrets

---

## GitHub Environments

### Staging Environment

**Purpose**: Staging deployment environment

**Protection Rules** (optional):
- Required reviewers (if needed)
- Wait timer (if needed)

**Secrets:**
- `STAGING_URL`
- `STAGING_KUBECONFIG` (if using Kubernetes)

### Production Environment

**Purpose**: Production deployment environment

**Protection Rules** (recommended):
- Required reviewers
- Wait timer (optional)

**Secrets:**
- `PRODUCTION_URL`
- `PRODUCTION_KUBECONFIG` (if using Kubernetes)

---

## Workflow Features

### Fail Fast

All workflows use `fail-fast: true` to stop immediately on first failure, saving CI time and providing quick feedback.

### Path Filtering

Workflows only run when relevant files change:
- Backend workflows: `backend/**`
- Frontend workflows: `frontend/**`

### Caching

- **Python**: pip cache (via setup-python)
- **Flutter**: Flutter cache (via flutter-action)
- **Docker**: Build cache (via buildx)

### Artifacts

- **Backend**: Docker images pushed to GitHub Container Registry
- **Frontend**: APK and Web build artifacts (retained for 7 days)

### Coverage

- **Backend**: Coverage uploaded to Codecov
- **Frontend**: Coverage uploaded to Codecov

---

## Workflow Execution

### Automatic Triggers

1. **Push to main/develop**: Runs CI workflows
2. **Pull request**: Runs CI workflows (no deployment)

### Manual Triggers

1. **Backend Deploy**: Manual workflow dispatch
   - Select environment: `staging` or `production`
   - Only runs on `main` branch

---

## Logs and Debugging

### Clear Logs

- Each step has descriptive names
- Error messages are clear and actionable
- Failed steps show full error output

### Debugging Failed Workflows

1. Check workflow logs in Actions tab
2. Identify failed job and step
3. Review error messages
4. Fix issue and push changes

### Common Issues

#### Backend

- **Database connection**: Check PostgreSQL service health
- **Redis connection**: Check Redis service health
- **Docker build**: Check Dockerfile syntax

#### Frontend

- **Flutter version**: Ensure Flutter version matches
- **Dependencies**: Check `pubspec.yaml` for issues
- **Build failures**: Check platform-specific requirements

---

## Best Practices

1. **No Secrets in Code**: All secrets use GitHub Secrets
2. **Fail Fast**: Stop on first failure
3. **Clear Logs**: Descriptive step names and messages
4. **Path Filtering**: Only run when relevant files change
5. **Caching**: Use caching for faster builds
6. **Artifacts**: Upload build artifacts for debugging
7. **Coverage**: Track test coverage over time

---

## Summary

### Backend Workflows

- ✅ **Lint**: Code quality checks
- ✅ **Test**: Run tests with coverage
- ✅ **Docker Build**: Validate Docker image
- ✅ **Deploy**: Build and deploy to staging/production

### Frontend Workflows

- ✅ **Analyze**: Code quality checks
- ✅ **Build**: Validate Android/iOS/Web builds
- ✅ **Test**: Run tests with coverage

### Features

- ✅ **Fail Fast**: Stop on first failure
- ✅ **Clear Logs**: Descriptive output
- ✅ **Secrets**: No secrets in code
- ✅ **Caching**: Faster builds
- ✅ **Coverage**: Track test coverage

All workflows are production-ready and follow best practices for CI/CD pipelines.

