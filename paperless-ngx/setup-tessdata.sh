#!/bin/bash
# Download Tesseract "best" trained data for German and English OCR.
# Run once before starting paperless-ngx.

set -euo pipefail

DEST="/var/paperless/tessdata"
BASE_URL="https://github.com/tesseract-ocr/tessdata_best/raw/main"

mkdir -p "$DEST"

for lang in deu eng osd; do
    echo "Downloading ${lang}.traineddata ..."
    curl -L -o "${DEST}/${lang}.traineddata" "${BASE_URL}/${lang}.traineddata"
done

echo "Done. Tessdata-best installed to ${DEST}"
