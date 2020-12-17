#!/bin/bash

###
# Automating your CloudFlare DDoS Protection by https://bobbyiliev.com
###

##
# CloudFlare API Config
##

CF_ZONE_ID=YOUR_CF_ZONE_ID
CF_EMAIL_ADDRESS=YOUR_CF_EMAIL_ADDRESS
CF_API_KEY=YOUR_CF_API_KEY

##
# Set to 1 in order to enable email notifications
##
notifications=1

##
# Prepare CloudFlare directory
if ! [ -d ~/.cloudflare ] ; then
    mkdir ~/.cloudflare
fi

##
##
# Check current status:
##

current_status=$(mktemp /tmp/temp-status.XXXXXX)
status=$(mktemp /tmp/temp-status.XXXXXX)

function status() {
    curl -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/settings/security_level" \
        -H "X-Auth-Email: ${CF_EMAIL_ADDRESS}" \
        -H "X-Auth-Key: ${CF_API_KEY}" \
        -H "Content-Type: application/json" 2>/dev/null > ${current_status}

    cat ${current_status} | awk -F":" '{ print $4 }' | awk -F',' '{ print $1 }' | tr -d '"' > ${status}
    currentStatus=$(cat ${status})
}

##
# Monitoring your CPU load:
##

load=$(uptime | awk -F'average:' '{ print $2 }' | awk '{print $1}' | sed 's/,/ /')

ddos=${load%.*}

##
# Monitor the status and enable the DDoS protection if required:
##

function allowed_cpu_load(){
    normalCPUload=$(grep -c ^processor /proc/cpuinfo);
    average=$(($normalCPUload/2))
    if [[ $average -eq 0 ]]; then
        average=1;
    fi
    maxCPUload=$(( $normalCPUload+$average ));
}

function disable(){
    curl -X PATCH "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/settings/security_level" \
     -H "X-Auth-Email: ${CF_EMAIL_ADDRESS}" \
     -H "X-Auth-Key: ${CF_API_KEY}" \
     -H "Content-Type: application/json" \
     --data '{"value":"medium"}'
}

function under_attack(){
    curl -X PATCH "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/settings/security_level" \
     -H "X-Auth-Email: ${CF_EMAIL_ADDRESS}" \
     -H "X-Auth-Key: ${CF_API_KEY}" \
     -H "Content-Type: application/json" \
     --data '{"value":"under_attack"}'
}

##
# Check the current status
##

function ddos_check(){
    if [[ $ddos -gt $maxCPUload ]]
    then
        if [[ $currentStatus == "medium" ]]
        then
        # Enable the CloudFlare DDOS protection
        under_attack

        echo "$(date) - Enabled DDoS" >> ~/.cloudflare/ddos.log 
            if [[ $notifications == 1 ]] ; then
                echo "$(date) - Enabled DDoS"  | mail -s "Enabled DDoS" ${CF_EMAIL_ADDRESS}
            fi
        else
        exit 0
        fi
    elif [[ $ddos -lt $normalCPUload ]]
    then
        # If the CPU load is less than the normal CPU load for your server,
        # then the DDoS protection would be disabled if the current status is under attack
        if [[ $currentStatus == "under_attack" ]]
        then
            # Disable the CloudFlare DDOS protection
            disable

            echo "$(date) - Disabled DDoS" >> ~/.cloudflare/ddos.log 
            if [[ $notifications == 1 ]] ; then
                echo "$(date) - Disabled DDoS"  | mail -s "Enabled DDoS" bobby@bobbyiliev.com
            fi
        else
        exit 0
        fi
    else
    #echo "Everything is under control"
    exit 0
    fi
}

##
# Call all functions
##

function main(){
    allowed_cpu_load
    status
    ddos_check
    rm -f ${status} ${current_status}
}
main
