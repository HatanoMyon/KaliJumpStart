#!/bin/bash
dpkg-reconfigure kali-grant-root

apt update && apt upgrade
# shutdown -r now if you want

#Tools dir
mkdir tools
cd tools

git clone https://github.com/danielmiessler/SecLists
git clone https://github.com/henshin/filebuster
cpan -T install YAML Furl Benchmark Net::DNS::Lite List::MoreUtils IO::Socket::SSL URI::Escape HTML::Entities IO::Socket::Socks::Wrapper URI::URL Cache::LRU IO::Async::Timer::Periodic
git clone https://github.com/infodox/python-pty-shells


#Install zsh and ohmyzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
zsh=$(which zsh)
chsh -s "$zsh"
export SHELL="$zsh"

sed 's,ZSH_THEME=[^;]*,ZSH_THEME=\"mh\",' -i ~/.zshrc
. ~/.zshrc