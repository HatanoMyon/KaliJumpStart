#!/bin/bash


# Check if sudo
if [[ $UID -ne 0 ]]; then
   echo "This script must be run from root account"
   exit 1
fi


# Update and upgrade, then install extra packages
apt update --fix-missing && apt upgrade -y && apt autoremove -y
echo "Installed upgrades"

apt install debsums apt-listbugs apt-listchanges needrestart -y
echo "Installed apt improvements"

apt install xmlstarlet golang-go peass powercat windows-privesc-check seclists  -y
echo "Installed extra repos"

# Change shell to bash
chsh -s /usr/bin/bash
echo "Changed shell to bash"


# Set autologin for the root user, intended for vm use
#nano /etc/lightdm/lightdm.conf # and add these lines in [Seat:*] section
if grep -Pq '^autologin' /etc/lightdm/lightdm.conf ; then
	echo "Root autologin already set, skipping..."
else
	sed -i '/^\[Seat\:\*\]/a autologin-user-timeout=0' /etc/lightdm/lightdm.conf
	sed -i "/^\[Seat\:\*\]/a autologin-user=root" /etc/lightdm/lightdm.conf
	echo "Set autologin"
fi

# Enable root autologin
#nano /etc/pam.d/lightdm-autologin #Comment out below line
#authrequired pam_succeed_if.so user != root quiet_success
if grep -Pq '^#auth      required pam_succeed_if.so user' /etc/pam.d/lightdm-autologin ; then
	echo "Root autologin (pam step) already set, skipping..."
else
	sed -i '/auth      required pam_succeed_if.so user/s/^/#/' /etc/pam.d/lightdm-autologin
	echo "Enabled root autologin"
fi
echo "Enabled root autologin"

# Show hidden files in thunar file explorer
xfconf-query -c thunar -p /last-show-hidden -s true --create -t bool
echo "Set hidden files to be shown"

# Install PDTM
go install github.com/projectdiscovery/pdtm/cmd/pdtm@latest
pdtm -install-all
echo "Installed PDTM"

# Install FFUF
go install github.com/ffuf/ffuf/v2@latest
echo "Installed FFUF"

# Create net interface monitor script
cat > /root/ipmon_genmon.sh << 'eox'
#!/bin/bash
# ipmon_genmon.sh - IP monitor script intended for use with xfce4 generic monitor plugin
interface_ips=$(ip -4 -br addr | awk 'NR>1 {printf "%s ", $1": "$3;} END {print ""}')
external="ext: $(dig @resolver4.opendns.com myip.opendns.com +short -4)"
echo "$interface_ips $external"
eox
chmod +x /root/ipmon_genmon.sh
echo "Installed ip monitor script"

# Create enumeration script
cat > /root/enumerate.sh << 'eox'
#!/bin/bash
# Auto Enumerate
tip=tip
nmap $tip -T4
tipports=$(nmap $tip -p- -T4 -oX - | xmlstarlet sel -t -v '//port[state/@state="open"]/@portid' -nl | paste -s -d, -)
echo Ports: $tipports
nmap $tip -p$tipports -T4 -sV -sC -oN $tip_enumerate.nmap
# cat $rip_enumerate.nmap
eox
chmod +x /root/enumerate.sh
echo "Installed enumerate script"

# Add extras to .bashrc
cat >> /root/.bashrc << 'eos' # single quotes prevent the need to escape anything
#### Custom ####

PS1='╭──{\[\e[91m\]\u@\h\[\e[0m\]} \[\e[38;5;81;3m\]\w\[\e[0m\] \n╰\[\e[38;5;76m\][\D{%d/%m/%y} \t]\[\e[0m\] \$ '

alias wanip4='dig @resolver4.opendns.com myip.opendns.com +short -4'
alias enumerate='/root/enumerate.sh'

# target and ip setting - tip and $lip
alias settgt='nano /etc/hosts'
setlip() { lipif=${1:-eth0}; lip=$(ip -f inet addr show $lipif | sed -En -e 's/.*inet ([0-9.]+).*/\1/p'); echo "lip set to $lip";}


cd ~/Desktop

# print banner
echo "Available cmdlets: wanip4, settgt, setlip"
echo "Custom alias: enumerate"
echo "External IP: $(wanip4)"
eos
echo "Added extras to bash"


# Remove power saving options
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false --create -t bool # disable display power management
xfconf-query -c xfce4-screensaver -p /saver/enabled -s false --create -t bool # disable display power management
echo "Set power options"

# Install background image
curl https://i.imgur.com/6cdsm1n.png --output ~/bg.png
xfconf-query -c xfce4-desktop -n -t string -p /backdrop/screen0/monitorVirtual1/workspace0/last-image -s ~/bg.png
echo "Installed bg"

