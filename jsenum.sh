#!/bin/bash

# Enhanced JavaScript Recon Script
set -euo pipefail

INPUT_FILE="live.txt"
RAW_JS="raw_jslinks.txt"
UNIQUE_JS="jslinks.txt"
LIVE_JS="jslive.txt"
NUCLEI_OUTPUT="js_bugs.txt"
SECRET_OUTPUT="js_secrets.txt"
LOG="recon.log"

# Check if dependencies are installed
required_tools=(gau waybackurls subjs katana waymore httpx nuclei python3)
for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo "[ERROR] $tool is not installed!" | tee -a "$LOG"
        exit 1
    fi
done

# Create or clear output files
> "$RAW_JS"
> "$UNIQUE_JS"
> "$LIVE_JS"
> "$NUCLEI_OUTPUT"
> "$SECRET_OUTPUT"
> "$LOG"

echo "[*] Starting JS recon process..." | tee -a "$LOG"

# 1. GAU
echo "[*] Running gau..." | tee -a "$LOG"
gau < "$INPUT_FILE" | grep -iE "\.js(\?|$)" >> "$RAW_JS"

# 2. Waybackurls
echo "[*] Running waybackurls..." | tee -a "$LOG"
waybackurls < "$INPUT_FILE" | grep -iE "\.js(\?|$)" >> "$RAW_JS"

# 3. Subjs
echo "[*] Running subjs..." | tee -a "$LOG"
subjs < "$INPUT_FILE" >> "$RAW_JS"

# 4. Katana
echo "[*] Running katana..." | tee -a "$LOG"
katana -list "$INPUT_FILE" -jc | grep -iE "\.js(\?|$)" >> "$RAW_JS"

# 5. Waymore
echo "[*] Running waymore..." | tee -a "$LOG"
waymore -i "$INPUT_FILE" -mode U | grep -iE "\.js(\?|$)" >> "$RAW_JS"

# 6. Unique JS Links
sort -u "$RAW_JS" > "$UNIQUE_JS"
echo "[*] Collected $(wc -l < "$UNIQUE_JS") unique JS links." | tee -a "$LOG"

# 7. Check for live JS files
echo "[*] Checking live JS files using httpx..." | tee -a "$LOG"
cat "$UNIQUE_JS" | httpx -silent -status-code -mc 200 | tee "$LIVE_JS"

# 8. Nuclei Scan
echo "[*] Scanning with Nuclei..." | tee -a "$LOG"
nuclei -l "$UNIQUE_JS" -t ~/nuclei-templates/http/exposures/ -o "$NUCLEI_OUTPUT"

# 9. SecretFinder
echo "[*] Running SecretFinder..." | tee -a "$LOG"
while IFS= read -r url; do
    echo "[*] Scanning $url for secrets..." | tee -a "$LOG"
    python3 /home/tools/secretfinder/SecretFinder.py -i "$url" -o cli >> "$SECRET_OUTPUT"
done < "$UNIQUE_JS"

echo "[*] JS Recon completed!" | tee -a "$LOG"
echo "[*] Results:"
echo " - Unique JS: $UNIQUE_JS"
echo " - Live JS: $LIVE_JS"
echo " - Nuclei Findings: $NUCLEI_OUTPUT"
echo " - Secrets Found: $SECRET_OUTPUT"
