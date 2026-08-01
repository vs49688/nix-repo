---
name: pdf-to-text
description: Extract text from PDF files using Poppler pdftotext. Use when you need to read, search, or analyze PDF content.
---

# PDF Text Extraction

Extract plain text from PDF files using Poppler `pdftotext`.

## Default Usage

The default invocation preserves layout, suppresses page breaks, and writes to stdout:

```bash
pdftotext -layout -nopgbrk <input.pdf> -
```

The trailing `-` sends output to stdout. Omit it to write to a `.txt` file alongside the PDF:

```bash
pdftotext -layout -nopgbrk <input.pdf>
# writes <input.txt>
```

## Useful Options

| Option | Purpose |
|--------|---------|
| `-f N` | First page to convert |
| `-l N` | Last page to convert |
| `-raw` | Keep strings in content stream order (use for column-heavy layouts where `-layout` misorders text) |
| `-htmlmeta` | Generate HTML with metadata instead of plain text |
| `-upw <pass>` | Password for encrypted PDFs (user) |
| `-opw <pass>` | Password for encrypted PDFs (owner) |
| `-q` | Suppress errors/messages |

## Extracting a Page Range

```bash
pdftotext -layout -nopgbrk -f 5 -l 10 <input.pdf> -
```

## Column-Heavy Layouts

If `-layout` produces text in the wrong order (common with multi-column PDFs), try `-raw`:

```bash
pdftotext -raw -nopgbrk <input.pdf> -
```

## Encrypted PDFs

```bash
pdftotext -layout -nopgbrk -upw <password> <input.pdf> -
```
