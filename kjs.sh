#!/bin/bash

debugstop() {
	echo "-----"
	echo $1
	#read -p "Press Enter to continue..."
	echo "-----"
}

#are you even qualified to do this?
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

pimpmykali(){
	git clone https://github.com/Dewalt-arch/pimpmykali
	./pimpmykali/pimpmykali.sh
	rm -rf pimpmykali
	rm -rf pimpmykali.log
}

screenandpower(){
	#get rid of screensaver and power manager bs
	xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/power-button-action -s 3
	xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false --create -t bool # disable display power management
	xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0 --create -t int # never shutdown screen
	xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-screen-suspend-hibernate -s false --create -t bool # don't lock screen when going to sleep
	xfconf-query -c xfce4-session -p /shutdown/LockScreen -s false
	debugstop "Got rid of screensaver and power manager BS"
}

rootautologin(){
	#intended for vm use
	
	#nano /etc/lightdm/lightdm.conf # and add these lines in [Seat:*] section
	#autologin-user=root
	#autologin-user-timeout=0
	if grep -Pq '^autologin' /etc/lightdm/lightdm.conf ; then
		debugstop "Root autologin already set, skipping..."
	else
		sed -i '/^\[Seat\:\*\]/a autologin-user-timeout=0' /etc/lightdm/lightdm.conf
		sed -i "/^\[Seat\:\*\]/a autologin-user=root" /etc/lightdm/lightdm.conf
		debugstop "Set autologin"
	fi

	#nano /etc/pam.d/lightdm-autologin #Comment out below line
	#authrequired pam_succeed_if.so user != root quiet_success
	if grep -Pq '^#auth      required pam_succeed_if.so user' /etc/pam.d/lightdm-autologin ; then
		debugstop "Root autologin (pam step) already set, skipping..."
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

additionalaptpackages(){
	# debsums - check the MD5 sums of installed Debian packages
	# apt-listbugs - Lists critical bugs before each APT installation/upgrade
	# apt-listchanges - Show new changelog entries from Debian package archives
	# needrestart checks which daemons need to be restarted after library upgrades
	sudo apt install debsums apt-listbugs apt-listchanges needrestart
}

toolinstall(){
	#go home
	cd ~

	#Tools dir
	mkdir tools
	cd tools
	debugstop "Created tools dir"

	git clone https://github.com/rebootuser/LinEnum

	git clone https://github.com/Ekultek/WhatBreach
	cd WhatBreach
	pip install -r requirements.txt
	ln -s "$(pwd)/whatbreach.py" "/usr/bin/whatbreach"
	cd ..

	git clone https://github.com/EnableSecurity/wafw00f
	cd wafw00f
	python setup.py install
	cd ..

	debugstop "Cloned all repos"
}

shellandfiles(){
	#Install zsh and ohmyzsh
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
	zsh=$(which zsh)
	chsh -s "$zsh"
	export SHELL="$zsh"
	debugstop "Installed oh my zsh"

	cp hatanomyon.zsh-theme /root/.oh-my-zsh/themes/
	sed 's,ZSH_THEME=[^;]*,ZSH_THEME=\"hatanomyon\",' -i ~/.zshrc
	#. ~/.zshrc
	debugstop "Installed personal shell theme"
	
	#also remove transparency from terminal
	sed 's,ApplicationTransparency=.*$,ApplicationTransparency=0,' -i /root/.config/qterminal.org/qterminal.ini
	
	#show hidden files
	xfconf-query -c thunar -p /last-show-hidden -s true --create -t bool
}

zshrcadditions(){
	cat <<eos >> .zshrc

	alias wanip4='dig @resolver4.opendns.com myip.opendns.com +short -4'

	# smart_script will continuously log the input and output of the terminal into a logfile located in ~/terminal_logs
	# Original credit to HuskyHacks

	logging_script(){
		# if there's no SCRIPT_LOG_FILE exported yet
		if [ -z "$SCRIPT_LOG_FILE" ]; then
			# make folder paths
			logdirparent=~/terminal_logs
			logdirraw=raw/$(date +%F)
			logdir=$logdirparent/$logdirraw
			logfile=$logdir/$(date +%F_%T).$$.rawlog
			txtfile=$logdir/$(date +%F_%T).$$.txt
			
			# if no folder exist - make one
			if [ ! -d $logdir ]; then
				mkdir -p $logdir
			fi
			export SCRIPT_LOG_FILE=$logfile
			export SCRIPT_LOG_PARENT_FOLDER=$logdirparent
			export TXTFILE=$txtfile
			
			# quiet output if no args are passed
			if [ ! -z "$1" ]; then
				script -f $logfile
				cat $logfile | perl -pe 's/\\e([^\\[\\]]|\\[.*?[a-zA-Z]|\\].*?\\a)//g' | col -b > $txtfile
			else
				script -f -q $logfile
				cat $logfile | perl -pe 's/\\e([^\\[\\]]|\\[.*?[a-zA-Z]|\\].*?\\a)//g' | col -b > $txtfile
			fi
			exit
		fi
	}
	# Start logging into new file
	alias startnewlog='unset SCRIPT_LOG_FILE && smart_script -v'

	# savelog manually saves the current terminal in/out into a logfile: 
	# Example: $ savelog logname
	savelog(){
		# make folder path
		manualdir=$SCRIPT_LOG_PARENT_FOLDER/manual
		# if no folder exists - make one
		if [ ! -d $manualdir ]; then
			mkdir -p $manualdir
		fi
		# make log name
		logname=${SCRIPT_LOG_FILE##*/}
		logname=${logname%.*}
		# add user logname if passed as argument
		if [ ! -z $1 ]; then
			logname=$logname'_'$1
		fi
		# make filepaths
		txtfile=$manualdir/$logname'.txt'
		rawfile=$manualdir/$logname'.rawlog'
		# make .rawlog readable and save it to .txt file
		cat $SCRIPT_LOG_FILE | perl -pe 's/\\e([^\\[\\]]|\\[.*?[a-zA-Z]|\\].*?\\a)//g' | col -b > $txtfile
		# copy corresponding .rawfile
		cp $SCRIPT_LOG_FILE $rawfile
		printf '[+] Saved logs'
		echo ""
		printf '  \\\\-> '$txtfile''
		echo ""
		printf '  \\\\-> '$rawfile''
	}

	# Run script at terminal initialization
	logging_script

	# print banner
	print -P "%F{045}%}Session being logged!%{$reset_color%}"
	print -P "%F{045}%}External IP: $(wanip4)%{$reset_color%}"

	eos
}

bg(){
	curl https://i.imgur.com/6cdsm1n.png > ~/bg.png
	xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorVirtual1/workspace0/last-image -s ~/bg.png
	debugstop "Installed bg"
}

toolsonly(){
	toolinstall
}

configsonly(){
	pimpmykali
	rootautologin
	screenandpower
	additionalaptpackages
	shellandfiles
	zshrcadditions
	bg
	upgradeautoremove
}

fullinstall(){
	configsonly
	toolinstall
	debugstop "Done! Reboot for full effect."
}

mainf(){
	title="KaliJumpStarter"
	prompt="Pick an option:"
	options=("Full" "Configs only" "Tools only")

	echo "$title"
	PS3="$prompt "
	select opt in "${options[@]}" "Quit"; do 
	    case "$REPLY" in
	    1) echo "You picked $opt"
	    fullinstall
	    break;;
	    2) echo "You picked $opt"
	    configsonly
            break;;
	    3) echo "You picked $opt"
	    toolsonly
            break;;
	    $((${#options[@]}+1))) echo "Goodbye!"; break;;
	    *) echo "Invalid option. Try another one.";continue;;
	    esac
	done
}

mainf
