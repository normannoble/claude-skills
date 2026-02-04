# Repository Configuration

The skill supports multiple ways to configure target repositories, checked in this order:

1. **Project-level config** (`.claude/pages.json` in current directory)
2. **User default** (`~/.claude/pages-config.json`)
3. **Enterprise policy** (`~/.claude/pages-policy.json`)
4. **Interactive prompt** (fallback if no config found)

---

## 1. Project-Level Configuration

Store repo settings per project by creating `.claude/pages.json` in the project root:

```json
{
  "repo": "myorg/project-docs",
  "branch": "gh-pages",
  "path": "/docs"
}
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `repo` | Yes | Target repository in `owner/repo` format |
| `branch` | No | Branch to publish to (default: `gh-pages`) |
| `path` | No | Subdirectory within branch (default: `/`) |

### Creating Project Config

When a user publishes for the first time from a project, offer to save the config:

```
You published to myorg/project-docs.

Would you like me to save this as the default for this project?
This creates .claude/pages.json so you won't need to specify the repo next time.
```

---

## 2. User Default Configuration

Set personal default repos at `~/.claude/pages-config.json`:

```json
{
  "defaultPublicRepo": "username/public-site",
  "defaultPrivateRepo": "myorg/internal-docs",
  "defaultBranch": "gh-pages",
  "preferences": {
    "autoPreview": true,
    "style": "minimal"
  }
}
```

### Fields

| Field | Description |
|-------|-------------|
| `defaultPublicRepo` | Default repo for public content |
| `defaultPrivateRepo` | Default repo for private/internal content |
| `defaultBranch` | Default branch (default: `gh-pages`) |
| `preferences.autoPreview` | Auto-open browser preview (default: `true`) |
| `preferences.style` | Default styling: `minimal`, `professional`, `colorful` |

### Setting User Defaults

Users can set defaults via conversation:

```
User: Set my default public repo to username/my-site

Claude: Done! I've saved username/my-site as your default for public pages.
```

```
User: Set my default private repo to myorg/internal-docs

Claude: Done! I've saved myorg/internal-docs as your default for private pages.
```

Or set both at once:

```
User: /pages set-default --public username/site --private myorg/internal

Claude: Done! Defaults saved:
        - Public pages: username/site
        - Private pages: myorg/internal
```

This creates/updates `~/.claude/pages-config.json`.

### Visibility Selection

When publishing with both defaults configured, Claude asks:

```
Claude: Should this be public or private?

        1. Public (username/site) - Anyone can view
        2. Private (myorg/internal) - Only org members can view
```

If only one default is set, that's used without asking.

---

## 3. Enterprise Policy Configuration

Administrators can restrict which repos users can publish to via `~/.claude/pages-policy.json`:

```json
{
  "allowedRepos": [
    "myorg/public-docs",
    "myorg/team-site",
    "myorg/product-pages"
  ],
  "allowedOrgs": [
    "myorg"
  ],
  "requireApproval": false,
  "auditWebhook": "https://audit.example.com/pages-publish"
}
```

### Fields

| Field | Description |
|-------|-------------|
| `allowedRepos` | Explicit list of allowed repositories |
| `allowedOrgs` | Allow any repo in these organizations |
| `requireApproval` | If true, publish requires manual approval step |
| `auditWebhook` | URL to POST publish events for external logging |

### Behavior

When policy exists:
- Only repos matching `allowedRepos` or `allowedOrgs` are permitted
- If user tries to publish to unauthorized repo: "This repository isn't in your organization's allowed list. Contact your admin to add it."
- All publishes are logged to both local audit log and webhook (if configured)

### Enterprise Deployment

Admins can deploy the policy file via:
- Configuration management (Puppet, Chef, Ansible)
- MDM profiles
- Login scripts

---

## Configuration Resolution

When determining which repo to use:

```
1. Check command arguments
   User: /pages --repo myorg/specific-repo
   → Use myorg/specific-repo

2. Check project config
   .claude/pages.json exists with "repo" field?
   → Use project repo

3. Check enterprise policy
   ~/.claude/pages-policy.json exists with "allowedRepos"?
   → Present allowed repos as options

4. Check user default
   ~/.claude/pages-config.json exists with "defaultRepo"?
   → Offer default: "Publish to username/my-site? Or specify different repo"

5. Prompt interactively
   → "Which repository should I publish to? (format: owner/repo)"
```

---

## Commands

### View Current Config

```
User: /pages config

Claude: Current configuration:

        Project (.claude/pages.json):
          repo: myorg/project-docs
          branch: gh-pages

        User default (~/.claude/pages-config.json):
          defaultRepo: username/my-site
          autoPreview: true

        Enterprise policy: Not configured
```

### Set Project Repo

```
User: /pages set-repo myorg/new-repo

Claude: Updated .claude/pages.json:
        repo: myorg/new-repo

        Future publishes from this project will use myorg/new-repo.
```

### Set User Default

```
User: /pages set-default myorg/my-site

Claude: Updated ~/.claude/pages-config.json:
        defaultRepo: myorg/my-site
```

### Clear Config

```
User: /pages clear-config

Claude: Which config should I clear?
        1. Project config (.claude/pages.json)
        2. User default (~/.claude/pages-config.json)
        3. Both
```

---

## Validation

Before publishing, validate the repo:

```bash
# Check repo exists and user has access
gh repo view <owner/repo> --json name,visibility 2>/dev/null

# If enterprise policy exists, verify repo is allowed
if policy.allowedRepos exists:
  assert repo in policy.allowedRepos OR
         repo.org in policy.allowedOrgs
```

Error messages:

- **Repo not found**: "I couldn't find `owner/repo`. Check the name and your access permissions."
- **Policy violation**: "Publishing to `owner/repo` isn't allowed by your organization's policy. Allowed repos: [list]"
- **No write access**: "You don't have write access to `owner/repo`. Request access or choose a different repo."
