# Workflow Stage Explanations

## Backend CI Workflow

### Stage 1: Lint

**Purpose**: Ensure code quality and consistency

**What it does:**
1. **flake8**: Checks for syntax errors, undefined names, and code style issues
   - First pass: Critical errors only (E9, F63, F7, F82)
   - Second pass: All other issues (warnings, complexity)
   
2. **black**: Checks code formatting
   - Ensures consistent code style
   - Fails if code is not formatted
   
3. **isort**: Checks import sorting
   - Ensures imports are organized consistently
   - Fails if imports are not sorted
   
4. **mypy**: Type checking (optional)
   - Checks type hints
   - Does not fail build (continue-on-error: true)

**Why it matters**: Catches code quality issues early, before they reach production.

**Fail Fast**: ✅ Yes - stops immediately on failure

---

### Stage 2: Test

**Purpose**: Verify backend functionality works correctly

**What it does:**
1. **Set up services**: PostgreSQL and Redis containers
   - PostgreSQL: Test database
   - Redis: For Django Channels testing
   
2. **Install dependencies**: Install Python packages
   - Uses pip cache for faster installs
   
3. **Run migrations**: Set up database schema
   - Creates tables for testing
   
4. **Run tests**: Execute all backend tests
   - Uses pytest with coverage
   - Generates coverage report
   
5. **Upload coverage**: Send coverage to Codecov
   - Tracks test coverage over time
   - Optional (continue-on-error: true)

**Why it matters**: Ensures code changes don't break existing functionality.

**Fail Fast**: ✅ Yes - stops immediately on failure

---

### Stage 3: Docker Build

**Purpose**: Validate Docker image builds correctly

**What it does:**
1. **Set up Docker Buildx**: Enable advanced Docker features
   - BuildKit for faster builds
   - Multi-platform support
   
2. **Build Docker image**: Create Docker image
   - Uses Dockerfile from backend/docker/
   - Uses build cache for faster builds
   - Does not push (test only)
   
3. **Test Docker image**: Verify image works
   - Runs Django check command
   - Validates image is functional

**Why it matters**: Ensures Docker image can be built and deployed.

**Fail Fast**: ✅ Yes - stops immediately on failure

**Dependencies**: Requires lint and test to pass first

---

## Backend Deploy Workflow

### Stage 1: Build and Push

**Purpose**: Build and publish Docker image to registry

**What it does:**
1. **Set up Docker Buildx**: Enable advanced Docker features
   
2. **Log in to registry**: Authenticate with GitHub Container Registry
   - Uses GITHUB_TOKEN (automatically provided)
   - No secrets needed in code
   
3. **Extract metadata**: Generate image tags
   - Branch name
   - SHA hash
   - `latest` (for main branch)
   - Semantic version (if tagged)
   
4. **Build and push**: Create and publish image
   - Uses build cache for faster builds
   - Pushes to GitHub Container Registry
   - Tags with multiple tags for flexibility
   
5. **Output metadata**: Provide image tag and digest
   - Used by deployment jobs

**Why it matters**: Creates deployable artifact for staging/production.

**Secrets Used**: `GITHUB_TOKEN` (automatically provided)

---

### Stage 2: Deploy Staging

**Purpose**: Deploy to staging environment

**What it does:**
1. **Checkout code**: Get latest code
   
2. **Deploy**: Deploy Docker image to staging
   - Uses image tag from build job
   - Environment-specific secrets from GitHub Environment
   - Example: `kubectl set image` or similar

**Why it matters**: Validates deployment process before production.

**Trigger**: 
- Automatic on push to `main`
- Manual with `staging` environment selected

**Secrets Used**: From GitHub Environment `staging`

---

### Stage 3: Deploy Production

**Purpose**: Deploy to production environment

**What it does:**
1. **Checkout code**: Get latest code
   
2. **Deploy**: Deploy Docker image to production
   - Uses image tag from build job
   - Environment-specific secrets from GitHub Environment
   - Example: `kubectl set image` or similar

**Why it matters**: Deploys to production environment.

**Trigger**: Manual workflow dispatch with `production` environment

**Secrets Used**: From GitHub Environment `production`

**Protection**: Should have required reviewers (configure in GitHub)

---

## Frontend CI Workflow

### Stage 1: Analyze

**Purpose**: Ensure Flutter code quality

**What it does:**
1. **Set up Flutter**: Install Flutter SDK
   - Uses Flutter cache for faster setup
   
2. **Get dependencies**: Install Flutter packages
   - Runs `flutter pub get`
   
3. **Run analyze**: Check code for issues
   - Analyzes Dart code
   - Checks for errors and warnings
   - `--no-fatal-infos`: Info messages don't fail build
   
4. **Check formatting**: Verify code formatting
   - Uses `dart format`
   - Fails if code is not formatted

**Why it matters**: Catches code quality issues early.

**Fail Fast**: ✅ Yes - stops immediately on failure

---

### Stage 2: Build Android

**Purpose**: Validate Android builds work

**What it does:**
1. **Set up Flutter and Java**: Install required tools
   - Flutter SDK
   - Java 17 (required for Android builds)
   
2. **Get dependencies**: Install Flutter packages
   
3. **Build APK (debug)**: Create debug Android build
   - Validates build process works
   
4. **Build APK (release)**: Create release Android build
   - Validates production build
   - Optional (continue-on-error: true)
   
5. **Upload artifact**: Save APK for debugging
   - Retained for 7 days
   - Can be downloaded from Actions

**Why it matters**: Ensures Android app can be built.

**Fail Fast**: ✅ Yes - stops immediately on failure

**Dependencies**: Requires analyze to pass first

---

### Stage 3: Build iOS

**Purpose**: Validate iOS builds work

**What it does:**
1. **Set up Flutter**: Install Flutter SDK
   - Runs on macOS (required for iOS)
   
2. **Get dependencies**: Install Flutter packages
   
3. **Build iOS (debug)**: Create debug iOS build
   - Validates build process works
   - `--no-codesign`: No code signing needed for CI
   
4. **Build iOS (release)**: Create release iOS build
   - Validates production build
   - Optional (continue-on-error: true)

**Why it matters**: Ensures iOS app can be built.

**Fail Fast**: ✅ Yes - stops immediately on failure

**Dependencies**: Requires analyze to pass first

**Note**: Requires macOS runner (iOS builds only work on macOS)

---

### Stage 4: Build Web

**Purpose**: Validate Web builds work

**What it does:**
1. **Set up Flutter**: Install Flutter SDK
   
2. **Get dependencies**: Install Flutter packages
   
3. **Build Web**: Create production Web build
   - Optimized for web deployment
   
4. **Upload artifact**: Save Web build for debugging
   - Retained for 7 days
   - Can be downloaded from Actions

**Why it matters**: Ensures Web app can be built.

**Fail Fast**: ✅ Yes - stops immediately on failure

**Dependencies**: Requires analyze to pass first

---

### Stage 5: Test

**Purpose**: Run Flutter tests

**What it does:**
1. **Set up Flutter**: Install Flutter SDK
   
2. **Get dependencies**: Install Flutter packages
   
3. **Run tests**: Execute all Flutter tests
   - Uses `flutter test`
   - Generates coverage report
   
4. **Upload coverage**: Send coverage to Codecov
   - Tracks test coverage over time
   - Optional (continue-on-error: true)

**Why it matters**: Ensures tests pass and tracks coverage.

**Fail Fast**: ✅ Yes - stops immediately on failure

**Dependencies**: Requires analyze to pass first

---

## Common Patterns

### Fail Fast

All workflows use `fail-fast: true` to stop immediately on first failure, saving CI time and providing quick feedback.

### Path Filtering

Workflows only run when relevant files change:
- Backend: `backend/**`
- Frontend: `frontend/**`

This saves CI resources by not running unnecessary workflows.

### Caching

- **Python**: pip cache (via setup-python)
- **Flutter**: Flutter cache (via flutter-action)
- **Docker**: Build cache (via buildx)

Caching speeds up builds significantly.

### Secrets

- **No secrets in code**: All secrets use GitHub Secrets
- **Environment secrets**: Deployment secrets in GitHub Environments
- **Automatic tokens**: GITHUB_TOKEN provided automatically

---

## Summary

### Backend Stages

1. **Lint**: Code quality (flake8, black, isort, mypy)
2. **Test**: Run tests with coverage
3. **Docker Build**: Validate Docker image
4. **Deploy**: Build and deploy to staging/production

### Frontend Stages

1. **Analyze**: Code quality (Flutter analyze, format)
2. **Build**: Validate Android/iOS/Web builds
3. **Test**: Run tests with coverage

### Key Features

- ✅ **Fail Fast**: Stop on first failure
- ✅ **Clear Logs**: Descriptive step names
- ✅ **No Secrets**: All secrets in GitHub Secrets
- ✅ **Caching**: Faster builds
- ✅ **Coverage**: Track test coverage

All stages are designed to provide fast, clear feedback while maintaining security and best practices.

