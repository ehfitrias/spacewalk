#!/bin/bash

## setup Variables
read -rp "Spacewalk IP Address: ($IP_SVR): " choice;
	if [ "$choice" != "" ] ; then
		export IP_SVR="$choice";
	fi

read -rp "Spacewalk Hostname: ($HOST_SVR): " choice;
	if [ "$choice" != "" ] ; then
		export HOST_SVR="$choice";
	fi	
	
read -rp "Spacewalk User: ($USER_SVR): " choice;
	if [ "$choice" != "" ] ; then
		export USER_SVR="$choice";
	fi
	
read -rp "Spacewalk Password: ($PASS_SVR): " choice;
	if [ "$choice" != "" ] ; then
		export PASS_SVR="$choice";
	fi
	
## adding Spacewalk Server to /etc/hosts
cat << EOF >> /etc/hosts
$IP_SVR   $HOST_SVR
EOF

## install Packages & Registration
rpm -Uvh http://$IP_SVR/pub/rhn-org-trusted-ssl-cert-1.0-1.noarch.rpm
rhnreg_ks --serverUrl https://$HOST_SVR/XMLRPC \
--sslCACert=/usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT \
--activationkey=1-rhel
rhn-profile-sync

## adding spacewalk client & epel channel
spacewalk-channel -a -c spacewalk-client -c epel-7 -u $USER_SVR -p $PASS_SVR

## install package & configure OSAD
yum -y --nogpgcheck install rhn-client-tools rhn-check rhn-setup rhnsd m2crypto yum-rhn-plugin osad rhncfg rhncfg-actions rhncfg-client
systemctl | grep "osad.*running"
if [ $? = 1 ]; then
	systemctl start osad
	systemctl enable osad
fi

## remove spacewalk client and epel channel
spacewalk-channel -r -c spacewalk-client -c epel-7 --u $USER_SVR -p $PASS_SVR

## enable deploy & run
rhn-actions-control --enable-all
rhn-actions-control --report

## sync Profile
rhn-profile-sync

read -p "Done"
