# 🔍 JS Recon Automation Script

Automated tool to extract, analyze, and assess JavaScript files for security risks during reconnaissance or bug bounty hunting.

---

## 🚀 Features

- Extract JS URLs from live domains using:
  - `gau`
  - `waybackurls`
  - `subjs`
  - `katana`
  - `waymore`
- Deduplicate and verify live JS links with `httpx`
- Scan for known exposures using `nuclei`
- Find hardcoded secrets using `SecretFinder`
- Organized output and logs

---

## 📂 Output Files

| File              | Description                             |
|-------------------|-----------------------------------------|
| `jslinks.txt`     | Unique JS links                         |
| `jslive.txt`      | Live JS links verified via `httpx`      |
| `js_bugs.txt`     | Exposure findings from `nuclei`         |
| `js_secrets.txt`  | Secrets found using `SecretFinder`      |
| `recon.log`       | Execution log                           |

---

## ⚙️ Requirements

Install the following tools before running the script:

```bash
gau
waybackurls
subjs
katana
waymore
httpx
nuclei
python3
