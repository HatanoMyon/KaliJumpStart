#!/bin/bash

debugstop() {
	echo "-----"
	echo $1
	read -p "Press Enter to continue..."
	echo "-----"
}

#are you even qualified to do this?
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

#get other stuff done first
debugstop "Insert VBox Additions cd please..."
cp -r /media/cdrom0/ ~/vboxadditions/
chmod +x ~/vboxadditions/VBoxLinuxAdditions.run
~/vboxadditions/VBoxLinuxAdditions.run
rm -rf ~/vboxadditions

debugstop "Installed VBox Additions"
	
#get rid of screensaver bs
xset s 0 0
xset s off
xset -dpms
debugstop "Got rid of screensaver BS"

#nano /etc/lightdm/lightdm.conf # and add these lines in [Seat:*] section
#autologin-user=root
#autologin-user-timeout=0
if grep -Pq '^autologin' /etc/lightdm/lightdm.conf ; then
	debugstop "Autologin already set, skipping..."
else
	sed -i '/^\[Seat\:\*\]/a autologin-user-timeout=0' /etc/lightdm/lightdm.conf
	sed -i '/^\[Seat\:\*\]/a autologin-user=root' /etc/lightdm/lightdm.conf
	debugstop "Set autologin"
fi

#nano /etc/pam.d/lightdm-autologin #Comment out below line
	#authrequired pam_succeed_if.so user != root quiet_success
if grep -Pq '^#auth      required pam_succeed_if.so user' /etc/pam.d/lightdm-autologin ; then
			debugstop "Root autologin already set, skipping..."
	else
	sed -i '/auth      required pam_succeed_if.so user/s/^/#/' /etc/pam.d/lightdm-autologin
	debugstop "Enabled root autologin"
	fi

apt update && apt -y upgrade
debugstop "Did update and upgrade"

apt -y autoremove
debugstop "Did autoremove"

#go home
cd ~

#Tools dir
mkdir tools
cd tools
debugstop "Created tools dir"

git clone https://github.com/danielmiessler/SecLists
git clone https://github.com/henshin/filebuster
cpan -T install YAML Furl Benchmark Net::DNS::Lite List::MoreUtils IO::Socket::SSL URI::Escape HTML::Entities IO::Socket::Socks::Wrapper URI::URL Cache::LRU IO::Async::Timer::Periodic
git clone https://github.com/infodox/python-pty-shells
debugstop "Cloned all repos"


#Install zsh and ohmyzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
zsh=$(which zsh)
chsh -s "$zsh"
export SHELL="$zsh"
debugstop "Installed zsh"

cp /root/KaliJumpStart/hatanomyon.zsh-theme /root/.oh-my-zsh/themes/
sed 's,ZSH_THEME=[^;]*,ZSH_THEME=\"hatanomyon\",' -i ~/.zshrc
#. ~/.zshrc

curl https://i.imgur.com/6cdsm1n.png > /root/bg.png


debugstop "Installed personal theme"

debugstop "Done! Reboot for full effect."


