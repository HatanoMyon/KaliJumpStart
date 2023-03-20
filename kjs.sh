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

screenandpower(){
	#get rid of screensaver and power manager bs
	xset s 0 0
	xset s off
	xset -dpms
	xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/power-button-action -s 3
	fconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false --create -t bool # disable display power management
	xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0 --create -t int # never shutdown screen
	xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-screen-suspend-hibernate -s false --create -t bool # don't lock screen when going to sleep
	xfconf-query -c xfce4-session -p /shutdown/LockScreen -s false
	debugstop "Got rid of screensaver and power manager BS"
}

rootautologin(){
	#nano /etc/lightdm/lightdm.conf # and add these lines in [Seat:*] section
	#autologin-user=root
	#autologin-user-timeout=0
	if grep -Pq '^autologin' /etc/lightdm/lightdm.conf ; then
		debugstop "Root Autologin already set, skipping..."
	else
		sed -i '/^\[Seat\:\*\]/a autologin-user-timeout=0' /etc/lightdm/lightdm.conf
		sed -i "/^\[Seat\:\*\]/a autologin-user=root" /etc/lightdm/lightdm.conf
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
}

upgradeautoremove(){
	apt update && apt -y upgrade
	debugstop "Did update and upgrade"

	apt -y autoremove
	debugstop "Did autoremove"
}

toolinstall(){
	#go home
	cd ~

	#Tools dir
	mkdir tools
	cd tools
	debugstop "Created tools dir"

	git clone https://github.com/danielmiessler/SecLists

	git clone https://github.com/rebootuser/LinEnum

	git clone https://github.com/SecureAuthCorp/impacket
	cd impacket
	pip install .
	cd ..

	git clone https://github.com/ShawnDEvans/smbmap
	cd smbmap
	python3 -m pip install -r requirements.txt
	cd ..

	git clone https://github.com/drwetter/testssl.sh

	git clone https://github.com/Ekultek/WhatBreach
	cd WhatBreach
	pip install -r requirements.txt
	cd ..

	git clone https://github.com/Ekultek/WhatWaf

	git clone https://github.com/EnableSecurity/wafw00f
	cd wafw00f
	python setup.py install
	cd ..

	debugstop "Cloned all repos"
}

zshtheme1(){
	#Install zsh and ohmyzsh
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
	zsh=$(which zsh)
	chsh -s "$zsh"
	export SHELL="$zsh"
	debugstop "Installed zsh"

	cp /root/KaliJumpStart/hatanomyon.zsh-theme /root/.oh-my-zsh/themes/
	sed 's,ZSH_THEME=[^;]*,ZSH_THEME=\"hatanomyon\",' -i ~/.zshrc
	#. ~/.zshrc
	debugstop "Installed personal theme"
}

bg(){
	curl https://i.imgur.com/6cdsm1n.png > ~/bg.png
	xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s ~/bg.png
	debugstop "Installed bg"
}


debugstop "Installed personal theme"

debugstop "Done! Reboot for full effect."
