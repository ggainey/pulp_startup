#!/bin/bash
curl -H "Authorization: Token token=i${SUSE_AUTH}" https://scc.suse.com/connect/subscriptions/products | tr "," "\n" | grep -i "url" | grep -i "SLE-SERVER" > suse_subs_info.tx
awk -F\" '{print $4}' suse_subs_info.txt  | grep "/product/" | awk -F "\?" '{print $1 "\n" $2 "\n\n" }'
