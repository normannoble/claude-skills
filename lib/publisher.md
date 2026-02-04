# GitHub Pages Publishing

## Prerequisites Check

Before publishing, verify these requirements:

### 1. GitHub CLI Installation
```bash
gh --version
```

If not installed, direct user to: https://cli.github.com/

### 2. GitHub CLI Authentication
```bash
gh auth status
```

Expected output for authenticated user:
```
github.com
  ✓ Logged in to github.com as <username>
  ✓ Git operations for github.com configured to use https protocol.
  ✓ Token: gho_****
  ✓ Token scopes: gist, read:org, repo, workflow
```

If not authenticated:
```bash
gh auth login
```

### 3. For Enterprise GitHub
```bash
gh auth login --hostname <enterprise-hostname>
```

## Publishing Workflow

### Step 1: Validate Repository Access

```bash
gh repo view <owner/repo> --json name,visibility,defaultBranchRef
```

This confirms:
- Repository exists
- User has access
- We know the default branch

### Step 2: Prepare Local Copy

Create a temporary working directory:
```bash
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
```

Clone the repository:
```bash
gh repo clone <owner/repo> . -- --depth 1
```

### Step 3: Set Up gh-pages Branch

Check if gh-pages branch exists:
```bash
git ls-remote --heads origin gh-pages
```

If branch exists:
```bash
git fetch origin gh-pages
git checkout gh-pages
```

If branch doesn't exist, create it:
```bash
git checkout --orphan gh-pages
git rm -rf .
```

### Step 4: Determine Folder Name

Each conversation is published to its own folder. Generate a suggested name based on:
- Main topic from conversation
- Date if relevant
- User's title preference

```bash
# Suggest a folder name
FOLDER_NAME="product-strategy-2026"

# Validate: lowercase, hyphenated, no special chars
FOLDER_NAME=$(echo "$FOLDER_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')

# Check it doesn't already exist
if [ -d "$FOLDER_NAME" ]; then
  echo "Folder '$FOLDER_NAME' already exists. Choose a different name or update existing."
fi
```

Present to user:
```
What should I name this site's folder?
Suggested: "product-strategy-2026"

Published URL will be: https://owner.github.io/repo/product-strategy-2026/
```

### Step 5: Copy Generated Files

Copy files into the folder:
```bash
mkdir -p "$FOLDER_NAME"
cp -r <source-files>/* "$FOLDER_NAME/"
```

Ensure `index.html` is in the folder.

### Step 6: Commit Changes

```bash
git add "$FOLDER_NAME/"
git commit -m "Published '$FOLDER_NAME' via /pages skill

Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Folder: $FOLDER_NAME
Pages: <list of pages>"
```

### Step 6: Push to Remote

```bash
git push -u origin gh-pages
```

If push is rejected due to conflicts:
```bash
git pull --rebase origin gh-pages
git push origin gh-pages
```

### Step 7: Verify and Enable Pages

Check if Pages is configured:
```bash
gh api repos/<owner>/<repo>/pages --jq '.html_url'
```

If Pages not enabled, enable it via API:
```bash
# IMPORTANT: Use --input with JSON, not -f with stringified JSON
gh api repos/<owner>/<repo>/pages -X POST --input - <<EOF
{
  "build_type": "legacy",
  "source": {
    "branch": "gh-pages",
    "path": "/"
  }
}
EOF
```

**Common API errors:**
- `HTTP 409 "already enabled"` - Pages already active, ignore error
- `HTTP 422 "plan does not support"` - Repo is private on free plan, need to make public or upgrade

**If repo is private and user wants Pages:**
```bash
# Make repo public (requires explicit confirmation)
gh repo edit <owner>/<repo> --visibility public --accept-visibility-change-consequences
```

Then retry enabling Pages.

### Step 8: Return Published URL

Format: `https://<owner>.github.io/<repo>/`

For organization sites: `https://<org>.github.io/<repo>/`

For custom domains (if configured): The custom domain URL

## Cleanup

After successful publish:
```bash
rm -rf "$TEMP_DIR"
```

## Error Handling

### Authentication Errors

**Error**: `gh: not logged in`
```
You're not authenticated with GitHub. Let's fix that:

Run: gh auth login

Then follow the prompts to authenticate via browser or token.
```

**Error**: `HTTP 401` or `Bad credentials`
```
Your GitHub token may have expired. Let's re-authenticate:

Run: gh auth login

If you're using an enterprise GitHub, add: --hostname <your-enterprise-host>
```

**Error**: `SAML SSO enforcement` or `Resource protected by organization SAML enforcement`
```
This organization requires SSO authentication.

1. First, visit the authorization URL shown in the error
2. Then refresh your token with org access:

   gh auth refresh -h github.com -s repo,read:org

3. I'll retry the operation after you confirm.
```

**Error**: `OAuth Application` blocked by SAML (push fails after clone works)

When `gh repo clone` works but `git push` fails with "re-authorize the OAuth Application":
```bash
# Use gh as git credential helper instead of other OAuth apps
git config --local credential.helper '!gh auth git-credential'
git push -u origin gh-pages
```

### Repository Errors

**Error**: `repository not found`
```
I couldn't find the repository '<owner/repo>'.

Please check:
1. The repository name is correct (format: owner/repo)
2. You have access to this repository
3. For private repos, ensure your token has the 'repo' scope

You can verify with: gh repo view <owner/repo>
```

**Error**: `Permission denied`
```
You don't have permission to push to this repository.

Please check:
1. You have write access to the repository
2. For organization repos, you may need to request access
3. SSO authentication may be required: gh auth login
```

### Push Errors

**Error**: `Updates were rejected because the remote contains work`
```
The gh-pages branch has changes I don't have locally.

Options:
1. **Pull and merge** - Incorporate remote changes (recommended)
2. **Force push** - Overwrite remote (use with caution)

Which would you prefer?
```

For pull and merge:
```bash
git pull --rebase origin gh-pages
git push origin gh-pages
```

For force push (with user confirmation):
```bash
git push --force origin gh-pages
```

### Pages Configuration Errors

**Error**: Pages not enabled
```
GitHub Pages isn't enabled for this repository.

To enable it:
1. Go to https://github.com/<owner>/<repo>/settings/pages
2. Under "Build and deployment":
   - Source: "Deploy from a branch"
   - Branch: "gh-pages" / root
3. Click Save

Once enabled, try publishing again.
```

**Error**: Pages build failed
```
GitHub Pages encountered a build error.

Check the Actions tab for details:
https://github.com/<owner>/<repo>/actions

Common issues:
- Invalid HTML syntax
- File too large (>100MB limit)
- Invalid filename characters
```

## Site Tracking

After successful publish, update the tracking file:

### File Location
`~/.claude/github-pages-sites.json`

### Schema
```json
{
  "version": 1,
  "sites": [
    {
      "id": "uuid-v4",
      "repo": "owner/repo",
      "branch": "gh-pages",
      "folder": "product-strategy-2026",
      "url": "https://owner.github.io/repo/product-strategy-2026/",
      "title": "Product Strategy 2026",
      "pages": ["index.html", "features.html", "roadmap.html"],
      "lastPublish": "2026-02-04T10:00:00Z",
      "contentHash": "sha256:abc123...",
      "publishCount": 1
    }
  ]
}
```

### Repo Structure

A single repo contains multiple conversation sites:

```
repo (gh-pages branch)/
├── product-strategy-2026/
│   ├── index.html
│   ├── features.html
│   └── roadmap.html
├── quarterly-review-q1/
│   ├── index.html
│   └── summary.html
├── team-onboarding/
│   └── index.html
└── index.html  (optional: auto-generated index of all sites)
```

### Operations

**Add new site**:
```javascript
sites.push({
  id: crypto.randomUUID(),
  repo: "owner/repo",
  // ...other fields
});
```

**Update existing site**:
```javascript
const site = sites.find(s => s.repo === "owner/repo");
site.lastPublish = new Date().toISOString();
site.publishCount++;
site.contentHash = newHash;
```

## Audit Logging

### File Location
`~/.claude/github-pages-audit.log`

### Format
```
<ISO-timestamp> | <ACTION> | <repo> | "<title>" | <status>
```

### Actions
- `PUBLISH` - New site published
- `UPDATE` - Existing site updated
- `ROLLBACK` - Reverted to previous version
- `DELETE` - Site removed

### Example Entries
```
2026-02-04T10:00:00Z | PUBLISH | owner/repo | "Product Landing Page" | success
2026-02-04T10:30:00Z | UPDATE | owner/repo | "Updated pricing section" | success
2026-02-04T11:00:00Z | PUBLISH | owner/other | "Documentation" | failed:push-rejected
```

### Logging Command
```bash
echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") | PUBLISH | $REPO | \"$TITLE\" | success" >> ~/.claude/github-pages-audit.log
```
