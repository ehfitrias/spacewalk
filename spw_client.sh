#!/bin/bash
#Assume Spacewalk Server IP 10.197.17.208

echo "Adding SpaceWalk Server to /etc/hosts"
cat << EOF >> /etc/hosts
10.197.17.208   bdi-poc-spw2
EOF

echo "Create Spacewalk Repo"
cat <<EOD > /etc/yum.repos.d/spacewalk.repo

[spacewalk-client]
name=Spacewalk Client
baseurl=http://10.197.17.208/pub/spacewalk-client/
enabled=1
gpgcheck=0
EOD

echo "Install Packages & Registration"
yum -y install rhn-client-tools rhn-check rhn-setup rhnsd m2crypto yum-rhn-plugin
rpm -Uvh http://10.197.17.208/pub/rhn-org-trusted-ssl-cert-1.0-1.noarch.rpm
rhnreg_ks --force --serverUrl https://bdi-poc-spw2/XMLRPC --sslCACert /usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT --activationkey 1-b1e505ff7deff1539ba65720d37860e8 --profilename=$HOSTNAME
rhn-profile-sync

#delete spacewalk repo
rm -rf /etc/yum.repos.d/spacewalk.repo

#adding spacewalk client & epel channel
spacewalk-channel -a -c spacewalk-client -c epel-7 -u admin -p P@ssw0rd

#install & configure OSAD
yum -y --nogpgcheck install osad rhncfg-actions
systemctl | grep "osad.*running"
if [ $? = 1 ]; then
	systemctl start osad
	systemctl enable osad
fi

#remove spacewalk client and epel channel
spacewalk-channel -r -c spacewalk-client -c epel-7 -u admin -p P@ssw0rd

#enable checking system
chcon system_u:object_r:rpm_exec_t:s0 /sbin/rhn_check-2.7

#enable deploy & run
rhn-actions-control --enable-all
rhn-actions-control --report

#Sync Profile
rhn-profile-sync

read -p "Done"
