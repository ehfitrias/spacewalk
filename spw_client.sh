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

## create Spacewalk Repo
cat <<EOD > /etc/yum.repos.d/spacewalk.repo

[spacewalk-client]
name=Spacewalk Client
baseurl=http://$IP_SVR/pub/spacewalk-client/
enabled=1
gpgcheck=0
EOD

## install Packages & Registration
yum -y install rhn-client-tools rhn-check rhn-setup rhnsd m2crypto yum-rhn-plugin
rpm -Uvh http://$IP_SVR/pub/rhn-org-trusted-ssl-cert-1.0-1.noarch.rpm
rhnreg_ks --force --serverUrl https://$HOST_SVR/XMLRPC\
--sslCACert /usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT\
--activationkey 1-b1e505ff7deff1539ba65720d37860e8\
--profilename=$HOSTNAME
rhn-profile-sync

# delete spacewalk repo
rm -rf /etc/yum.repos.d/spacewalk.repo

# adding spacewalk client & epel channel
spacewalk-channel -a -c spacewalk-client -c epel-7 -u $USER_SVR -p $PASS_SVR

# install & configure OSAD
yum -y --nogpgcheck install osad rhncfg-actions
systemctl | grep "osad.*running"
if [ $? = 1 ]; then
	systemctl start osad
	systemctl enable osad
fi

# remove spacewalk client and epel channel
spacewalk-channel -r -c spacewalk-client -c epel-7 -u $USER_SVR -p $PASS_SVR

# enable checking system
chcon system_u:object_r:rpm_exec_t:s0 /sbin/rhn_check-2.7

#enable deploy & run
rhn-actions-control --enable-all
rhn-actions-control --report

#Sync Profile
rhn-profile-sync

read -p "Done"
