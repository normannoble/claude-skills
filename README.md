# GitHub Pages Publisher

A Claude Code skill that enables non-technical users to generate static web content and publish it to GitHub Pages.

## Features

- **Conversation → Pages**: Transform any Claude Code conversation into a published website
- **Fresh Creation**: Build landing pages, documentation, or blog posts from scratch
- **Local Preview**: Auto-opens preview in your browser before publishing
- **Multi-page Support**: Generate full sites with navigation
- **Self-contained**: All CSS/JS inlined, images embedded as base64
- **Enterprise Ready**: Audit logging, works with enterprise GitHub

## Prerequisites

- [Claude Code](https://github.com/anthropics/claude-code) installed
- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated
- An existing GitHub repository with Pages enabled

## Installation

### 1. Install the Skill

Copy the `pages` folder to your Claude Code skills directory (exclude `.git` to avoid permission errors):

```bash
rsync -av --exclude='.git' pages ~/.claude/skills/
```

Or create a symlink (recommended for development):

```bash
mkdir -p ~/.claude/skills
ln -sf /path/to/pages ~/.claude/skills/pages
```

### 2. Configure Claude Code Permissions

For smooth operation without repeated permission prompts, add these to your `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Read(~/.claude/*)",
      "Bash(rm -rf /tmp/*)",
      "Bash(gh *)",
      "Bash(git *)",
      "Bash(open *)",
      "Bash(mkdir *)",
      "Bash(cp *)"
    ]
  }
}
```

If you already have a settings file, merge the `allow` array with your existing permissions.

### 3. Configure Default Repositories

Create `~/.claude/pages-config.json` to set your publishing destinations:

```json
{
  "defaultPublicRepo": "username/my-public-site",
  "defaultPrivateRepo": "myorg/internal-docs"
}
```

With both configured, Claude will only offer these two options when publishing:
```
Who should be able to see this page?

1. Everyone on the internet
2. Only people in your organization
```

If you only set one (public or private), that repo is used automatically without prompting.

### 4. Verify

The skill will be available in Claude Code as `/pages`

## Usage

### Publish from a Conversation

Have any conversation with Claude, then:

```
/pages
```

Claude will analyze your conversation, identify publishable topics, and guide you through:
1. Selecting which topics to include
2. Choosing structure (single or multi-page)
3. Previewing in your browser
4. Publishing to your GitHub repository

### Create Fresh Content

```
/pages
```

When there's no prior conversation, Claude will ask what you want to create:
- Landing page
- Documentation
- Blog post
- Custom content

### Update an Existing Site

Simply tell Claude what to update:

```
Update the pricing section on my landing page
```

Claude will find your previously published site and guide you through changes.

## Examples

### Example 1: Strategy → Website

```
You: Let's discuss our product launch strategy

[Extended conversation about product, features, target market, etc.]

You: /pages

Claude: I identified these topics from our conversation:
        1. Product Overview
        2. Key Features
        3. Target Market
        4. Launch Timeline

        Which should I include?
```

### Example 2: Quick Landing Page

```
You: /pages

Claude: What would you like to create?

You: A landing page for my consulting business

Claude: What's your business name and main service?

[Claude guides you through content, generates preview]

Claude: What should I name this site's folder?
        Suggested: "consulting-services"

        Published URL: https://you.github.io/my-site/consulting-services/

You: Call it "acme-consulting"

Claude: Published! View at: https://you.github.io/my-site/acme-consulting/
```

### Repo Structure

Each conversation becomes a folder in your repo:

```
your-repo (gh-pages branch)/
├── product-launch-2026/
│   ├── index.html
│   └── features.html
├── acme-consulting/
│   └── index.html
├── quarterly-review/
│   └── index.html
└── index.html  (auto-generated listing of all sites)
```

## Configuration

### Repository Resolution Order

The skill checks for repo settings in this order:

1. **Command argument**: `/pages --repo myorg/repo`
2. **Project config**: `.claude/pages.json` in your project
3. **Enterprise policy**: `~/.claude/pages-policy.json` (admin-managed)
4. **User default**: `~/.claude/pages-config.json` (see Installation step 3)
5. **Interactive prompt**: Only if no config exists

#### Set Project Repo

Lock a project to a specific repo:

```
/pages set-repo myorg/project-docs
```

Creates `.claude/pages.json`:
```json
{
  "repo": "myorg/project-docs",
  "branch": "gh-pages"
}
```

#### Set Personal Defaults via Command

Alternative to manually editing `~/.claude/pages-config.json`:

```
/pages set-default --public username/my-site --private myorg/internal-docs
```

#### Enterprise Policy (Admin)

Admins can restrict allowed repos via `~/.claude/pages-policy.json`:
```json
{
  "allowedRepos": ["myorg/docs", "myorg/site"],
  "allowedOrgs": ["myorg"]
}
```

#### View Configuration

```
/pages config
```

### GitHub Authentication

Ensure you're authenticated with the GitHub CLI:

```bash
gh auth login
```

For enterprise GitHub:

```bash
gh auth login --hostname your-enterprise-host.com
```

### Enable GitHub Pages

1. Go to your repository Settings
2. Navigate to Pages
3. Set Source to "Deploy from a branch"
4. Select the `gh-pages` branch

## File Structure

```
pages/
├── skill.md              # Main skill definition
├── lib/
│   ├── generator.md      # Content generation patterns
│   ├── publisher.md      # Publishing workflow
│   ├── preview.md        # Local preview handling
│   └── config.md         # Repository configuration system
├── templates/
│   ├── landing-page.html
│   ├── documentation.html
│   └── blog-post.html
└── README.md
```

## Data Files

The skill creates these files to track state:

- `~/.claude/github-pages-sites.json` - Tracks published sites
- `~/.claude/github-pages-audit.log` - Audit log of all publish actions

## Troubleshooting

### Repeated permission prompts

If Claude keeps asking for permission to run commands, ensure you've configured `~/.claude/settings.json` as described in Installation step 2. Changes take effect in new sessions.

### "gh: not logged in"

Run `gh auth login` and follow the prompts.

### "Repository not found"

Verify the repository name (format: `owner/repo`) and that you have access.

### "Push rejected"

The remote has changes you don't have. Claude will offer to pull and merge or force push.

### "Pages not enabled"

Go to repository Settings → Pages and enable GitHub Pages with the gh-pages branch.

### Permission denied when copying skill

If you get permission errors when copying with `cp -r`, use rsync instead:
```bash
rsync -av --exclude='.git' pages ~/.claude/skills/
```

## License

MIT
