# /pages

Publish static web content to GitHub Pages. Transform conversations into websites or create fresh content.

## User-invocable

## Description

This skill helps non-technical users publish static websites to GitHub Pages. It supports two primary workflows:

1. **Conversation → Pages**: Extract and publish content from your current conversation
2. **Create Fresh**: Build new content from scratch

## Workflow

When the user invokes `/pages`, follow this process:

### Step 1: Detect Context

Check if there's substantial prior conversation (more than a few exchanges). If yes, offer to extract content from it. If no (or minimal conversation), proceed to fresh creation.

### Step 2A: Conversation Extraction (if prior conversation exists)

1. **Analyze the conversation** to identify distinct, publishable topics
2. **Present topics to user** as a numbered list with brief descriptions
3. **Ask which topics to include** (guided extraction - don't auto-decide)
4. **Ask about structure**: Single page with sections, or multi-page site with navigation?
5. **Ask about styling preferences**: Minimal/clean, professional/corporate, or colorful/modern?

### Step 2B: Fresh Creation (if no prior conversation)

1. **Ask what they want to create**:
   - Landing page
   - Documentation
   - Blog post
   - Something custom
2. **Gather content through conversation**
3. **Ask about structure and styling** (same as 2A)

### Step 3: Generate Content

Generate self-contained HTML/CSS/JS with these requirements:

- **Inline all CSS** in `<style>` tags (no external stylesheets)
- **Inline all JS** in `<script>` tags (no external scripts)
- **Embed images as base64** data URIs when provided
- **Use semantic HTML5** elements (header, nav, main, article, section, footer)
- **Include responsive design** with mobile-first approach
- **Add meta tags** for SEO and social sharing

For multi-page sites:
- Create an `index.html` as the main entry point
- Create additional HTML files for each page
- Include consistent navigation across all pages
- Use relative links between pages

### Step 4: Local Preview

Before publishing, show the user a preview:

1. Write the generated HTML file(s) to a temporary location
2. Auto-open the main page in the user's default browser:
   - macOS: `open <filepath>`
   - Linux: `xdg-open <filepath>`
   - Windows: `start <filepath>`
3. Ask the user if they want to:
   - Publish as-is
   - Make changes (iterate on the content)
   - Cancel

### Step 5: Publish to GitHub Pages

1. **Verify gh CLI authentication**:
   ```bash
   gh auth status
   ```
   If not authenticated, guide user through `gh auth login`

2. **Determine target repository** (see lib/config.md for details):

   Resolution order:
   - Command argument: `/pages --repo owner/repo`
   - Project config: `.claude/pages.json` in current directory
   - Enterprise policy: `~/.claude/pages-policy.json` (if exists, only allowed repos)
   - User default: `~/.claude/pages-config.json`
   - Interactive prompt: Ask user for `owner/repo`

   If enterprise policy exists, validate repo is in allowed list before proceeding.

3. **Determine folder name**:

   Each conversation is published to its own folder within the repo. Ask the user for a name or suggest one based on the content:

   ```
   Claude: What should I name this site's folder?
           Suggested: "product-strategy-2026" (based on our discussion)

           This will be published to: https://owner.github.io/repo/product-strategy-2026/
   ```

   Folder naming rules:
   - Lowercase, hyphenated (e.g., `quarterly-review-q1`)
   - No spaces or special characters
   - Must not already exist in the repo

4. **Clone and prepare**:
   ```bash
   gh repo clone <owner/repo> <temp-dir>
   cd <temp-dir>

   # Use gh for git credentials (avoids OAuth app conflicts with SAML)
   git config --local credential.helper '!gh auth git-credential'

   git checkout gh-pages || git checkout --orphan gh-pages

   # Check folder doesn't exist
   if [ -d "<folder-name>" ]; then
     echo "Folder already exists"
     # Ask user for different name or to update existing
   fi

   mkdir -p <folder-name>
   ```

5. **Copy generated files** to the folder:
   ```bash
   cp -r <generated-files>/* <folder-name>/
   ```

6. **Commit and push**:
   ```bash
   git add <folder-name>/
   git commit -m "Published '<folder-name>' via /pages skill"
   git push -u origin gh-pages
   ```

7. **Update repo index** (optional):

   Generate/update a root `index.html` that lists all published sites in the repo:

   ```html
   <h1>Published Sites</h1>
   <ul>
     <li><a href="product-strategy-2026/">Product Strategy 2026</a></li>
     <li><a href="quarterly-review/">Quarterly Review</a></li>
   </ul>
   ```

   Ask user: "Should I update the repo's index page to include this site?"

8. **Return the published URL**: `https://<owner>.github.io/<repo>/<folder-name>/`

### Step 6: Log and Confirm

1. Append to audit log at `~/.claude/github-pages-audit.log`:
   ```
   <timestamp> | PUBLISH | <repo> | "<page title>" | success
   ```

2. Confirm to user with:
   - Published URL
   - What was published
   - How to update in the future

## Error Handling

Handle these errors gracefully with guided remediation:

| Error | Response |
|-------|----------|
| `gh` not installed | "GitHub CLI (gh) is required. Install it from https://cli.github.com/" |
| `gh` not authenticated | "Let's authenticate with GitHub. Run: `gh auth login`" |
| Repository not found | "I couldn't find that repository. Please verify the name (format: owner/repo) and that you have access." |
| Push rejected | "The push was rejected. This usually means there are remote changes. Would you like me to pull and merge, or force push?" |
| Pages not enabled | "GitHub Pages isn't enabled for this repo. Go to Settings → Pages and select the gh-pages branch as the source." |
| Enterprise SSO required | "This repo requires SSO authentication. Run: `gh auth login --hostname <enterprise-host>`" |
| SAML SSO blocking clone | "Visit the authorization URL in the error, then run: `gh auth refresh -h github.com -s repo,read:org`" |
| Push blocked by OAuth app | Use `git config --local credential.helper '!gh auth git-credential'` then retry push |
| Private repo, no Pages | "This repo is private. Make it public with: `gh repo edit owner/repo --visibility public --accept-visibility-change-consequences`" |

## Iterative Updates

When updating an existing site:

1. Check `~/.claude/github-pages-sites.json` for tracked sites
2. If user mentions a known site, offer to update it
3. Show current content and ask what to change
4. Follow the same preview → publish flow

## Templates

Use these as starting points when appropriate:

### Minimal Landing Page
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{title}}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: system-ui, -apple-system, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 800px; margin: 0 auto; padding: 2rem; }
        header { text-align: center; padding: 4rem 0; }
        h1 { font-size: 2.5rem; margin-bottom: 1rem; }
        .subtitle { font-size: 1.25rem; color: #666; }
        section { padding: 2rem 0; }
        h2 { margin-bottom: 1rem; }
        @media (max-width: 600px) {
            .container { padding: 1rem; }
            h1 { font-size: 2rem; }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>{{title}}</h1>
            <p class="subtitle">{{subtitle}}</p>
        </header>
        <main>
            {{content}}
        </main>
    </div>
</body>
</html>
```

### Multi-page Navigation
```html
<nav style="background: #f5f5f5; padding: 1rem;">
    <div class="container" style="display: flex; gap: 1rem;">
        <a href="index.html">Home</a>
        <a href="{{page1}}.html">{{Page 1}}</a>
        <a href="{{page2}}.html">{{Page 2}}</a>
    </div>
</nav>
```

## Subcommands

The skill supports these subcommands for configuration:

### `/pages config`
Show current configuration (project, user, enterprise).

### `/pages set-repo <owner/repo>`
Set the repo for the current project. Creates `.claude/pages.json`.

### `/pages set-default`
Set your personal default repos. Updates `~/.claude/pages-config.json`.

Options:
- `--public <owner/repo>` - Default for public pages
- `--private <owner/repo>` - Default for private pages

Examples:
- `/pages set-default --public user/site` - Set public default only
- `/pages set-default --private org/internal` - Set private default only
- `/pages set-default --public user/site --private org/internal` - Set both

### `/pages clear-config`
Clear project and/or user configuration.

### `/pages --repo <owner/repo>`
Publish to a specific repo (one-time override).

---

## Notes

- Always generate self-contained HTML - no external dependencies
- Embed images as base64 to keep everything in one file
- Use modern, accessible HTML5 patterns
- Ensure responsive design works on mobile
- Keep the user informed at each step
- Ask before making assumptions about content or style
