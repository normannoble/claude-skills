# Content Generation Patterns

## Conversation Analysis

When analyzing a conversation for publishable content, look for:

### Topic Indicators
- **Explicit statements**: "Our product does X", "The goal is Y"
- **Structured lists**: Features, benefits, steps, requirements
- **Key decisions**: "We decided to...", "The approach is..."
- **Summaries**: "In summary...", "The main points are..."
- **Questions answered**: Explanations, definitions, clarifications

### Topic Categories
Classify identified topics into these categories:

1. **Overview/Vision** - Mission statements, goals, purpose
2. **Features/Capabilities** - What something does
3. **Process/Workflow** - How something works, steps
4. **Technical Details** - Specifications, architecture, implementation
5. **Comparison/Positioning** - vs competitors, alternatives
6. **Timeline/Roadmap** - Phases, milestones, dates
7. **Team/About** - People, organization, history
8. **FAQ/Support** - Common questions, help content

### Extraction Prompt

When presenting topics to the user, format as:

```
From our conversation, I identified these publishable topics:

1. **[Topic Name]** - [One sentence description]
   Key points: [2-3 bullet points of what would be included]

2. **[Topic Name]** - [One sentence description]
   Key points: [2-3 bullet points]

[etc.]

Which topics should I include? You can:
- List numbers (e.g., "1, 3, 4")
- Say "all" or "all except X"
- Ask me to combine topics
- Request different organization
```

## Content Generation Guidelines

### Writing Style
- **Clear and direct**: Avoid jargon unless the source used it
- **Active voice**: "The system processes..." not "Data is processed by..."
- **Consistent tone**: Match the formality of the original conversation
- **Scannable**: Use headers, bullets, and short paragraphs

### HTML Structure

For single-page sites:
```html
<header>
  <h1>Main Title</h1>
  <p class="subtitle">Tagline or description</p>
</header>

<main>
  <section id="topic-1">
    <h2>Topic 1 Heading</h2>
    <p>Content...</p>
  </section>

  <section id="topic-2">
    <h2>Topic 2 Heading</h2>
    <p>Content...</p>
  </section>
</main>

<footer>
  <p>Footer content</p>
</footer>
```

For multi-page sites:
- `index.html` - Overview/home page with links to other pages
- `[topic].html` - One page per major topic
- Consistent `<nav>` element on all pages
- Breadcrumbs or clear navigation back to index

### CSS Patterns

#### Minimal/Clean
```css
:root {
  --primary: #333;
  --secondary: #666;
  --bg: #fff;
  --accent: #0066cc;
}
body {
  font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
  line-height: 1.6;
  color: var(--primary);
  background: var(--bg);
}
```

#### Professional/Corporate
```css
:root {
  --primary: #1a1a2e;
  --secondary: #4a4a68;
  --bg: #f8f9fa;
  --accent: #0d47a1;
}
body {
  font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
  line-height: 1.7;
}
```

#### Colorful/Modern
```css
:root {
  --primary: #2d3436;
  --secondary: #636e72;
  --bg: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  --accent: #00cec9;
}
body {
  font-family: 'Inter', system-ui, sans-serif;
  line-height: 1.6;
}
```

## Asset Handling

### Image Embedding
When the user provides an image path, convert to base64:

```bash
base64 -i <image-path>
```

Then embed as:
```html
<img src="data:image/png;base64,<base64-data>" alt="Description">
```

Supported formats:
- PNG: `data:image/png;base64,...`
- JPEG: `data:image/jpeg;base64,...`
- GIF: `data:image/gif;base64,...`
- SVG: `data:image/svg+xml;base64,...` (or inline directly)
- WebP: `data:image/webp;base64,...`

### SVG Icons
For common icons, use inline SVG rather than external resources:

```html
<!-- Checkmark -->
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
  <polyline points="20 6 9 17 4 12"></polyline>
</svg>

<!-- Arrow right -->
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
  <line x1="5" y1="12" x2="19" y2="12"></line>
  <polyline points="12 5 19 12 12 19"></polyline>
</svg>
```

## Multi-page Navigation

### Navigation Component
```html
<nav class="site-nav">
  <div class="nav-container">
    <a href="index.html" class="nav-brand">Site Name</a>
    <div class="nav-links">
      <a href="index.html" class="nav-link">Home</a>
      <a href="features.html" class="nav-link">Features</a>
      <a href="about.html" class="nav-link">About</a>
    </div>
  </div>
</nav>

<style>
.site-nav {
  background: #fff;
  border-bottom: 1px solid #eee;
  padding: 1rem 0;
  position: sticky;
  top: 0;
}
.nav-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.nav-brand {
  font-weight: 600;
  font-size: 1.25rem;
  color: #333;
  text-decoration: none;
}
.nav-links {
  display: flex;
  gap: 1.5rem;
}
.nav-link {
  color: #666;
  text-decoration: none;
  transition: color 0.2s;
}
.nav-link:hover {
  color: #333;
}
@media (max-width: 600px) {
  .nav-container {
    flex-direction: column;
    gap: 1rem;
  }
}
</style>
```

## Content Quality Checklist

Before presenting to user, verify:

- [ ] All content is from the conversation (no hallucinated details)
- [ ] Links between pages work (relative paths)
- [ ] CSS is complete and inline
- [ ] Responsive breakpoints included
- [ ] Semantic HTML elements used
- [ ] Alt text on images
- [ ] Page title and meta description set
- [ ] No external dependencies
