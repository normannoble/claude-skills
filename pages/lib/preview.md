# Local Preview

## Overview

Before publishing, generate a local preview that the user can view in their browser. This allows them to verify the content and styling before going live.

## Preview Workflow

### Step 1: Create Preview Directory

Use a predictable location for easy cleanup:
```bash
PREVIEW_DIR="$HOME/.claude/pages-preview"
mkdir -p "$PREVIEW_DIR"
```

### Step 2: Write Generated Files

Copy all generated HTML/CSS/JS files to the preview directory:
- `index.html` - Main entry point
- Additional `.html` files for multi-page sites
- Any other assets

### Step 3: Open in Browser

Detect the operating system and use the appropriate command:

**macOS**:
```bash
open "$PREVIEW_DIR/index.html"
```

**Linux** (with xdg-utils):
```bash
xdg-open "$PREVIEW_DIR/index.html"
```

**Windows** (WSL or Git Bash):
```bash
start "$PREVIEW_DIR/index.html"
# or for WSL:
wslview "$PREVIEW_DIR/index.html"
# or:
explorer.exe "$PREVIEW_DIR/index.html"
```

**Cross-platform detection**:
```bash
case "$(uname -s)" in
  Darwin)
    open "$PREVIEW_DIR/index.html"
    ;;
  Linux)
    if command -v xdg-open &> /dev/null; then
      xdg-open "$PREVIEW_DIR/index.html"
    elif command -v wslview &> /dev/null; then
      wslview "$PREVIEW_DIR/index.html"
    else
      echo "Preview available at: file://$PREVIEW_DIR/index.html"
    fi
    ;;
  MINGW*|CYGWIN*|MSYS*)
    start "$PREVIEW_DIR/index.html"
    ;;
  *)
    echo "Preview available at: file://$PREVIEW_DIR/index.html"
    ;;
esac
```

### Step 4: Present Options

After opening the preview, ask the user:

```
I've opened a preview in your browser.

What would you like to do?
1. **Publish** - Deploy to GitHub Pages as-is
2. **Make changes** - Tell me what to adjust
3. **Cancel** - Discard and don't publish
```

## Handling User Feedback

### If user wants changes:

Ask clarifying questions:
- "What would you like to change?"
- "Any specific sections need adjustment?"
- "Should I modify the styling or content?"

Then:
1. Update the generated files
2. Refresh the preview (re-open in browser)
3. Ask again: Publish, change, or cancel?

### If user approves:

Proceed to publishing workflow.

### If user cancels:

```bash
rm -rf "$PREVIEW_DIR"
```

Confirm: "Preview discarded. Let me know if you'd like to try again."

## Multi-page Preview

For sites with multiple pages:

1. Open `index.html` as the starting point
2. Inform user about navigation:

```
I've opened the preview. Your site has these pages:
- index.html (Home) - currently viewing
- features.html (Features)
- about.html (About)

Navigate between them using the site's navigation menu.
```

3. Relative links between pages will work since they're all in the same directory

## Preview File Structure

```
~/.claude/pages-preview/
├── index.html
├── features.html
├── about.html
└── (any other generated pages)
```

## Troubleshooting

### Browser doesn't open

If the `open`/`xdg-open` command fails:

```
I couldn't automatically open your browser.

You can view the preview manually:
1. Open your browser
2. Press Cmd+O (Mac) or Ctrl+O (Windows/Linux)
3. Navigate to: ~/.claude/pages-preview/
4. Open index.html
```

Or provide the full file URL:
```
file:///Users/<username>/.claude/pages-preview/index.html
```

### Preview looks wrong

Common issues:
- **Broken images**: Base64 encoding may have failed - check image paths
- **Missing styles**: CSS may not be properly inlined
- **Navigation broken**: Check relative links between pages

### Cleanup

Always clean up preview files after:
- User publishes (success)
- User cancels
- Session ends

```bash
rm -rf "$HOME/.claude/pages-preview"
```

## Preview vs. Production Differences

Inform users that preview is a local file, while production is served via HTTP:

```
Note: You're viewing a local file preview. Some differences from the live site:
- URLs show file:// instead of https://
- Some browser features may behave differently
- The live site will have your GitHub Pages URL

These differences don't affect how the published site will look.
```
