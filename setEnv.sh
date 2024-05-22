#install ps
apt-get update
apt-get install -y wget
wget https://github.com/PowerShell/PowerShell/releases/download/v7.4.2/powershell_7.4.2-1.deb_amd64.deb
dpkg -i powershell_7.4.2-1.deb_amd64.deb
apt-get install -f
rm powershell_7.4.2-1.deb_amd64.deb

#ansible module
ansible-galaxy collection install ansible.netcommon

#install git
apt-get install -y git
git version
git config --global user.name "SmokeDaReal"
git config --global user.email "szmok.peter1@gmail.com"

#install openssh
apt-get install -y openssh-server
