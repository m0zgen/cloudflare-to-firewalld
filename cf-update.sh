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

# Check catalog for downloaded ip ranges lists
if [[ ! -d "${LISTS_CATALOG}" ]]; then
    mkdir -p ${LISTS_CATALOG}
fi

# Check cloudflare zone exists
echo "Checking zone ${ZONE_NAME} exists in"
_CF_ZONE_STATUS=$(firewall-cmd --list-all --zone=${ZONE_NAME} | head -1)

if [[ "${_CF_ZONE_STATUS}" =~ "${ZONE_NAME}" ]]; then
    echo "Zone ${ZONE_NAME} Exist"
else
    echo "Need to add zone ${ZONE_NAME}"
    firewall-cmd --new-zone=${ZONE_NAME} --permanent
    firewall-cmd --zone=${ZONE_NAME} --add-service=https --permanent
    # firewall-cmd --zone=${ZONE_NAME} --add-service={http, https} --permanent
    firewall-cmd --reload
fi

applyFirewall() {
    # Add IP addresses to zone
    echo "Update IPs in ${ZONE_NAME} firewalld zone..."
    for i in `<${1}`; do firewall-cmd --zone=${ZONE_NAME} --add-source=$i --permanent; done
    firewall-cmd --reload   

}

downloadLists() {

    local _firts=${LISTS_CATALOG}/ips.txt
    local _last=${LISTS_CATALOG}/ips2.txt

    if [[ ! -f "${_firts}" ]]; then
        echo "List ${_firts} first time will download..."
        curl -sS https://www.cloudflare.com/ips-v4 > ${_firts}
        echo -e "\n"
        curl -sS https://www.cloudflare.com/ips-v6 >> ${_firts}

        applyFirewall ${_firts}

    else
        echo "List will download to compare.."
        curl -sS https://www.cloudflare.com/ips-v4 > ${_last}
        echo -e "\n"
        curl -sS https://www.cloudflare.com/ips-v6 >> ${_last}

        diff ${_last} ${_firts}
        if [ $? -ne 0 ]; then
            echo "List is updated..";
            applyFirewall ${_last}
        fi

        rm ${_firts}; mv ${_last} ${_firts}

    fi

    echo "Done!"

}

downloadLists
