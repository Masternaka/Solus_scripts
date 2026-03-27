#!/bin/bash

# Configuration stricte pour plus de sécurité et de prévisibilité
set -uo pipefail

# Définition de couleurs pour l'amélioration de la visibilité des messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color (réinitialise la couleur)

# Fonctions utilitaires pour le retour console
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_succ() { echo -e "${GREEN}[SUCCÈS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[ATTENTION]${NC} $1"; }
log_err()  { echo -e "${RED}[ERREUR]${NC} $1"; }

# Gestion des erreurs inattendues
trap_err() {
  log_err "Une erreur inattendue empêchant la suite de l'installation s'est produite (ligne $1)."
  exit 1
}
# La ligne ci-dessous (commentée) permettrait d'arrêter le script à la moindre commande échouée,
# mais ce comportement est souvent trop strict pour les scripts d'installation.
# trap 'trap_err $LINENO' ERR

# 1. Vérification stricte des droits
if [ "$EUID" -ne 0 ]; then
  log_err "Ce script doit être exécuté avec les privilèges d'administrateur."
  echo -e "Utilisez : ${YELLOW}sudo $0${NC}"
  exit 1
fi

# 2. Liste dynamique des logiciels (facilement modifiable)
LOGICIELS=(
  # === Outils Système & Surveillance ===
  "btop"
  "cpu-x"
  "fastfetch"
  "gparted"
  "gufw"
  "hardinfo2"
  "inxi"
  "lshw"
  "samba"
  "ufw"
  
  # === Utilitaires CLI & Gestion de Fichiers ===
  "catfish"
  "curl"
  "eza"
  "fzf"
  "krusader"
  "p7zip"
  "peazip"
  "ranger"
  "ripgrep"
  "stow"
  "wget"
  "yazi"
  "zoxide"

  # === Terminaux & Shell ===
  "alacritty"
  "fish"
  "ghostty"
  "kitty"
  "ptyxis"
  "starship"
  "yakuake"

  # === Développement & Éditeurs ===
  "git"
  "helix"
  "lazygit"
  "meld"
  "micro"
  "vim"
  "vscode"
  "zed"

  # === Navigateurs & Internet ===
  "brave"
  "discord"
  "opera-stable"
  "qbittorrent"
  "solseek"
  "transmission"
  "vivaldi-stable"

  # === Multimédia (Audio/Vidéo) ===
  "cava"
  "deadbeef"
  "easyeffects"
  "mpv"
  "strawberry"
  "vlc"

  # === Personnalisation & Thèmes ===
  "conky"
  "conky-manager"
  "font-firacode-nerd"
  "font-hack-ttf"
  "font-jetbrainsmono-ttf"
  "klassy"
  "kvantum"
  "papirus-icon-theme"

  # === Virtualisation & ISO ===
  "distrobox"
  "etcher"
  "qemu"
  "virt-manager"
  "virtualbox"

  # === Sécurité & Bureautique ===
  "bitwarden-desktop"
  "keepassxc"
  "localsend"

  # === Pilotes & Matériel ===
  "ffmpeg-chromium-vivaldi-stable"
  "intel-media-driver"
  "intel-microcode"
  "openrgb"
  
  # "un-logiciel-qui-n-existe-pas" (testez ceci pour vérifier la gestion des erreurs)
)

log_info "Démarrage du processus de configuration..."

# 3. Sécurité réseau et base de données : vérifier que l'update fonctionne
log_info "Synchronisation et mise à jour des dépôts logiciels..."
if ! eopkg update-repo; then
  log_err "Impossible de mettre à jour les dépôts. Vérifiez votre connexion internet."
  exit 1
fi

# Préparation des listes
PAQUETS_A_INSTALLER=()
PAQUETS_INTROUVABLES=()

log_info "Vérification de la disponibilité de ${#LOGICIELS[@]} paquet(s)..."

# 4. Intelligence et robustesse : au lieu d'interrompre l'installation si un paquet manque,
# nous pré-vérifions chaque paquet pour construire un lot valide.
for logiciel in "${LOGICIELS[@]}"; do
  # On masque la sortie de eopkg info. Si code de retour 0 = succès (existe), sinon (n'existe pas)
  if eopkg info "$logiciel" >/dev/null 2>&1; then
    PAQUETS_A_INSTALLER+=("$logiciel")
  else
    PAQUETS_INTROUVABLES+=("$logiciel")
  fi
done

# Affichage clair des paquets à problèmes
if [ ${#PAQUETS_INTROUVABLES[@]} -gt 0 ]; then
  log_warn "Les paquets suivants sont introuvables sur Solus et seront ignorés :"
  for p in "${PAQUETS_INTROUVABLES[@]}"; do
    echo -e "  - ${YELLOW}$p${NC}"
  done
fi

# 5. Efficacité de l'installation : regroupement de l'opération
# eopkg est bien plus rapide (et gère mieux les dépendances) quand on installe un lot global
if [ ${#PAQUETS_A_INSTALLER[@]} -gt 0 ]; then
  log_info "Début de l'installation de ${#PAQUETS_A_INSTALLER[@]} paquet(s)..."
  
  # L'installation elle-même vérifiée
  if eopkg install -y "${PAQUETS_A_INSTALLER[@]}"; then
    log_succ "Tous les paquets trouvés ont été installés avec succès !"
  else
    log_err "L'installation a rencontré un problème."
    log_warn "Vous pouvez relancer le script ou vérifier manuellement ce qui bloque."
    exit 1
  fi
else
  log_warn "Aucun paquet de votre liste n'est disponible pour installation."
fi

log_succ "Fin du script."
