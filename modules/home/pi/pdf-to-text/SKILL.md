---
name: pdf-to-text
description: Extract text from PDF files using Poppler pdftotext. Use when you need to read, search, or analyze PDF content.
---

# PDF Text Extraction

Extract plain text from PDF files with Poppler's `pdftotext`.

The house invocation preserves layout, suppresses page breaks, and writes to
stdout:

```bash
pdftotext -layout -nopgbrk <input.pdf> -
```

The trailing `-` is stdout; drop it to write `<input>.txt` beside the PDF.
`-f N`/`-l N` bound the page range, `-raw` keeps content-stream order for
column-heavy layouts where `-layout` misorders the text, and `-upw <pass>` opens
an encrypted PDF. `pdftotext -h` has the rest.
