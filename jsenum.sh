#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Define output files
LIVE_FILE="live.txt"
JS_LINKS="jslinks.txt"
JS_LIVE="jslive.txt"
NUCLEI_OUT="js_bugs.txt"
LINKFINDER_OUT="endpoints_linkfinder.txt"
SECRETFINDER_OUT="endpoints_secretfinder.txt"
MANTRA_OUT="Mantra.txt"
JSLEAK_OUT="jsleaks_output.txt"

echo -e "${BLUE}[+] Collecting JS files from various sources...${NC}"
> "$JS_LINKS"

echo -e "${YELLOW}[-] gau${NC}"
cat "$LIVE_FILE" | gau | grep "\.js" | tee -a "$JS_LINKS"

echo -e "${YELLOW}[-] waybackurls${NC}"
cat "$LIVE_FILE" | waybackurls | grep "\.js" | tee -a "$JS_LINKS"

echo -e "${YELLOW}[-] subjs${NC}"
cat "$LIVE_FILE" | subjs | tee -a "$JS_LINKS"

echo -e "${YELLOW}[-] katana${NC}"
cat "$LIVE_FILE" | katana -jc | grep "\.js" | tee -a "$JS_LINKS"

echo -e "${GREEN}[✓] Deduplicating JS links...${NC}"
sort -u "$JS_LINKS" -o "$JS_LINKS"

echo -e "${BLUE}[+] Checking live JS links with httpx...${NC}"
cat "$JS_LINKS" | httpx -silent > "$JS_LIVE"

# Analysis phase
echo -e "${BLUE}\n============================="
echo -e "[+] Running Nuclei on JS links"
echo -e "=============================${NC}"
nuclei -l "$JS_LINKS" -t ~/.local/nuclei-templates/http/exposures/ -o "$NUCLEI_OUT"

echo -e "${BLUE}\n==============================="
echo -e "[+] Running LinkFinder on JS files"
echo -e "===============================${NC}"
cat "$JS_LINKS" | while read -r url; do
    echo -e "${YELLOW}[*] Scanning $url${NC}"
    python3 /home/tools/LinkFinder/linkfinder.py -i "$url" -o cli
done | tee "$LINKFINDER_OUT"

echo -e "${BLUE}\n==========================="
echo -e "[+] Running Mantra on JS files"
echo -e "===========================${NC}"
cat "$JS_LINKS" | mantra | tee "$MANTRA_OUT"

echo -e "${BLUE}\n==============================="
echo -e "[+] Running SecretFinder on JS files"
echo -e "===============================${NC}"
cat "$JS_LINKS" | while read -r url; do
    echo -e "${YELLOW}[*] Scanning $url${NC}"
    python3 /home/tools/secretfinder/SecretFinder.py -i "$url" -o cli
done | tee "$SECRETFINDER_OUT"

echo -e "${BLUE}\n==========================="
echo -e "[+] Running jsleak on live.txt"
echo -e "===========================${NC}"
cat "$LIVE_FILE" | jsleak -l -s | sort -u | tee "$JSLEAK_OUT"

echo -e "${GREEN}\n[✓] All tasks completed successfully!${NC}"
echo -e "${YELLOW}Results saved in:
 - JS Links: ${JS_LINKS}
 - Live JS: ${JS_LIVE}
 - Nuclei: ${NUCLEI_OUT}
 - LinkFinder: ${LINKFINDER_OUT}
 - SecretFinder: ${SECRETFINDER_OUT}
 - Mantra: ${MANTRA_OUT}
 - jsleak: ${JSLEAK_OUT}${NC}"
