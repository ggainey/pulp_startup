#!/bin/bash
curl -H "Authorization: Token token=${SUSE_AUTH}" https://scc.suse.com/connect/subscriptions/products | tr "," "\n" > /home/vagrant/devel/pulp_startup/CDN_cert/suse_info_full.txt
grep "url"  /home/vagrant/devel/pulp_startup/CDN_cert/suse_info_full.txt | grep -i product | awk -F\" '{print $4}' | awk -F "\?" '{print $1 "\n" $2 "\n\n" }' > /home/vagrant/devel/pulp_startup/CDN_cert/suse_product_info.txt
grep "url"  /home/vagrant/devel/pulp_startup/CDN_cert/suse_info_full.txt | grep Backport | awk -F\" '{print $4}' | awk -F "\?" '{print $1 "\n" $2 "\n\n" }' > /home/vagrant/devel/pulp_startup/CDN_cert/suse_backport_info.txt
