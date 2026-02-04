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

1. Copy the `github-pages-publisher` folder to your Claude Code skills directory:

```bash
cp -r github-pages-publisher ~/.claude/skills/
```

Or create a symlink:

```bash
ln -s /path/to/github-pages-publisher ~/.claude/skills/github-pages-publisher
```

2. The skill will be available in Claude Code as `/pages`

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

### Repository Configuration

The skill checks for repo settings in this order:

1. **Command argument**: `/pages --repo myorg/repo`
2. **Project config**: `.claude/pages.json` in your project
3. **Enterprise policy**: `~/.claude/pages-policy.json` (admin-managed)
4. **User default**: `~/.claude/pages-config.json`
5. **Interactive prompt**: Asked during publish

#### Set Project Repo

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

#### Set Personal Defaults

Set separate defaults for public and private pages:

```
/pages set-default --public username/my-site --private myorg/internal-docs
```

Creates `~/.claude/pages-config.json`:
```json
{
  "defaultPublicRepo": "username/my-site",
  "defaultPrivateRepo": "myorg/internal-docs"
}
```

When publishing, Claude will ask which visibility you want:
```
Should this be public or private?
1. Public (username/my-site) - Anyone can view
2. Private (myorg/internal-docs) - Only org members can view
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
github-pages-publisher/
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

### "gh: not logged in"

Run `gh auth login` and follow the prompts.

### "Repository not found"

Verify the repository name (format: `owner/repo`) and that you have access.

### "Push rejected"

The remote has changes you don't have. Claude will offer to pull and merge or force push.

### "Pages not enabled"

Go to repository Settings → Pages and enable GitHub Pages with the gh-pages branch.

## License

MIT
