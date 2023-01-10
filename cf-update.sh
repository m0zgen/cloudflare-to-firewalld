#!/bin/bash
# Author: Yevgeniy Goncharov aka xck, http://sys-adm.in
# Add ipv4, ipv6 Cloudflare IP ranges to specified firewalld zone
# Reference: https://www.cloudflare.com/ips/

# Sys env / paths / etc
# ---------------------------------------------------------------------\

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
cd $SCRIPT_PATH

ZONE_NAME=cloudflare
LISTS_CATALOG=$SCRIPT_PATH/lists

# Action
# ---------------------------------------------------------------------\

# Check cloudflare zone exists
echo "Checking zone ${ZONE_NAME} exists in"
_CF_ZONE_STATUS=$(firewall-cmd --list-all --zone=${ZONE_NAME} | head -1)

if [[ "${_CF_ZONE_STATUS}" =~ "${ZONE_NAME}" ]]; then
    echo "Zone ${ZONE_NAME} Exist"
else
    echo "Need to add zone ${ZONE_NAME}"
    firewall-cmd --new-zone=${ZONE_NAME} --permanent
    # firewall-cmd --zone=${ZONE_NAME} --add-service={http, https} --permanent
    firewall-cmd --reload
fi

# Check catalog for downloaded ip ranges lists
if [[ ! -d "${LISTS_CATALOG}" ]]; then
    mkdir -p ${LISTS_CATALOG}
fi

# Download lists
echo "Downloading IPv4 list..."
curl -sS https://www.cloudflare.com/ips-v4 > ${LISTS_CATALOG}/ips.txt
echo -e "\n" >> ${LISTS_CATALOG}/ips.txt
echo "Downloading IPv6 list..."
curl -sS https://www.cloudflare.com/ips-v6 >> ${LISTS_CATALOG}/ips.txt

# Add IP addresses to zone
echo "Update IPs in ${ZONE_NAME} firewalld zone..."
for i in `<${LISTS_CATALOG}/ips.txt`; do firewall-cmd --zone=${ZONE_NAME} --add-source=$i; done

firewall-cmd --zone=${ZONE_NAME} --add-service=https

echo "Done!"
