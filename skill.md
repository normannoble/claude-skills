# /pages

Publish static web content to GitHub Pages. Transform conversations into websites or create fresh content.

## User-invocable

## Description

This skill helps non-technical users publish static websites to GitHub Pages. It supports two primary workflows:

1. **Conversation → Pages**: Extract and publish content from your current conversation
2. **Create Fresh**: Build new content from scratch

## Allowed Tools

```yaml
- Bash(gh auth status)
- Bash(gh auth token)
- Bash(gh repo clone *)
- Bash(gh repo view *)
- Bash(gh api *)
- Bash(git checkout *)
- Bash(git add *)
- Bash(git commit *)
- Bash(git push *)
- Bash(git remote *)
- Bash(open *)
- Bash(xdg-open *)
- Read(~/.claude/pages-config.json)
- Bash(mkdir *)
- Bash(cp *)
- Bash(rm -rf /tmp/claude-pages-*)
```

## Workflow

When the user invokes `/pages`, follow this process:

### Step 1: Detect Context

Check if there's substantial prior conversation (more than a few exchanges). If yes, offer to extract content from it. If no (or minimal conversation), proceed to fresh creation.

### Step 2A: Conversation Extraction (if prior conversation exists)

1. **Analyze the conversation** to identify distinct, publishable topics
2. **Present topics to user** as a numbered list with brief descriptions
3. **Ask which topics to include** (guided extraction - don't auto-decide)
4. **Ask about layout** (user-friendly language):
   ```
   Claude: How would you like this organized?

           1. One scrollable page (everything together, easy to share)
           2. Separate pages with a menu (better for longer content)
   ```
5. **Ask about look and feel** (user-friendly):
   ```
   Claude: What style fits best?

           1. Clean and simple
           2. Professional
           3. Modern and colorful
   ```

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

2. **Determine where to publish** (see lib/config.md for details):

   Resolution order:
   - Command argument: `/pages --repo owner/repo`
   - Project config: `.claude/pages.json` in current directory
   - Enterprise policy: `~/.claude/pages-policy.json` (if exists, only allowed repos)
   - User default: `~/.claude/pages-config.json`
   - Interactive prompt (only if no config exists)

   **IMPORTANT: Check user defaults first.** Use the Read tool to read `~/.claude/pages-config.json`. If the file doesn't exist, treat it as "no config".

   **If both `defaultPublicRepo` AND `defaultPrivateRepo` are configured:**
   Only offer these two options - do NOT list other repos or search GitHub:
   ```
   Claude: Who should be able to see this page?

           1. Everyone on the internet
           2. Only people in your organization
   ```
   Then use the corresponding repo (`defaultPublicRepo` for option 1, `defaultPrivateRepo` for option 2).

   **If only one default is configured** (either public or private):
   Use that repo automatically without asking.

   **If enterprise policy exists:**
   Validate the selected repo is in the allowed list before proceeding.

   **Only if NO config exists at all**, ask in friendly terms:
   ```
   Claude: Where would you like to publish this?

           If you have a GitHub URL, paste it here.
           Or I can list your available repositories.
   ```

   Accept any of these formats:
   - Full URL: `https://github.com/username/my-site`
   - Short form: `username/my-site`
   - Just paste from browser

3. **Ask for a title** (user-friendly):

   Don't ask for a "folder name" - ask for a title and auto-generate the URL:

   ```
   Claude: What should we call this page?
           Suggested: "Product Strategy 2026" (based on our discussion)
   ```

   After user confirms or provides a title:
   ```
   Claude: Great! Your page will be at:
           https://yoursite.github.io/pages/product-strategy-2026/
   ```

   **Behind the scenes** (don't expose to user):
   - Convert title to URL-safe slug: lowercase, replace spaces with hyphens
   - Remove special characters
   - Check for conflicts silently, append number if needed (e.g., `-2`)

4. **Clone and prepare**:

   **IMPORTANT: Run each command as a SEPARATE Bash tool call. Do NOT chain commands with `&&` or `;` - this breaks permission matching.**

   First, clean up any existing temp directory:
   ```bash
   rm -rf <temp-dir>
   ```

   Then clone:
   ```bash
   gh repo clone <owner/repo> <temp-dir>
   ```

   Then cd (or use absolute paths):

   # CRITICAL: Set remote URL with gh token to bypass other OAuth apps (VS Code, etc.)
   TOKEN=$(gh auth token)
   git remote set-url origin "https://x-access-token:${TOKEN}@github.com/<owner/repo>.git"

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

7. **Update homepage** (handle silently or ask simply):

   If user has multiple pages published, automatically maintain a homepage that lists them all.

   Only ask if this is their first publish:
   ```
   Claude: Would you like a homepage that lists all your published pages?
           (You can always add more pages later and they'll appear automatically)
   ```

   If they say yes or don't respond, create it automatically. Don't mention "index.html" or technical terms.

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

## Error Handling (User-Friendly)

**IMPORTANT**: Never show technical commands to non-technical users. Handle errors silently when possible, or explain in plain language.

| Error | User-Friendly Response |
|-------|------------------------|
| `gh` not installed | "I need to connect to GitHub but the connection tool isn't set up yet. [Open setup guide](https://cli.github.com/) - it takes about 2 minutes." |
| `gh` not authenticated | "I need to connect to your GitHub account. I'll open a browser window for you to sign in." Then run `gh auth login` automatically. |
| Repository not found | "I can't find that location. Could you paste the link from your browser when you're on the GitHub page?" |
| Push rejected | "Someone else made changes. Let me sync those first..." Then handle automatically. |
| Pages not enabled | Handle silently - enable via API. If that fails: "I need to turn on web publishing for this location. I'll open the settings page for you." |
| SAML/SSO required | "Your organization requires an extra sign-in step. I'll open the authorization page - just click Authorize when it appears." Then open the URL automatically. |
| Push blocked by OAuth | Handle silently with token-in-URL approach. User should never see this. |
| Private repo, no Pages | "This is a private location. To publish a public webpage, I'll need to make it visible. Is that okay? (Your other content stays private - only the webpage becomes public)" |

**Principle**: If Claude can fix it automatically, do so silently. Only ask the user when a decision is genuinely needed.

## Iterative Updates

Users can edit pages in fresh conversations - no need to remember details.

**Trigger phrases:**
- "Edit my product page"
- "Update the landing page"
- "Change the pricing section"
- `/pages edit <name>`
- `/pages list` then select one

**Flow (see lib/retrieval.md for details):**

1. Match user's description to tracked sites in `~/.claude/github-pages-sites.json`
2. If ambiguous, show list and ask which one
3. Fetch current HTML content from GitHub via `gh api`
4. Parse and present the page structure to user
5. User describes changes in plain language
6. Regenerate HTML with changes
7. Preview → Publish (overwrites same folder)

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

### `/pages list`
Show all your published pages:
```
Claude: Your published pages:

        1. Product Strategy 2026
           https://yoursite.github.io/pages/product-strategy-2026/
           Last updated: January 15, 2026

        2. Team Onboarding Guide
           https://yoursite.github.io/pages/team-onboarding/

        Say "edit [name]" to make changes, or "delete [name]" to remove.
```

### `/pages edit <name>`
Edit a previously published page. Fetches content from GitHub:
```
/pages edit product strategy

Claude: Here's your "Product Strategy 2026" page:

        Sections:
        1. Vision and Mission
        2. Feature Roadmap
        3. Competitive Positioning

        What would you like to change?
```

### `/pages delete <name>`
Remove a published page (asks for confirmation).

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

- **NEVER chain bash commands with `&&` or `;`** - run each as a separate Bash tool call (required for permission matching)
- Always generate self-contained HTML - no external dependencies
- Embed images as base64 to keep everything in one file
- Use modern, accessible HTML5 patterns
- Ensure responsive design works on mobile
- Keep the user informed at each step
- Ask before making assumptions about content or style
