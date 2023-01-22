#!/bin/bash
# Author: Yevgeniy Goncharov aka xck, http://sys-adm.in
# Add ipv4, ipv6 Cloudflare IP ranges to specified firewalld zone
# Reference: https://www.cloudflare.com/ips/

# Sys env / paths / etc
# ---------------------------------------------------------------------\

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd); cd $SCRIPT_PATH

# Vars
# ---------------------------------------------------------------------\

ZONE_NAME=cloudflare
LISTS_CATALOG=$SCRIPT_PATH/lists

# Help information
usage() {

    echo -e "\nArguments:
    -p (add ip addresses with --permanent)\n"
    exit 1

}

# Checks arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -p|--permanent) _PERMANENT=1; ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Action
# ---------------------------------------------------------------------\

check_zone_exists() {

    # Check cloudflare zone exists
    echo -e "\nChecking zone ${ZONE_NAME} exists in"
    _CF_ZONE_STATUS=$(firewall-cmd --list-all --zone=${ZONE_NAME} | head -1) 

    if [[ "${_CF_ZONE_STATUS}" =~ "${ZONE_NAME}" ]]; then
        echo "Zone ${ZONE_NAME} Exist"
    else
        echo "Zone does not found. Adding new zone: ${ZONE_NAME}"
        firewall-cmd --new-zone=${ZONE_NAME} --permanent
        # firewall-cmd --zone=${ZONE_NAME} --add-service={http, https} --permanent
        firewall-cmd --reload
        echo "New zone: ${ZONE_NAME} added."
    fi
}

check_list_catalog() {

    # Check catalog for downloaded ip ranges lists
    if [[ ! -d "${LISTS_CATALOG}" ]]; then
        mkdir -p ${LISTS_CATALOG}
    fi
}

download_lists() {

    # Download lists
    echo -e "\nDownload Cloudflare IP Ranges lists..."
    echo "Downloading IPv4 list..."
    curl -sS https://www.cloudflare.com/ips-v4 > ${LISTS_CATALOG}/ips.txt
    echo -e "\n" >> ${LISTS_CATALOG}/ips.txt
    echo "Downloading IPv6 list..."
    curl -sS https://www.cloudflare.com/ips-v6 >> ${LISTS_CATALOG}/ips.txt
}

push_to_firewalld() {
    
    if [[ -z "${1}" ]]; then
        # Add IP addresses to zone
        echo -e "\nUpdate IPs in ${ZONE_NAME} firewalld zone..."
    else
        echo -e "\nUpdate IPs in ${ZONE_NAME} firewalld zone... With permanent parameter."
    fi
    
    for i in `<${LISTS_CATALOG}/ips.txt`; do firewall-cmd --zone=${ZONE_NAME} --add-source=$i ${1}; done

    if [[ -z "${1}" ]]; then
        echo -e "\nAdd HTTPS protocol to zone..."
    else
        echo -e "\nAdd HTTPS protocol to zone... With permanent parameter."
    fi
    
    firewall-cmd --zone=${ZONE_NAME} --add-service=https ${1}

    if [[ ! -z "${1}" ]]; then
        echo -e "\nApplying settings, firewalld will be reloaded..."
        firewall-cmd --reload
        
    fi
}

add_ip_to_zone() {

    if [[ "$_PERMANENT" -eq "1" ]]; then
        push_to_firewalld "--permanent"
    else
        push_to_firewalld
    fi
}

finality() {

    echo -e "\nDone!\n"
    echo -e "Note: You can review firewalld ${ZONE_NAME} with command:
    firewall-cmd --list-all --zone=cloudflare\n"
}

# Calls
# ---------------------------------------------------------------------\
check_zone_exists
check_list_catalog
download_lists
add_ip_to_zone
finality
