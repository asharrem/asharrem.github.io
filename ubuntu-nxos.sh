#!/bin/bash

DO_RELEASE_UPGRADE=false
TAIL_UPGRADE_LOG=false
CONFIRM_RELEASE_UPGRADE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --release-upgrade|-U)
      DO_RELEASE_UPGRADE=true
      shift
      ;;
    --tail|-t)
      TAIL_UPGRADE_LOG=true
      shift
      ;;
    -*)
      echo "Usage: $0 [--release-upgrade|-U] [--tail|-t]" >&2
      echo "  --release-upgrade, -U  Run do-release-upgrade at end of script (with early confirm)" >&2
      echo "  --tail, -t             Follow upgrade log after starting (use with -U)" >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -gt 0 ]]; then
  echo "Usage: $0 [--release-upgrade|-U] [--tail|-t]" >&2
  exit 1
fi

# Early block: upgrade path and confirmation (only when --release-upgrade)
if [[ $DO_RELEASE_UPGRADE == true ]]; then
  echo "Current release: $(lsb_release -ds 2>/dev/null || cat /etc/os-release 2>/dev/null | sed -n 's/^PRETTY_NAME=//p' | tr -d '"')"
  if [[ -f /etc/update-manager/release-upgrades ]]; then
    prompt_val=$(sed -n 's/^Prompt=//p' /etc/update-manager/release-upgrades 2>/dev/null)
    case $prompt_val in
      lts)   echo "Upgrade policy: LTS only" ;;
      normal) echo "Upgrade policy: normal (next release)" ;;
      never) echo "Upgrade policy: never" ;;
      *)     echo "Upgrade policy: $prompt_val" ;;
    esac
  fi
  if sudo do-release-upgrade --check-dist-upgrade-only 2>/dev/null; then
    echo "A new release is available. The upgrade will be run at the end of this script in the background."
    read -r -p "Run release upgrade at end of script? [y/N] " ans
    if [[ $ans == [yY] || $ans == [yY][eE][sS] ]]; then
      CONFIRM_RELEASE_UPGRADE=true
    fi
  else
    echo "No new release is available (or check failed). Release upgrade will not be scheduled."
  fi
fi

# remove ubuntu (variants)desktop
sudo apt remove -y -- \
  *ubuntu-desktop

# apt update (and optionally upgrade); on source/GPG errors, offer to disable failing sources and retry
APT_UPDATE_OK=false
APT_OUT=$(mktemp)
cleanup_apt_out() { rm -f "$APT_OUT"; }
trap cleanup_apt_out EXIT

# shellcheck disable=SC2024
if sudo apt update > "$APT_OUT" 2>&1; then
  APT_UPDATE_OK=true
else
  # Parse apt update output for failing repository URLs
  FAILING_URLS=()
  while IFS= read -r line; do
    if [[ $line =~ E:\ The\ repository\ \'([^\']+)\' ]]; then
      FAILING_URLS+=("${BASH_REMATCH[1]}")
    elif [[ $line =~ Err:[0-9]+\ ([^[:space:]]+) ]]; then
      FAILING_URLS+=("${BASH_REMATCH[1]}")
    elif [[ $line =~ W:\ GPG\ error:\ ([^[:space:]]+) ]]; then
      FAILING_URLS+=("${BASH_REMATCH[1]}")
    fi
  done < "$APT_OUT"

  # Find which list files in sources.list.d reference those URLs (we do not disable main sources.list)
  FILES_TO_DISABLE=()
  for url in "${FAILING_URLS[@]}"; do
    [[ -z $url ]] && continue
    while IFS= read -r -d '' f; do
      if [[ -f $f && ! $f == *.disabled ]]; then
        FILES_TO_DISABLE+=("$f")
      fi
    done < <(grep -lZ -- "$url" /etc/apt/sources.list.d/*.list 2>/dev/null || true)
  done

  # Deduplicate and offer to disable
  if [[ ${#FILES_TO_DISABLE[@]} -gt 0 ]]; then
    readarray -t FILES_TO_DISABLE < <(printf '%s\n' "${FILES_TO_DISABLE[@]}" | sort -u)
    echo "The following apt source(s) appear to be failing (e.g. GPG key missing, 404):" >&2
    printf '  %s\n' "${FILES_TO_DISABLE[@]}" >&2
    read -r -p "Disable these sources and retry apt update? [y/N] " ans
    if [[ $ans == [yY] || $ans == [yY][eE][sS] ]]; then
      for f in "${FILES_TO_DISABLE[@]}"; do
        [[ -f $f ]] && sudo mv -- "$f" "${f}.disabled" && echo "Disabled: $f" >&2
      done
      # shellcheck disable=SC2024
      if sudo apt update > "$APT_OUT" 2>&1; then
        APT_UPDATE_OK=true
      fi
    fi
  fi
fi

if [[ $APT_UPDATE_OK == true ]]; then
  if ! sudo apt upgrade -y; then
    echo "Warning: apt upgrade reported errors. Continuing; release upgrade will still be attempted if scheduled." >&2
  fi
else
  echo "Warning: apt update reported errors (e.g. third-party repo GPG/sources). Continuing; release upgrade will still be attempted if scheduled." >&2
  if ! sudo apt upgrade -y 2>/dev/null; then
    echo "Warning: apt upgrade skipped or failed." >&2
  fi
fi

# install nxos packages
sudo apt install -y --no-install-recommends \
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

sudo apt autoremove -y

# download, install & cleanup nxos-default-settings
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

# Release upgrade at end (background) when requested and confirmed
if [[ $DO_RELEASE_UPGRADE == true && $CONFIRM_RELEASE_UPGRADE == true ]]; then
  UPGRADE_LOG="${UPGRADE_LOG:-/tmp/do-release-upgrade-$(date +%Y%m%d-%H%M%S).log}"
  # Redirect before nohup so stdout/stderr are not a terminal; nohup then does not create nohup.out
  nohup sudo do-release-upgrade --frontend=DistUpgradeViewNonInteractive >> "$UPGRADE_LOG" 2>&1 &
  UPGRADE_PID=$!
  echo "Release upgrade started in background (PID $UPGRADE_PID). Log: $UPGRADE_LOG (see also /var/log/dist-upgrade/)"
  if [[ $TAIL_UPGRADE_LOG == true ]]; then
    echo "Tailing upgrade log (Ctrl+C to stop tailing; upgrade continues in background)..."
    tail -f "$UPGRADE_LOG" &
    TAIL_PID=$!
    wait $UPGRADE_PID 2>/dev/null
    kill $TAIL_PID 2>/dev/null
    wait $TAIL_PID 2>/dev/null
  fi
fi

# Nx 6.1 depends
#binutils binutils-common binutils-x86-64-linux-gnu libbinutils libctf-nobfd0 libctf0 libxcb-cursor0 libxslt1.1