# How to Convert PRESENTATION.md to PDF

I've created a comprehensive 85-slide presentation in `PRESENTATION.md` that explains the entire project for beginners. Here's how to convert it to PDF:

## Option 1: Using Marp CLI (Recommended)

### Install Marp CLI

```bash
npm install -g @marp-team/marp-cli
```

### Convert to PDF

```bash
marp PRESENTATION.md --pdf --allow-local-files
```

This creates `PRESENTATION.pdf` in the same directory.

### With Custom Theme (Optional)

```bash
marp PRESENTATION.md --pdf --theme-set custom-theme.css --allow-local-files
```

---

## Option 2: Using Marp for VS Code

### Install Extension

1. Open VS Code
2. Go to Extensions (Cmd+Shift+X or Ctrl+Shift+X)
3. Search for "Marp for VS Code"
4. Install it

### Export to PDF

1. Open `PRESENTATION.md` in VS Code
2. Click the Marp icon in the toolbar
3. Click "Export slide deck..."
4. Choose "PDF"
5. Save the file

---

## Option 3: Using Docker (No Installation Needed)

```bash
docker run --rm -v $PWD:/home/marp/app/ marpteam/marp-cli PRESENTATION.md --pdf --allow-local-files
```

This creates the PDF without installing anything on your system.

---

## Option 4: Online Converter

### Using Marp Web

1. Go to https://web.marp.app/
2. Copy the content of `PRESENTATION.md`
3. Paste it into the editor
4. Click the menu icon (☰)
5. Click "Export as PDF"

**Note:** Some formatting might be slightly different from CLI.

---

## Option 5: Using Pandoc

### Install Pandoc

```bash
# macOS
brew install pandoc

# Ubuntu/Debian
sudo apt-get install pandoc texlive-latex-base texlive-fonts-recommended

# Windows
# Download from https://pandoc.org/installing.html
```

### Convert to PDF

```bash
pandoc PRESENTATION.md -o PRESENTATION.pdf -t beamer
```

**Note:** This uses LaTeX Beamer theme, which looks different from Marp.

---

## Customizing the PDF

### Change Theme

Edit the YAML front matter in `PRESENTATION.md`:

```yaml
---
marp: true
theme: gaia  # Try: default, gaia, uncover
paginate: true
---
```

### Add Custom Styles

Create `custom.css`:

```css
/* Custom styles */
section {
  background-color: #f5f5f5;
}

h1 {
  color: #2c3e50;
}

code {
  background-color: #ecf0f1;
}
```

Then use it:

```bash
marp PRESENTATION.md --pdf --theme custom.css
```

---

## Presentation Features

The presentation includes:

✅ **85 slides** covering every aspect
✅ **6 parts** building knowledge incrementally:
   1. Core Concepts (10 slides)
   2. Setting Up (7 slides)
   3. Modules (8 slides)
   4. Remote State (4 slides)
   5. Environments (9 slides)
   6. CI/CD (10 slides)

✅ **Implementation Guide** (8 step-by-step slides)
✅ **Visual diagrams** using ASCII art
✅ **Code examples** with syntax highlighting
✅ **Best practices** (4 slides)
✅ **Troubleshooting** (3 slides)
✅ **Next steps** and resources

---

## Tips for Presenting

### For Live Presentations

```bash
# Generate HTML for browser presentation
marp PRESENTATION.md --html

# Open in browser and use arrow keys to navigate
```

### For Handouts

```bash
# Generate PDF with 2 slides per page
marp PRESENTATION.md --pdf --allow-local-files -- --pdf-notes
```

### For Printing

```bash
# High quality output
marp PRESENTATION.md --pdf --allow-local-files --pdf-outlines
```

---

## Editing the Presentation

The presentation is written in **Markdown** with Marp syntax:

- `---` separates slides
- `#` for slide titles
- Standard Markdown for content
- Code blocks with syntax highlighting
- Tables, lists, emphasis all supported

### Example Slide

```markdown
---

# My Slide Title

**Bold text** and *italic text*

- Bullet point 1
- Bullet point 2

\`\`\`bash
terraform apply
\`\`\`

---
```

---

## Quick Start Command

**The simplest way:**

```bash
# Install Marp CLI
npm install -g @marp-team/marp-cli

# Generate PDF
marp PRESENTATION.md --pdf --allow-local-files

# Done! Open PRESENTATION.pdf
```

---

## Troubleshooting

### "Command not found: marp"

**Solution:** Install Marp CLI globally:
```bash
npm install -g @marp-team/marp-cli
```

### "Command not found: npm"

**Solution:** Install Node.js first:
- Download from https://nodejs.org/
- Or use: `brew install node` (macOS)

### PDF looks different from expected

**Solution:** Use the official Marp CLI (not pandoc) for best results:
```bash
marp PRESENTATION.md --pdf --allow-local-files
```

### Images or formatting issues

**Solution:** Use `--allow-local-files` flag:
```bash
marp PRESENTATION.md --pdf --allow-local-files
```

---

## Need Help?

**Marp Documentation:**
- https://marp.app/
- https://github.com/marp-team/marp-cli

**Quick Test:**
```bash
# Test if Marp works
marp --version

# Generate HTML preview first
marp PRESENTATION.md --html

# Then generate PDF
marp PRESENTATION.md --pdf --allow-local-files
```

**Alternative:** If all else fails, use the online version at https://web.marp.app/

---

## Summary

**Recommended workflow:**

1. Install Marp CLI: `npm install -g @marp-team/marp-cli`
2. Generate PDF: `marp PRESENTATION.md --pdf --allow-local-files`
3. Open `PRESENTATION.pdf`
4. Present to your audience!

**That's it!** Your 85-slide presentation is ready to share. 🎉
