#!/bin/bash
# =========================================================
#  Optimized Full Recon Automation Script
# =========================================================

LIVE_FILE="live.txt"
if [ ! -f "$LIVE_FILE" ]; then
    echo "[!] $LIVE_FILE not found. Please create it with your domains."
    exit 1
fi

mkdir -p results/js_results

# ================== ************** ===================== #
# ================== URL COLLECTION ===================== #
# ================== ************** ===================== #

echo "[*] Collecting URLs..."
cat "$LIVE_FILE" | gau > results/gau.txt
cat "$LIVE_FILE" | waybackurls > results/waybackurls.txt
cat "$LIVE_FILE" | katana > results/katana.txt
cat "$LIVE_FILE" | cariddi > results/cariddi.txt

cat results/*.txt | sort -u > results/Uniq_urls.txt

echo "[*] Checking live URLs..."
cat results/Uniq_urls.txt | httpx -silent > results/liveurls.txt

echo "[*] Checking Sensitive Endpoints..."
cat results/liveurls.txt | | grep -aiE "\.(zip|rar|tar|gz|config|log|bak|backup|java|old|xlsx|json|pdf|doc|docx|pptx|csv|htaccess|7z)$|(?i)(?:(?:access_key|access_token|admin_pass|admin_user|algolia_admin_key|algolia_api_key|alias_pass|alicloud_access_key|amazon_secret_access_key|amazonaws|ansible_vault_password|aos_key|api_key|api_key_secret|api_key_sid|api_secret|api.googlemaps AIza|apidocs|apikey|apiSecret|app_debug|app_id|app_key|app_log_level|app_secret|appkey|appkeysecret|application_key|appsecret|appspot|auth_token|authorizationToken|authsecret|aws_access|aws_access_key_id|aws_bucket|aws_key|aws_secret|aws_secret_key|aws_token|AWSSecretKey|b2_app_key|bashrc password|bintray_apikey|bintray_gpg_password|bintray_key|bintraykey|bluemix_api_key|bluemix_pass|browserstack_access_key|bucket_password|bucketeer_aws_access_key_id|bucketeer_aws_secret_access_key|built_branch_deploy_key|bx_password|cache_driver|cache_s3_secret_key|cattle_access_key|cattle_secret_key|certificate_password|ci_deploy_password|client_secret|client_zpk_secret_key|clojars_password|cloud_api_key|cloud_watch_aws_access_key|cloudant_password|cloudflare_api_key|cloudflare_auth_key|cloudinary_api_secret|cloudinary_name|codecov_token|config|conn.login|connectionstring|consumer_key|consumer_secret|credentials|cypress_record_key|database_password|database_schema_test|datadog_api_key|datadog_app_key|db_password|db_server|db_username|dbpasswd|dbpassword|dbuser|deploy_password|digitalocean_ssh_key_body|digitalocean_ssh_key_ids|docker_hub_password|docker_key|docker_pass|docker_passwd|docker_password|dockerhub_password|dockerhubpassword|dot-files|dotfiles|droplet_travis_password|dynamoaccesskeyid|dynamosecretaccesskey|elastica_host|elastica_port|elasticsearch_password|encryption_key|encryption_password|env.heroku_api_key|env.sonatype_password|eureka.awssecretkey)[a-z0-9_.,-]{0,25})[:<>=|]{1,2}.{0,5}['\"]([0-9A-Za-z\-_=]{8,64})['\"]" > results/sensitive_endpoints.txt

echo "[*] Searching for sensitive patterns..."
grep -E -i '\.env$|\.git/|\.sql$|\.bak$|/phpinfo|/config|/admin|/wp-admin|/upload|token=|api_key=|access_token=|AKIA[0-9A-Z]{16}|-----BEGIN PRIVATE KEY-----|\.js$|\.pdf$|\.docx?$|\.zip$' results/liveurls.txt | tee results/final_grep.txt

# ================== ************** ===================== #
# ================== JS ENUMERATION ===================== #
# ================== ************** ===================== #

echo "[*] Extracting JS links from live URLs..."
grep "\.js$" results/liveurls.txt | sort -u > results/js_results/jslinks.txt

JS_LINKS="results/js_results/jslinks.txt"
JS_LIVE="results/js_results/jslive.txt"
NUCLEI_OUT="results/js_results/js_nuclei.txt"
LINKFINDER_OUT="results/js_results/endpoints_linkfinder.txt"
SECRETFINDER_OUT="results/js_results/endpoints_secretfinder.txt"
MANTRA_OUT="results/js_results/Mantra.txt"
JSLEAK_OUT="results/js_results/jsleaks_output.txt"
JSECRET_OUT="results/js_results/jsecret_output.txt"
CARIDDI_SECRET="results/js_results/cariddi_secret.txt"

echo "[*] Checking live JS links..."
cat "$JS_LINKS" | httpx -silent > "$JS_LIVE"

echo "[*] Running jsleak..."
cat "$JS_LIVE" | jsleak -l -s | sort -u | tee "$JSLEAK_OUT"

echo "[*] Running jsecret..."
cat "$JS_LIVE" | jsecret | tee "$JSECRET_OUT"

echo "[*] Running cariddi..."
cat "$JS_LIVE" | cariddi -s -e| tee "$CARIDDI_SECRET"

echo "[*] Running Mantra..."
cat "$JS_LIVE" | mantra | tee "$MANTRA_OUT"

echo "[*] Running LinkFinder..."
cat "$JS_LIVE" | while read -r url; do
    python3 /home/tools/LinkFinder/linkfinder.py -i "$url" -o cli
done | tee "$LINKFINDER_OUT"

echo "[*] Running SecretFinder..."
cat "$JS_LIVE" | while read -r url; do
    python3 /home/tools/secretfinder/SecretFinder.py -i "$url" -o cli
done | tee "$SECRETFINDER_OUT"

echo "[*] Running Nuclei on JS links..."
nuclei -l "$JS_LIVE" -t ~/nuclei-templates/http/exposures/ -o "$NUCLEI_OUT"

echo "[+] Done! All results saved in 'results/' and 'results/js_results/'"
                                                                            
