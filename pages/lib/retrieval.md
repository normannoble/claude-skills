# Page Retrieval

Enable editing of previously published pages in fresh conversations.

## User Triggers

Users might say:
- "Edit my product page"
- "Update the landing page I published last week"
- "Change the pricing on my site"
- `/pages list` - show all published pages
- `/pages edit <name>` - edit a specific page

## Retrieval Flow

### Step 1: Find the Page

Check `~/.claude/github-pages-sites.json` for tracked sites:

```bash
cat ~/.claude/github-pages-sites.json
```

If user mentions a page name, match against:
- `title` field (fuzzy match)
- `folder` field (exact or partial)
- `url` field

If multiple matches or no match:
```
Claude: I found these published pages:

        1. Product Strategy 2026
           https://yoursite.github.io/pages/product-strategy-2026/
           Last updated: January 15, 2026

        2. Team Onboarding Guide
           https://yoursite.github.io/pages/team-onboarding/
           Last updated: December 3, 2025

        Which one would you like to edit?
```

### Step 2: Fetch Content from GitHub

Once page is identified, fetch the HTML from the repo:

```bash
# Get the raw HTML content
gh api repos/<owner>/<repo>/contents/<folder>/index.html \
  --jq '.content' | base64 -d > /tmp/page-content.html
```

For multi-page sites, fetch all HTML files in the folder:

```bash
# List files in folder
gh api repos/<owner>/<repo>/contents/<folder> --jq '.[].name'

# Fetch each HTML file
for file in $(gh api repos/<owner>/<repo>/contents/<folder> --jq '.[] | select(.name | endswith(".html")) | .name'); do
  gh api "repos/<owner>/<repo>/contents/<folder>/$file" --jq '.content' | base64 -d
done
```

### Step 3: Parse and Present

Extract readable content from the HTML:
- Title from `<title>` or `<h1>`
- Main content from `<main>` or `<article>` or `<body>`
- Structure (sections, headings)

Present to user:
```
Claude: Here's your "Product Strategy 2026" page:

        **Title:** Product Strategy 2026

        **Sections:**
        1. Vision and Mission
        2. Feature Roadmap
        3. Competitive Positioning

        What would you like to change?
```

### Step 4: Apply Edits

User describes changes:
```
User: Update the roadmap section with our Q2 milestones
```

Claude:
1. Modifies the relevant section
2. Regenerates the HTML
3. Shows preview
4. Publishes update (same folder, overwrites)

## Commands

### `/pages list`

Show all tracked sites:

```
Claude: Your published pages:

        1. Product Strategy 2026 (public)
           https://yoursite.github.io/pages/product-strategy-2026/

        2. Team Onboarding (private)
           https://internal.github.io/docs/team-onboarding/

        Say "edit [name]" to make changes.
```

### `/pages edit <name>`

Open a specific page for editing:

```
/pages edit product strategy
```

### `/pages delete <name>`

Remove a published page:

```
Claude: Are you sure you want to delete "Product Strategy 2026"?
        This will remove it from https://yoursite.github.io/pages/product-strategy-2026/

        Type "yes" to confirm.
```

Then:
```bash
# Clone repo
gh repo clone <owner>/<repo> <temp-dir>
cd <temp-dir>
git checkout gh-pages

# Remove folder
rm -rf <folder-name>

# Commit and push
git add -A
git commit -m "Removed '<folder-name>' via /pages skill"
git push origin gh-pages
```

## Sync on Startup

When `/pages` is invoked, optionally sync local tracking with actual repo state:

```bash
# List all folders in gh-pages branch
gh api repos/<owner>/<repo>/contents?ref=gh-pages --jq '.[].name'
```

Compare with `~/.claude/github-pages-sites.json` and reconcile:
- Add any pages found in repo but not tracked
- Mark as "unknown" pages not published via skill
- Remove tracking for deleted pages

## Error Handling

| Error | Response |
|-------|----------|
| Page not found in tracking | "I don't have a record of that page. Paste the GitHub Pages URL and I'll try to find it." |
| Page deleted from repo | "That page seems to have been removed from GitHub. Would you like to republish it?" |
| No pages tracked | "You haven't published any pages yet. Would you like to create one?" |
| Can't fetch content | "I'm having trouble accessing that page. Let me try reconnecting to GitHub..." |

## Caching (Optional)

For faster retrieval, optionally cache page content locally:

```
~/.claude/github-pages-cache/
├── owner-repo-folder1/
│   ├── index.html
│   └── metadata.json
└── owner-repo-folder2/
    └── index.html
```

Cache metadata:
```json
{
  "fetchedAt": "2026-02-04T10:00:00Z",
  "commitSha": "abc123",
  "files": ["index.html", "features.html"]
}
```

Invalidate cache when:
- User requests fresh fetch
- Cache is older than 24 hours
- Commit SHA differs from remote
