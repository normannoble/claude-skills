#!/bin/bash
#
# Pages Skill Installer
# Installs the GitHub Pages Publisher skill for Claude Code
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
CONFIG_FILE="$CLAUDE_DIR/pages-config.json"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   GitHub Pages Skill Installer         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check for gh CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}✗ GitHub CLI (gh) not found${NC}"
    echo "  Install from: https://cli.github.com/"
    exit 1
fi
echo -e "${GREEN}✓ GitHub CLI found${NC}"

# Check gh auth status
if ! gh auth status &> /dev/null 2>&1; then
    echo -e "${YELLOW}! GitHub CLI not authenticated${NC}"
    echo "  Run 'gh auth login' after installation"
else
    echo -e "${GREEN}✓ GitHub CLI authenticated${NC}"
fi

# Create directories
echo
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p "$SKILLS_DIR"
echo -e "${GREEN}✓ Skills directory ready: $SKILLS_DIR${NC}"

# Copy skill files
echo
echo -e "${YELLOW}Installing skill files...${NC}"
if [ -d "$SKILLS_DIR/pages" ]; then
    echo -e "${YELLOW}  Existing installation found, updating...${NC}"
    rm -rf "$SKILLS_DIR/pages"
fi
rsync -av --exclude='.git' --exclude='.DS_Store' "$SCRIPT_DIR/" "$SKILLS_DIR/pages/" > /dev/null
echo -e "${GREEN}✓ Skill installed to $SKILLS_DIR/pages${NC}"

# Configure permissions
echo
echo -e "${YELLOW}Configuring permissions...${NC}"

PERMISSIONS='["Read(~/.claude/*)", "Bash(rm -rf /tmp/*)", "Bash(gh *)", "Bash(git *)", "Bash(open *)", "Bash(mkdir *)", "Bash(cp *)"]'

if [ -f "$SETTINGS_FILE" ]; then
    # Settings file exists - merge permissions
    if command -v jq &> /dev/null; then
        # Use jq if available for proper JSON merging
        EXISTING=$(cat "$SETTINGS_FILE")

        # Check if permissions.allow already exists
        if echo "$EXISTING" | jq -e '.permissions.allow' > /dev/null 2>&1; then
            # Merge with existing permissions
            MERGED=$(echo "$EXISTING" | jq --argjson new "$PERMISSIONS" '
                .permissions.allow = (.permissions.allow + $new | unique)
            ')
            echo "$MERGED" > "$SETTINGS_FILE"
            echo -e "${GREEN}✓ Merged permissions with existing settings${NC}"
        else
            # Add permissions section
            MERGED=$(echo "$EXISTING" | jq --argjson new "$PERMISSIONS" '
                .permissions = (.permissions // {}) | .permissions.allow = $new
            ')
            echo "$MERGED" > "$SETTINGS_FILE"
            echo -e "${GREEN}✓ Added permissions to existing settings${NC}"
        fi
    else
        echo -e "${YELLOW}! jq not found - cannot auto-merge permissions${NC}"
        echo "  Please manually add these permissions to $SETTINGS_FILE:"
        echo '  "permissions": { "allow": '$PERMISSIONS' }'
    fi
else
    # Create new settings file
    cat > "$SETTINGS_FILE" << EOF
{
  "permissions": {
    "allow": $PERMISSIONS
  }
}
EOF
    echo -e "${GREEN}✓ Created settings file with permissions${NC}"
fi

# Configure default repositories (optional)
echo
echo -e "${YELLOW}Repository Configuration${NC}"
echo "The skill needs GitHub repositories with Pages enabled."
echo

if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}✓ Existing configuration found at $CONFIG_FILE${NC}"
    if command -v jq &> /dev/null; then
        echo "  Current settings:"
        jq -r '  if .defaultPublicRepo then "  Public repo:  \(.defaultPublicRepo)" else empty end,
                 if .defaultPrivateRepo then "  Private repo: \(.defaultPrivateRepo)" else empty end' "$CONFIG_FILE" 2>/dev/null || true
    fi
    echo
    read -p "Would you like to reconfigure? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        SKIP_CONFIG=true
    fi
fi

if [ "$SKIP_CONFIG" != "true" ]; then
    echo "Enter repository names in 'owner/repo' format, or press Enter to skip."
    echo

    read -p "Public repository (visible to everyone): " PUBLIC_REPO
    read -p "Private/org repository (visible to org members): " PRIVATE_REPO

    if [ -n "$PUBLIC_REPO" ] || [ -n "$PRIVATE_REPO" ]; then
        CONFIG="{"
        FIRST=true

        if [ -n "$PUBLIC_REPO" ]; then
            CONFIG="$CONFIG\"defaultPublicRepo\": \"$PUBLIC_REPO\""
            FIRST=false
        fi

        if [ -n "$PRIVATE_REPO" ]; then
            if [ "$FIRST" = false ]; then
                CONFIG="$CONFIG, "
            fi
            CONFIG="$CONFIG\"defaultPrivateRepo\": \"$PRIVATE_REPO\""
        fi

        CONFIG="$CONFIG}"

        echo "$CONFIG" > "$CONFIG_FILE"

        # Pretty print if jq is available
        if command -v jq &> /dev/null; then
            jq '.' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        fi

        echo -e "${GREEN}✓ Saved repository configuration${NC}"
    else
        echo -e "${YELLOW}  Skipped repository configuration${NC}"
        echo "  You can configure later with: /pages set-default"
    fi
fi

# Summary
echo
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo
echo "The skill is now available as ${BLUE}/pages${NC} in Claude Code."
echo
echo "Quick start:"
echo "  1. Start a new Claude Code session"
echo "  2. Type ${BLUE}/pages${NC} to create or publish content"
echo
echo "For more information, see:"
echo "  $SKILLS_DIR/pages/README.md"
echo
