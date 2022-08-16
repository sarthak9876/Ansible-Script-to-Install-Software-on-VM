#!/bin/bash

#change hostname ips for proper result
taking_ips() {

masternode="172.31.4.114"

workernode_1="172.31.14.184"

workernode_2="172.31.7.219"

}

#checking root user or not
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi
create_zifuser() {
USERID="zifuser"

#checking if user exists or not
/bin/egrep  -i "^${USERID}:" /etc/passwd --quiet
if [ $? -eq 0 ]; then
   echo "$USERID exists try different name"
   echo "zifuser:gsLab!23" | chpasswd
#if user exists it will prompt you to change password of existing user

else
#new user will be created with password prompt
   useradd zifuser
   echo "zifuser:gsLab!23" | chpasswd
   echo "$USERID created in /etc/passwd"
fi

}


#adding user to sudo if there not a sudoer
configure_sudo() {
#USER="zifuser"

        grep -oi "zifuser" /etc/sudoers --quiet
if [ $? -eq 0 ]; then
echo "zifuser already exist in sudoers"
else
 
echo zifuser " ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo " zifuser become sudo user"
fi
}

#if firewall is active it will check and disable the firewall
disable_firewall() {
systemctl is-active firewalld --quiet
if [ $? -eq 0 ];then
      echo "firewall is active"
               systemctl stop firewalld
               systemctl disable firewalld
      echo "Firewall is now disabled successfully"
else
systemctl disable firewalld
echo "Firewall already disabled"
fi
}


#checking internet access
verify_internet_access() {
        res=`curl -H "Cache-Conrol: no-cache" -Is http://www.google.com | head -n 1 | awk '{print $2}'`
        #echo $res
[[ "$res" == "200" ]] && echo "Internet connection success" || echo "No Internet Connection"

}

#checking proxy access
verify_proxy() {
        printenv | grep http_proxy
        if [ $? -eq 1 ]
        then
                count=0
        else
                count=1
        fi

        printenv | grep https_proxy
        if [ $? -eq 1 ]
        then
                count=0
        else
                count=1
        fi

        if [ $count == "0" ]
        then
                echo "Proxy connected successfully"
        else
                echo "Failed to connect to proxy"
        fi

}

#Changing hostname
set_hostname() {
IFACE="eth0"
ipadd=$(ifconfig $IFACE |grep "inet " | awk '{print $2}')
if [[ ${ipadd} == $masternode ]]
then
hostnamectl set-hostname masternode
elif [[ ${ipadd} == $workernode_1 ]]
then
                hostnamectl set-hostname workernode_1
elif [[ ${ipadd} == $workernode_2 ]]
then
hostnamectl set-hostname workernode_2
else
echo "IP ADDRESS not found"
exit 1
fi

}


#checking if host entries exists in /etc/hosts
check_host_entries(){

 grep -o "masternode\|workernode_1\|workernode_2\|zif-windows-node1\|zif-windows-node2" /etc/hosts --quiet
 if [ $? -eq 0 ];then
         echo "Host entries already added"
 else
         add_host_entries  "${vms[@]}"
         echo "Added host entries"
 
 fi

}

add_host_entries() {

        local arr=("$@")
        for t in "${arr[@]}"; do
                #printf $t "\n"
                #echo $t | cut -d "," -f 2
                ip=`echo $t | cut -d "," -f 1`
                hostname=`echo $t | cut -d "," -f 2`
                echo $ip $hostname >> /etc/hosts
        done
}

update_sshtimeout(){
        sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 180m/' /etc/ssh/sshd_config
        systemctl restart sshd
echo "Updated SSH timeout to 180m"
}

#removing networkcard if present in system
remove_container_interface(){
        ifconfig | grep -o "cni0:"  --quiet
        if [ $? -eq 0 ]; then

        ifconfig cni0 down
        ip link delete cni0
fi
}
taking_ips
create_zifuser
configure_sudo
disable_firewall
verify_internet_access
verify_proxy
set_hostname
#vms=("$masternode,masternode" "$workernode_1,workernode-1" "$workernode_2,workernode-2")
#check_host_entries
update_sshtimeout
remove_container_interface
