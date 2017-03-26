#!/bin/bash

echo "cjdns IP address: $(grep -E '"ipv6":' /etc/cjdroute.conf | head -n 1 | sed 's/.*: "\(.*\)",/\1/')" >> /etc/issue;
echo "cjdns public key: $(grep -E '"publicKey":' /etc/cjdroute.conf | head -n 1 | sed 's/.*: "\(.*\)",/\1/')" >> /etc/issue;
echo "" >> /etc/issue;
