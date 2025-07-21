# 🔧 Troubleshooting Guide - Speculod Blockchain

**Complete troubleshooting reference for common deployment and build issues**

## 🚨 Google Cloud Build Issues

### Problem: "package speculod/docs is not in std"

**Symptoms:**
```bash
app/app.go:49:2: package speculod/docs is not in std (/usr/local/go/src/speculod/docs)
```

**Root Cause:**
The `docs` directory is not being included in the Docker build context, even though it's required for Go imports.

**Solution:**
1. **Check `.dockerignore`** - Remove `docs/` if present:
```bash
# Remove this line from .dockerignore:
docs/
```

2. **Verify docs directory exists locally:**
```bash
ls -la docs/
# Should show: docs.go, static/, template/, testing.md
```

3. **Check Go import in app/app.go:**
```go
import (
    "speculod/docs"  // This requires docs/ directory in build context
)
```

---

### Problem: Missing cmd Directory in Build

**Symptoms:**
```bash
go build -o build/speculodd ./cmd/speculodd
# Error: cmd directory not found
```

**Root Cause:**
`.gitignore` pattern is too broad and excludes source directories from Git tracking.

**Solution:**
1. **Fix .gitignore pattern specificity:**
```bash
# Check current .gitignore
cat .gitignore | grep speculodd

# WRONG (excludes source directories):
speculodd

# CORRECT (only excludes root binary):
/speculodd
```

2. **Add missing files to Git:**
```bash
# Check if cmd files are tracked
git ls-files cmd/

# If empty, add them:
git add cmd/
git commit -m "Add cmd directory files to Git tracking"
```

3. **Verify file inclusion:**
```bash
# Check what files will be uploaded to Cloud Build:
gcloud meta list-files-for-upload | grep cmd
```

---

### Problem: Docker Tag Format Errors

**Symptoms:**
```bash
invalid argument "gcr.io/speculo-blockchain/speculod-api:" for "-t, --tag" flag: invalid reference format
```

**Root Cause:**
`$COMMIT_SHA` environment variable is undefined in manual Cloud Build submissions, creating empty tags.

**Solution:**
1. **Get current commit SHA:**
```bash
git rev-parse HEAD
# Output: 8466bb4a5c5f7c0179745c9337ce5cee919088d7
```

2. **Fix cloudbuild-api.yaml in TWO places:**
```yaml
# Fix build step args:
args: 
  - 'build'
  - '-t'
  - 'gcr.io/$PROJECT_ID/speculod-api:ACTUAL_COMMIT_SHA'  # Replace with real SHA
  - '-t'
  - 'gcr.io/$PROJECT_ID/speculod-api:latest'

# ALSO fix images section (often missed):
images:
  - 'gcr.io/$PROJECT_ID/speculod-api:ACTUAL_COMMIT_SHA'  # Replace with real SHA
  - 'gcr.io/$PROJECT_ID/speculod-api:latest'
```

---

### Problem: Build Cache Issues

**Symptoms:**
- Local Docker builds work (158MB context)
- Cloud Build fails with same code (31MB context)
- Files appear to be included but build still fails

**Root Cause:**
Google Cloud Build is using cached Docker layers from previous failed builds that didn't include required files.

**Solution:**
1. **Purge all cached images:**
```bash
# List existing images
gcloud container images list-tags gcr.io/PROJECT_ID/IMAGE_NAME

# Delete all versions
gcloud container images delete gcr.io/PROJECT_ID/IMAGE_NAME --force-delete-tags --quiet
gcloud container images delete gcr.io/PROJECT_ID/IMAGE_NAME:TAG_NAME --quiet
```

2. **Force fresh build by adding --no-cache:**
```yaml
# In cloudbuild-api.yaml
args: 
  - 'build'
  - '--no-cache'  # Add this line
  - '-t'
  - 'gcr.io/$PROJECT_ID/speculod-api:latest'
```

3. **Verify cache is cleared:**
```bash
gcloud container images list-tags gcr.io/PROJECT_ID/IMAGE_NAME
# Should show: Listed 0 items.
```

---

### Problem: "failed to find images after execution"

**Symptoms:**
```bash
ERROR: failed to find one or more images after execution of build steps: ["gcr.io/speculo-blockchain/speculod-api:"]
```

**Root Cause:**
Mismatch between images built and images expected in `cloudbuild.yaml` configuration.

**Solution:**
Check that ALL references to variables are properly set:
```yaml
# Build step creates these images:
- 'gcr.io/$PROJECT_ID/speculod-api:COMMIT_SHA'
- 'gcr.io/$PROJECT_ID/speculod-api:latest'

# Images section must match EXACTLY:
images:
  - 'gcr.io/$PROJECT_ID/speculod-api:COMMIT_SHA'  # Must match build step
  - 'gcr.io/$PROJECT_ID/speculod-api:latest'      # Must match build step
```

---

## 🔍 File Inclusion Debugging

### Quick Diagnostic Commands

```bash
# 1. Check what files Git is tracking:
git ls-files | grep -E "(cmd|docs)/"

# 2. Check .gitignore patterns:
cat .gitignore | grep -E "(speculodd|cmd|docs)"

# 3. Check .dockerignore patterns:
cat .dockerignore | grep -E "(cmd|docs)"

# 4. Check .gcloudignore patterns:
cat .gcloudignore | grep -E "(cmd|docs)"

# 5. Check what will be uploaded to Cloud Build:
gcloud meta list-files-for-upload | wc -l
gcloud meta list-files-for-upload | grep -E "(cmd|docs)/"

# 6. Compare local vs cloud contexts:
# Local Docker context size:
docker build --dry-run . 2>&1 | grep "Sending build context"
# Should be ~150MB+ for full context
```

### Expected File Counts
- **Full Project**: ~261 files, ~68MB compressed, ~71MB Docker context
- **Missing Files**: ~200 files, ~31MB compressed, ~31MB Docker context

### Critical Directories
```bash
# These directories MUST be included:
cmd/speculodd/           # Main application entry point
docs/                    # Required for Go imports in app/app.go
proto/speculod/          # Protocol buffer definitions
x/*/                     # Cosmos SDK modules
app/                     # Application configuration
```

---

## 🚀 Build Process Validation

### Successful Build Indicators

```bash
# 1. Proper file count in upload:
Creating temporary archive of 261 file(s) totalling 68.1 MiB

# 2. Proper Docker context size:
Sending build context to Docker daemon  71.36MB

# 3. Successful Go build:
go build -o build/speculodd ./cmd/speculodd
# No errors about missing packages

# 4. Successful image creation:
Successfully built 12345abcdef
Successfully tagged gcr.io/PROJECT_ID/speculod-api:latest

# 5. Successful push:
The push refers to repository [gcr.io/PROJECT_ID/speculod-api]
```

### Failed Build Indicators

```bash
# 1. Low file count:
Creating temporary archive of ~200 file(s) totalling ~31 MiB

# 2. Small Docker context:
Sending build context to Docker daemon  ~31MB

# 3. Missing package errors:
package speculod/docs is not in std
package speculod/cmd/speculodd is not in std

# 4. Invalid tag format:
invalid argument "gcr.io/project/image:" for "-t, --tag" flag
```

---

## 📚 Additional Resources

- [Docker Build Context Documentation](https://docs.docker.com/engine/reference/builder/#dockerignore-file)
- [Google Cloud Build File Inclusion](https://cloud.google.com/build/docs/build-config-file-schema)
- [Git Ignore Patterns](https://git-scm.com/docs/gitignore)
- [Cosmos SDK Build Requirements](https://docs.cosmos.network/)

---

**Last Updated**: July 20, 2025  
**Status**: ✅ All major build issues resolved and documented
