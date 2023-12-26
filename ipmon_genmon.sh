#!/bin/bash
# ipmon_genmon.sh - IP monitor script intended for use with xfce4 generic monitor plugin
interface_ips=$(ip -4 -br addr | awk 'NR>1 {printf "%s ", $1": "$3;} END {print ""}')
external="ext: $(dig @resolver4.opendns.com myip.opendns.com +short -4)"
echo "$interface_ips $external"
