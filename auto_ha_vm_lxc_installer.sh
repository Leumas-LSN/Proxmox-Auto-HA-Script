#!/bin/bash

INSTALL_DIR="/root/scripts"
INSTALLER_TARGET="$INSTALL_DIR/install_auto_ha.sh"
HA_SCRIPT="$INSTALL_DIR/auto_add_ha_silent.sh"

clear
echo "=============================================================="
echo "             SCRIPT AUTO-HA PROXMOX — INSTALLATEUR"
echo "=============================================================="
echo ""
echo "  1) Installer Auto-HA"
echo "  2) Supprimer complètement Auto-HA"
echo "  3) Quitter"
echo ""
read -p "Votre choix (1/2/3) : " main_choice
echo ""

case "$main_choice" in

# =====================================================================
#                           INSTALLATION
# =====================================================================
1)
    clear
    echo "=============================================================="
    echo "        INSTALLATION DU SCRIPT AUTO-HA PROXMOX"
    echo "=============================================================="
    echo ""
    echo "Fonctionnement du script Auto-HA :"
    echo ""
    echo "  ✔ Ajoute AUTOMATIQUEMENT en HA les VMs/LXC non-HA"
    echo "  ✔ Ignore totalement les VMs/LXC avec le tag : No-HA"
    echo "  ✔ Retire de la HA les VMs/LXC avec le tag : archive"
    echo ""
    echo "=============================================================="
    echo ""
    read -p "Appuyez sur ENTER pour continuer..." _

    mkdir -p "$INSTALL_DIR"

    # copie de l’installateur
    cp "$0" "$INSTALLER_TARGET"
    chmod +x "$INSTALLER_TARGET"

    # script HA silencieux
    cat << 'EOF' > "$HA_SCRIPT"
#!/bin/bash
exec >/dev/null 2>&1

# si HA -> vrai
is_ha() {
    ha-manager config | grep -q "vm:${1}" && return 0 || return 1
}

# tag No-HA → ignorer
has_noha_tag() {
    echo "$1" | grep -qi "no-ha" && return 0 || return 1
}

# tag archive → sortir de la HA
has_archive_tag() {
    echo "$1" | grep -qi "archive" && return 0 || return 1
}

##############################
#       QEMU (VMs)
##############################
qm list | awk 'NR>1 {print $1}' | while read vmid; do
    CONFIG=$(qm config "$vmid" 2>/dev/null)
    tags=$(echo "$CONFIG" | awk -F': ' '/^tags:/ {print $2}')

    # Si tag "archive" -> retirer de HA
    if has_archive_tag "$tags"; then
        if is_ha "$vmid"; then
            ha-manager remove "vm:${vmid}" >/dev/null 2>&1
        fi
        continue
    fi

    # Si tag No-HA -> ignorer
    has_noha_tag "$tags" && continue

    # Sinon → ajouter en HA si pas déjà HA
    if ! is_ha "$vmid"; then
        ha-manager add "vm:${vmid}" >/dev/null 2>&1
    fi
done

##############################
#       LXC (Containers)
##############################
pct list | awk 'NR>1 {print $1}' | while read vmid; do
    CONFIG=$(pct config "$vmid" 2>/dev/null)
    tags=$(echo "$CONFIG" | awk -F': ' '/^tags:/ {print $2}')

    # Tag archive → retirer de HA
    if has_archive_tag "$tags"; then
        if is_ha "$vmid"; then
            ha-manager remove "ct:${vmid}" >/dev/null 2>&1
        fi
        continue
    fi

    # Tag No-HA → ignorer
    has_noha_tag "$tags" && continue

    # Sinon → ajouter en HA
    if ! is_ha "$vmid"; then
        ha-manager add "ct:${vmid}" >/dev/null 2>&1
    fi
done
EOF

    chmod +x "$HA_SCRIPT"

    echo ""
    echo "================= CHOIX DE LA FRÉQUENCE CRON ================="
    echo ""
    echo "  1) Toutes les 15 minutes"
    echo "  2) Toutes les heures"
    echo "  3) Toutes les 24h"
    echo ""
    read -p "Votre choix (1/2/3) : " choice
    echo ""

    case "$choice" in
        1) CRONLINE="*/15 * * * * $HA_SCRIPT" ;;
        2) CRONLINE="0 * * * * $HA_SCRIPT" ;;
        3) CRONLINE="0 0 * * * $HA_SCRIPT" ;;
        *) echo "❌ Choix invalide."; exit 1 ;;
    esac

    # Écrire la tâche CRON
    tmp=$(mktemp)
    crontab -l 2>/dev/null | grep -v "$HA_SCRIPT" > "$tmp"
    echo "$CRONLINE" >> "$tmp"
    crontab "$tmp"
    rm -f "$tmp"

    echo "→ Exécution immédiate du script HA..."
    "$HA_SCRIPT"

    echo ""
    echo "=============================================================="
    echo "           INSTALLATION TERMINÉE AVEC SUCCÈS 🎉"
    echo "=============================================================="
    echo ""
    echo "Script HA : $HA_SCRIPT"
    echo "Installateur : $INSTALLER_TARGET"
    echo "Cron : $CRONLINE"
    echo ""
    echo "Tags spéciaux :"
    echo "  No-HA   => Ignoré (jamais ajouté en HA)"
    echo "  archive => Retiré automatiquement de la HA"
    echo ""
    ;;
    
# =====================================================================
#                           SUPPRESSION
# =====================================================================
2)
    clear
    echo "=============================================================="
    echo "              SUPPRESSION DU SCRIPT AUTO-HA"
    echo "=============================================================="
    echo ""
    read -p "Voulez-vous vraiment supprimer Auto-HA ? (o/N) : " confirm

    if [[ "$confirm" =~ ^[oO]$ ]]; then
        echo "→ Suppression des scripts..."
        rm -f "$HA_SCRIPT"
        rm -f "$INSTALLER_TARGET"

        echo "→ Nettoyage CRON..."
        tmp=$(mktemp)
        crontab -l 2>/dev/null | grep -v "$HA_SCRIPT" | grep -v "$INSTALLER_TARGET" > "$tmp"
        crontab "$tmp"
        rm -f "$tmp"

        echo ""
        echo "=============================================================="
        echo "        AUTO-HA SUPPRIMÉ COMPLÈTEMENT ✔"
        echo "=============================================================="
        echo ""
    else
        echo "Annulé."
    fi
    ;;

# =====================================================================
#                           QUITTER
# =====================================================================
3)
    echo "Fermeture."
    exit 0
    ;;

*)
    echo "❌ Choix invalide."
    exit 1
    ;;
esac
