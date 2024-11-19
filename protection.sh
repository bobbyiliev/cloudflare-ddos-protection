#!/bin/bash

###
# Automating your CloudFlare DDoS Protection by https://bobbyiliev.com
###

set -euo pipefail

# Configuration
readonly CF_CONFIG_FILE="${HOME}/.cloudflare/config"
readonly CF_LOG_FILE="${HOME}/.cloudflare/ddos.log"
readonly TEMP_DIR="/tmp"

# CloudFlare API Configuration
CF_ZONE_ID=${CF_ZONE_ID:-"YOUR_CF_ZONE_ID"}
CF_EMAIL_ADDRESS=${CF_EMAIL_ADDRESS:-"YOUR_CF_EMAIL_ADDRESS"}
CF_API_KEY=${CF_API_KEY:-"YOUR_CF_API_KEY"}

# Settings
readonly NOTIFICATIONS_ENABLED=${notifications:-1}
readonly API_ENDPOINT="https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/settings/security_level"

# Logging function
log() {
    local message="$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$message" >>"$CF_LOG_FILE"
    [ "$NOTIFICATIONS_ENABLED" -eq 1 ] && echo "$message" | mail -s "CloudFlare DDoS Protection: $1" "$CF_EMAIL_ADDRESS"
}

# Error handling
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Validate configuration
validate_config() {
    [[ -z "$CF_ZONE_ID" || "$CF_ZONE_ID" == "YOUR_CF_ZONE_ID" ]] && error_exit "CF_ZONE_ID not configured"
    [[ -z "$CF_EMAIL_ADDRESS" || "$CF_EMAIL_ADDRESS" == "YOUR_CF_EMAIL_ADDRESS" ]] && error_exit "CF_EMAIL_ADDRESS not configured"
    [[ -z "$CF_API_KEY" || "$CF_API_KEY" == "YOUR_CF_API_KEY" ]] && error_exit "CF_API_KEY not configured"
}

# Initialize CloudFlare directory
init_cloudflare_dir() {
    local cf_dir="${HOME}/.cloudflare"
    if ! [ -d "$cf_dir" ]; then
        mkdir -p "$cf_dir" || error_exit "Failed to create CloudFlare directory"
        chmod 700 "$cf_dir" || error_exit "Failed to set permissions on CloudFlare directory"
    fi
}

# Get current CloudFlare security status
get_security_status() {
    local temp_status=$(mktemp "${TEMP_DIR}/cf-status.XXXXXX")
    local temp_result=$(mktemp "${TEMP_DIR}/cf-result.XXXXXX")

    trap 'rm -f "$temp_status" "$temp_result"' EXIT

    if ! curl -sS -X GET "$API_ENDPOINT" \
        -H "X-Auth-Email: ${CF_EMAIL_ADDRESS}" \
        -H "X-Auth-Key: ${CF_API_KEY}" \
        -H "Content-Type: application/json" >"$temp_status"; then
        error_exit "Failed to fetch CloudFlare status"
    fi

    jq -r '.result.value' <"$temp_status" >"$temp_result" 2>/dev/null || error_exit "Failed to parse CloudFlare response"
    cat "$temp_result"
}

# Get system CPU load
get_cpu_load() {
    local load
    load=$(uptime | awk -F'average:' '{ print $2 }' | awk '{print $1}' | sed 's/,/ /')
    echo "${load%.*}"
}

# Calculate allowed CPU load
get_allowed_cpu_load() {
    local cpu_count
    cpu_count=$(nproc)
    local average=$((cpu_count / 2))
    [ "$average" -eq 0 ] && average=1
    echo "$((cpu_count + average))"
}

# Update CloudFlare security level
update_security_level() {
    local level="$1"
    if ! curl -sS -X PATCH "$API_ENDPOINT" \
        -H "X-Auth-Email: ${CF_EMAIL_ADDRESS}" \
        -H "X-Auth-Key: ${CF_API_KEY}" \
        -H "Content-Type: application/json" \
        --data "{\"value\":\"$level\"}"; then
        error_exit "Failed to update security level to $level"
    fi
}

# Check and update DDoS protection status
check_ddos_status() {
    local current_load=$1
    local max_load=$2
    local normal_load=$(nproc)
    local current_status

    current_status=$(get_security_status)

    if [ "$current_load" -gt "$max_load" ] && [ "$current_status" = "medium" ]; then
        update_security_level "under_attack"
        log "Enabled DDoS protection (Load: $current_load)"
    elif [ "$current_load" -lt "$normal_load" ] && [ "$current_status" = "under_attack" ]; then
        update_security_level "medium"
        log "Disabled DDoS protection (Load: $current_load)"
    fi
}

main() {
    validate_config
    init_cloudflare_dir

    local cpu_load
    cpu_load=$(get_cpu_load)
    local max_allowed_load
    max_allowed_load=$(get_allowed_cpu_load)

    check_ddos_status "$cpu_load" "$max_allowed_load"
}

# Execute main function
main
