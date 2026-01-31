#!/bin/bash

apt install -y --no-install-recommends \
arandr \
arc-theme \
arp-scan \
avahi-discover \
avahi-utils \
blueman \
cifs-utils \
cockpit \
cockpit-networkmanager \
cockpit-packagekit \
cockpit-storaged \
cracklib-runtime \
curl \
dmz-cursor-theme \
dnsmasq-base \
file-roller \
fonts-freefont-ttf \
gdebi \
gedit \
gnome-disk-utility \
gnome-icon-theme \
gvfs-backends \
gvfs-fuse \
iputils-ping \
language-pack-en-base \
language-pack-en \
language-selector-gnome \
libaudio2 \
libfm-modules \
libgl1-mesa-dri \
libglu1-mesa \
libopenal1 \
libnspr4 \
libnss-mdns \
libnss3 \
libxcb-icccm4 \
libxcb-image0 \
libxcb-keysyms1 \
libxcb-randr0 \
libxcb-render-util0 \
libxcb-xinerama0 \
libxcb-xkb1 \
lightdm \
lightdm-gtk-greeter \
lxappearance \
lxrandr \
lxtask \
lxterminal \
net-tools \
network-manager \
nano \
notification-daemon \
numlockx \
obsession \
openbox \
openbox-menu \
pavucontrol \
pcmanfm \
pinentry-gtk2 \
policykit-1-gnome \
pulseaudio-module-bluetooth \
rsyslog \
samba-common \
scrot \
tint2 \
tzdata \
update-manager-core \
upower \
wbritish \
whiptail \
wireless-regdb \
wpasupplicant \
xdaliclock \
xdg-utils \
xdotool \
xorg \
xserver-xorg-video-all \
xserver-xorg-video-intel

apt remove -y \
ubiquity \
ubiquity-casper \
ubiquity-frontend-gtk \
ubiquity-ubuntu-artwork

apt autoremove -y

wget https://asharrem.github.io/nxos-default-settings.deb
sudo apt -y -o DPkg::options::="--force-overwrite" install "./nxos-default-settings.deb"
sudo rm /etc/lightdm/lightdm.conf
sudo apt -yf install
rm "$HOME/.gtkrc-2.0"
rm "$HOME/.config/gtk-3.0/settings.ini"
rm "$HOME/.config/pcmanfm/default/pcmanfm.conf"
rm "$HOME/.config/lxterminal/lxterminal.conf"
rm "$HOME/.config/tint2/tint2rc"
rm "$HOME/.local/share/applications/NxOS_Getting_Started.desktop"
rm "$HOME/.local/share/applications/NxOS_Install_Wizard.desktop"
rm "$HOME/.local/share/applications/NxOS_Clock.desktop"