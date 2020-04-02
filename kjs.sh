#!/bin/bash

debugstop() {
	echo $1
	pause
}

part1(){
    
	#install kjsservice
	cp ~/KaliJumpStart/kjsservice /etc/init.d/kjsservice
	debugstop "Copied kjsservice to /etc/init.d/"
	
	#nano /etc/lightdm/lightdm.conf # and add these lines in [Seat:*] section
	#autologin-user=root
	#autologin-user-timeout=o
	sed '/[Seat:*]/ aautologin-user-timeout=0' < /etc/lightdm/lightdm.conf
	sed '/[Seat:*]/ aautologin-user=root' < /etc/lightdm/lightdm.conf
	debugstop "Set autologin"

	#nano /etc/pam.d/lightdm-autologin #Comment out below line
	#authrequired pam_succeed_if.so user != root quiet_success
	sed -i '/authrequired pam_succeed_if.so user != root quiet_success/s/^/#/' /etc/pam.d/lightdm-autologin
	debugstop "Enabled root autologin"
	
}

part2(){
    apt update && apt -y upgrade
	debugstop "Did update and upgrade"
}

part3(){
    
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

	cp ./KaliJumpStart/hatanomyon.zsh-theme ./.oh-my-zsh/themes/
	sed 's,ZSH_THEME=[^;]*,ZSH_THEME=\"hatanomyon\",' -i ~/.zshrc
	. ~/.zshrc
	debugstop "Installed personal theme"
	
}

if [ -f /var/run/parttwodone ]; then
    part3
    rm /var/run/partonedone
    update-rc.d kjsservice remove
	debugstop "All done"
elif [ -f /var/run/partonedone ]; then
    part2
    rm /var/run/partonedone
    touch /var/run/parttwodone
    sudo reboot
else
    part1
    touch /var/run/partonedone
    update-rc.d kjsservice defaults
    sudo reboot
fi

