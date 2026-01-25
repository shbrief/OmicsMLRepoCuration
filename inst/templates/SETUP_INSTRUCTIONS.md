# Setup Instructions: Automated Schema-Metadata Synchronization

This document provides step-by-step instructions for setting up automated validation between **OmicsMLRepoCuration** (schema repository) and **curatedMetagenomicDataCuration** (metadata repository).

## Overview

The system ensures that all metadata in `curatedMetagenomicDataCuration` stays synchronized with the latest schema from `OmicsMLRepoCuration` through:

1. **Automated validation** on every metadata change
2. **Daily scheduled checks** to catch schema updates
3. **Immediate notifications** when schema changes
4. **Pull request validation** to prevent invalid metadata from merging

---

## Part 1: Setup in OmicsMLRepoCuration (Schema Repository)

### ✅ Already Complete

The file `.github/workflows/notify-dependents.yml` has been created in this repository. It will automatically trigger validation in `curatedMetagenomicDataCuration` whenever the schema changes.

### Required: Create GitHub Secret

1. Go to **OmicsMLRepoCuration** repository settings
2. Navigate to **Settings > Secrets and variables > Actions**
3. Click **New repository secret**
4. Name: `DEPENDENT_REPO_TOKEN`
5. Value: Create a Personal Access Token (PAT) with these steps:
   - Go to GitHub **Settings > Developer settings > Personal access tokens > Tokens (classic)**
   - Click **Generate new token (classic)**
   - Give it a name: "Schema Notification Token"
   - Select scope: `repo` (full control of private repositories)
   - Click **Generate token**
   - Copy the token and paste it as the secret value

---

## Part 2: Setup in curatedMetagenomicDataCuration (Metadata Repository)

### Step 1: Copy Validation Workflow

1. In the `curatedMetagenomicDataCuration` repository, create the directory structure:
   ```bash
   mkdir -p .github/workflows
   ```

2. Copy the validation workflow:
   ```bash
   cp inst/templates/github-actions-metadata-validation.yml \
      /path/to/curatedMetagenomicDataCuration/.github/workflows/validate-metadata.yml
   ```
   
   Or create the file manually using the template from `inst/templates/github-actions-metadata-validation.yml`

### Step 2: Enable Workflow Permissions

1. Go to **curatedMetagenomicDataCuration** repository
2. Navigate to **Settings > Actions > General**
3. Under **Workflow permissions**:
   - Select ☑️ **Read and write permissions**
   - Check ☑️ **Allow GitHub Actions to create and approve pull requests**
4. Click **Save**

### Step 3: Enable Repository Dispatch Events

1. The workflow is already configured to receive `repository_dispatch` events
2. Ensure the repository is not archived or has restrictions on incoming webhooks
3. The event type `schema-updated` will be sent from OmicsMLRepoCuration

### Step 4: Configure Branch Protection (Recommended)

1. Go to **Settings > Branches**
2. Click **Add rule** or edit existing rule for `master` branch
3. Configure:
   - Branch name pattern: `master`
   - ☑️ **Require status checks to pass before merging**
   - Search and select: `validate` (will appear after first workflow run)
   - ☑️ **Require branches to be up to date before merging**
4. Click **Create** or **Save changes**

This ensures that PRs cannot merge if validation fails.

### Step 5: Add Validation Status Badge (Optional)

Add to the repository README.md:

```markdown
## Metadata Validation Status

![Validation Status](https://github.com/waldronlab/curatedMetagenomicDataCuration/actions/workflows/validate-metadata.yml/badge.svg)

All metadata files are automatically validated against the latest schema from [OmicsMLRepoCuration](https://github.com/waldronlab/OmicsMLRepoCuration).
```

---

## Part 3: Testing the Setup

### Test 1: Manual Trigger

1. Go to **curatedMetagenomicDataCuration > Actions**
2. Select **Validate Metadata Against Latest Schema**
3. Click **Run workflow > Run workflow**
4. Wait for completion and check results

### Test 2: Schema Change Trigger

1. Make a change to any file in `OmicsMLRepoCuration/inst/schema/`
2. Commit and push to main branch
3. Check **curatedMetagenomicDataCuration > Actions**
4. A new workflow run should start automatically within 1-2 minutes

### Test 3: Pull Request Validation

1. In `curatedMetagenomicDataCuration`, create a new branch
2. Modify a metadata file: `inst/harmonized/{study_name}/{study_name}_sample.tsv`
3. Create a pull request
4. Validation should run automatically
5. PR will show validation status

---

## Understanding the Validation Workflow

### When Validation Runs

| Trigger | Description | Frequency |
|---------|-------------|-----------|
| **Push to master** | Validates after metadata changes | Every commit |
| **Pull Request** | Validates before merge | Every PR |
| **Daily Schedule** | Catches schema updates | Daily at 2 AM UTC |
| **Schema Update** | Immediate validation | When OmicsMLRepoCuration schema changes |
| **Manual** | On-demand validation | As needed |

### What Gets Validated

- All files matching pattern: `inst/harmonized/**/*_sample.tsv`
- Validated against latest schema from OmicsMLRepoCuration
- Checks:
  - Required fields present
  - Data types correct
  - Enum values valid (including dynamic enums)
  - Pattern matching (e.g., ontology IDs)
  - Cross-field dependencies

### Validation Output

**On Success:**
- ✅ Green checkmark on commit/PR
- Detailed validation report in workflow logs
- No errors or warnings

**On Failure:**
- ❌ Red X on commit/PR
- Detailed error messages showing:
  - Which files failed
  - Which fields have issues
  - What needs to be fixed
- PR cannot merge (if branch protection enabled)
- Validation report attached as artifact

---

## Troubleshooting

### Problem: Workflow doesn't trigger on schema update

**Solution:**
- Check that `DEPENDENT_REPO_TOKEN` secret exists in OmicsMLRepoCuration
- Verify token has `repo` scope
- Check token hasn't expired
- Verify workflow file exists in `.github/workflows/` (not just `.github/`)

### Problem: Validation fails with "package not found"

**Solution:**
- The workflow installs from GitHub, ensure OmicsMLRepoCuration is public or token has access
- Check workflow logs for installation errors
- Verify DESCRIPTION file and package structure are correct

### Problem: All files fail with same error

**Solution:**
- Schema may have changed significantly
- Review recent commits in OmicsMLRepoCuration/inst/schema/
- Check if required fields were added
- May need bulk update to metadata files

### Problem: Validation times out

**Solution:**
- Default timeout is 6 hours
- If you have many files, consider splitting validation into parallel jobs
- Or increase timeout in workflow: `timeout-minutes: 360`

---

## Maintenance

### Updating the Workflow

When new features are added to OmicsMLRepoCuration, you may need to update the validation workflow:

1. Check for updated template in `OmicsMLRepoCuration/inst/templates/`
2. Compare with your `.github/workflows/validate-metadata.yml`
3. Merge any new features or improvements
4. Test with manual trigger

### Monitoring

- Check **Actions** tab regularly for validation status
- Set up GitHub notifications for workflow failures:
  - Go to **Settings > Notifications**
  - Enable **Actions: Failed workflow run**
- Review validation reports for warnings (non-blocking issues)

### Schema Versioning

The validation always uses the **latest** schema from the main branch of OmicsMLRepoCuration. If you need to validate against a specific version:

1. Modify the workflow's install step:
   ```r
   remotes::install_github("waldronlab/OmicsMLRepoCuration@v1.2.0")
   ```
2. This pins to a specific version/tag/commit
3. Note: This defeats the auto-sync purpose, only use temporarily

---

## Benefits

✅ **Automatic synchronization** - No manual coordination needed  
✅ **Immediate feedback** - Know within minutes if metadata breaks  
✅ **Prevents regressions** - Invalid metadata can't merge  
✅ **Transparent** - All validation results visible in GitHub UI  
✅ **Documented** - Validation reports show exactly what's wrong  
✅ **Zero maintenance** - Runs automatically forever  

---

## Support

For issues with:
- **Schema validation logic**: Open issue in OmicsMLRepoCuration
- **Workflow configuration**: Check this document or workflow file comments
- **Specific validation errors**: Review error messages and schema documentation
- **General questions**: Contact repository maintainers

---

## Summary

Once setup is complete:

1. ✅ Schema changes automatically trigger metadata validation
2. ✅ Daily checks ensure nothing slips through
3. ✅ PRs validated before merge
4. ✅ Validation status visible in GitHub UI
5. ✅ Detailed reports help fix issues quickly

Your metadata will always stay in sync with the latest schema! 🎉
