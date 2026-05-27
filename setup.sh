#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Prerequisites & package managers ---------------------------------------

sudo apt update
sudo add-apt-repository -y universe
sudo apt install -y \
	curl \
	ca-certificates \
	gnupg \
	software-properties-common \
	rsync \
	flatpak \
	snapd \
	build-essential \
	pkg-config \
	libssl-dev

sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# --- Third-party apt repositories ---------------------------------------------

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkg.noctalia.dev/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/noctalia.gpg
# noctalia.dev currently publishes up to 'questing' (Ubuntu 25);
# pin to that on newer Ubuntu releases until they ship our codename.
UBUNTU_CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
case "${UBUNTU_CODENAME}" in
	resolute) NOCTALIA_SUITE="questing" ;;
	*)        NOCTALIA_SUITE="${UBUNTU_CODENAME}" ;;
esac
echo "deb [signed-by=/etc/apt/keyrings/noctalia.gpg] https://pkg.noctalia.dev/apt ${NOCTALIA_SUITE} main" \
	| sudo tee /etc/apt/sources.list.d/noctalia.list

# add-apt-repository imports the PPA signing key and writes a sources file
# stamped with the current codename. On Ubuntu releases newer than what the
# PPA publishes for, rewrite the codename to a known-good one (questing).
add_ppa() {
	local ppa="$1"
	local fallback="${2:-questing}"
	sudo add-apt-repository -y -n "ppa:${ppa}"
	if [[ "${UBUNTU_CODENAME}" == "resolute" ]]; then
		local owner="${ppa%%/*}"
		local name="${ppa##*/}"
		local f
		for f in \
			"/etc/apt/sources.list.d/${owner}-ubuntu-${name}-${UBUNTU_CODENAME}.sources" \
			"/etc/apt/sources.list.d/${owner}-ubuntu-${name}-${UBUNTU_CODENAME}.list"; do
			if [[ -f "${f}" ]]; then
				sudo sed -i "s/\b${UBUNTU_CODENAME}\b/${fallback}/g" "${f}"
			fi
		done
	fi
}

add_ppa fish-shell/release-4
add_ppa mkasberg/ghostty-ubuntu
add_ppa avengemedia/danklinux
add_ppa avengemedia/dms

sudo apt update

# --- apt packages -------------------------------------------------------------

sudo apt install -y \
	niri \
	noctalia-shell \
	fish \
	ghostty \
	bat \
	micro \
	fonts-jetbrains-mono \
	gh

# --- snap packages ------------------------------------------------------------

sudo snap install yazi --classic
sudo snap install btop
sudo snap install obsidian --classic
sudo snap install thunderbird --channel=monthly/stable

# --- flatpak packages ---------------------------------------------------------

flatpak install -y flathub org.chromium.Chromium

# --- curl-based installers ----------------------------------------------------

curl -sS https://starship.rs/install.sh | sh -s -- -y
curl -fsSL https://pi.dev/install.sh | sh -s -- -y
curl -LsSf https://astral.sh/uv/install.sh | sh -s -- -y
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- -y
curl -fsSL https://zed.dev/install.sh | sh -s -- -y
curl -LsSf https://mistral.ai/vibe/install.sh | bash -s -- -y
curl --proto '=https' --tlsv1.2 -LsSf \
	https://github.com/j178/prek/releases/download/v0.4.2/prek-installer.sh | sh -s -- -y

# --- Tools installed via freshly sourced PATH ---------------------------------

# shellcheck disable=SC1091
source "${HOME}/.cargo/env"
# shellcheck disable=SC1091
[[ -f "${HOME}/.local/bin/env" ]] && source "${HOME}/.local/bin/env"
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"

cargo install eza
uv tool install lmti

# --- Shell & editor defaults --------------------------------------------------

chsh -s "$(command -v fish)"
sudo update-alternatives --install /usr/bin/editor editor /usr/bin/micro 50
sudo update-alternatives --set editor /usr/bin/micro

# --- Local directories --------------------------------------------------------

mkdir -p "${HOME}/Code"
mkdir -p "${HOME}/.config"
mkdir -p "${HOME}/Pictures/Wallpapers"

if [[ -d "${SCRIPT_DIR}/.config" ]]; then
	rsync -a "${SCRIPT_DIR}/.config/" "${HOME}/.config/"
fi

if [[ -d "${SCRIPT_DIR}/Wallpapers" ]]; then
	rsync -a "${SCRIPT_DIR}/Wallpapers/" "${HOME}/Pictures/Wallpapers/"
fi

# --- Manual steps (not automated) ---------------------------------------------
#
# - Log into gh
# - Set SSH key on GitHub
# - Install Cursor
#
# Chromium:
# - Make work and not-work profiles
# - Install extensions:
#   - Bitwarden
#   - uBlock Origin Lite
#   - Stylus + catppuccin mocha
# - Make webapps: whatsapp, spotify, teams, youtube, protonmail, protoncalendar, protondrive
