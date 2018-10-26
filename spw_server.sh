#!/bin/bash

## This is for Red Hat Enterprise Linux 7, Scientific Linux 7, CentOS 7

## checking subscription
subscription-manager list|grep "Status.*Subscribed"
if [ $? -eq 1 ]; then
	read -p "Please Subscribe System First !!!"
	exit
fi

## setup Variables
export SPW_REPO=${SPW_REPO:="https://copr.fedorainfracloud.org/coprs/g/spacewalkproject/spacewalk-2.8/repo/epel-7/group_spacewalkproject-spacewalk-2.8-epel-7.repo"}
export SPW_RPM=${SPW_RPM:="https://copr-be.cloud.fedoraproject.org/results/@spacewalkproject/spacewalk-2.8/epel-7-x86_64/00736372-spacewalk-repo/spacewalk-repo-2.8-11.el7.centos.noarch.rpm"}
export SPW_EPEL=${SPW_EPEL:="https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"}
export SPW_JAVA=${SPW_JAVA:="https://copr.fedorainfracloud.org/coprs/g/spacewalkproject/java-packages/repo/epel-7/group_spacewalkproject-java-packages-epel-7.repo"}

## proxy configuration
read -rp "Are you using Proxy Server: (y/n) " ans;
	if [ "$ans" = "y" ] ; then
		export PRX_FLAG="true";
		
		read -rp "Proxy Server: " choice;
		export IP_PRX="$choice";
		
		read -rp "Proxy Port: " choice;
		export PORT_PRX="$choice";
	
	else
		export PRX_FLAG="false";
	fi
			
read -rp "Are you using Proxy Authentication: (y/n) " i;
	if [ "$i" = "y" ] ; then
		export PRX_AUTH="1";
		
		read -rp "Proxy User: " choice;
		export USER_PRX="$choice";
				
		read -rp "Proxy Password: " choice;
		export PASS_PRX="$choice";
	fi		

## adding proxy configuration	
if [ "$PRX_FLAG" = "true" ] && [ "$PRX_AUTH" = "" ] ; then
		export http_proxy="http://${IP_PRX}:${PORT_PRX}/";
		export https_proxy="http://${IP_PRX}:${PORT_PRX}/";
		OPSI=`subscription-manager repos --proxy=${IP_PRX}:${PORT_PRX} --enable=rhel-7-server-optional-rpms`
		else
		if [ "$PRX_FLAG" = "true" ] && [ "$PRX_AUTH" = "1" ] ; then
			export http_proxy="https://${USER_PRX}:${PASS_PRX}@${IP_PRX}:${PORT_PRX}/";
			export https_proxy="https://${USER_PRX}:${PASS_PRX}@${IP_PRX}:${PORT_PRX}/";
			OPSI=`subscription-manager repos --proxy=${IP_PRX}:${PORT_PRX} --proxyuser=${USER_PRX} \
			--proxypassword=${PASS_PRX} --enable=rhel-7-server-optional-rpms`
		fi
fi


if [ "$PRX_FLAG" = "false" ] ; then
	OPSI=`subscription-manager repos --enable=rhel-7-server-optional-rpms` ;
fi

echo "******"
echo "* Your Proxy Server is $IP_PRX "
echo "* Your Proxy Port is $PORT_PRX "
echo "* Your Proxy Username is $USER_PRX "
echo "* Your Proxy Password is $PASS_PRX "
echo "******"	
	
## install Packages & Registration
rpm -Uvh $SPW_RPM 
rpm -Uvh $SPW_EPEL
curl -o /etc/yum.repos.d/java-packages-epel-7.repo $SPW_JAVA
subscription-manager repos --enable=rhel-7-server-optional-rpms

## install postgresql database
yum -y install spacewalk-setup-postgresql

## install spacewalk
yum -y install spacewalk-postgresql

## setup firewalld
firewall-cmd --add-service=http; firewall-cmd --add-service=https;
firewall-cmd --add-port=5222/tcp; firewall-cmd --runtime-to-perm;
firewall-cmd --reload

## setup spacewalk
spacewalk-setup

## start spacewalk service
/usr/sbin/spacewalk-service restart

read -p "Done"