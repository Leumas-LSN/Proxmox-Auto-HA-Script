# 🚀 Auto-HA Proxmox

Automatisation de la gestion High Availability (HA) pour Proxmox VE via un script silencieux et un installateur interactif.  
Le système utilise des **tags Proxmox** simples pour déterminer automatiquement quelles VMs/LXC doivent être ajoutées, ignorées, ou retirées de la HA.

> ⚠️ **Important : ce script doit être installé et exécuté sur *tous les nœuds* du cluster Proxmox.**  
> Chaque nœud gère uniquement les VMs/LXC qu’il héberge localement.

---

## ✨ Fonctionnalités

- 🔄 **Ajout automatique en HA** de toutes les VMs/LXC non-HA  
- 🏷️ **Gestion intelligente via tags Proxmox**  
  - `No-HA` → La VM/LXC est ignorée (jamais ajoutée à la HA)  
  - `archive` → La VM/LXC est automatiquement **retirée** de la HA  
- ⚙️ Configuration automatique d’une tâche CRON (15 min / 1h / 24h)  
- 📁 Installation propre dans `/root/scripts/`  
- 🧹 Désinstallation complète via le même installateur  
- 🚀 Exécution automatique et silencieuse, sans output inutile  
- 🖥️ Compatible Proxmox VE 7.x / 8.x / 9.x

---

## ⚠️ Avertissement important

> **Ce script n’a pas encore été largement testé en production.**  
> Il fonctionne correctement en environnement de test, mais une vérification manuelle est recommandée avant un déploiement dans un environnement critique.  
> Utilisation à vos risques et responsabilités.

---

## 📥 Installation

Téléchargez l’installateur :

```bash
wget https://raw.githubusercontent.com/Leumas-LSN/Proxmox-Auto-HA-Script/refs/heads/main/auto_ha_vm_lxc_installer.sh
chmod +x auto_ha_vm_lxc_installer.sh
./auto_ha_vm_lxc_installer.sh
```

L’installateur vous proposera :

1. Installer Auto-HA  
2. Supprimer Auto-HA  
3. Quitter  

---

## 🧰 Fonctionnement du script HA

Une fois installé, le script principal se trouve ici :

```
/root/scripts/auto_add_ha_silent.sh
```

Ce script :

- scanne les VMs (QEMU) et containers (LXC)
- lit leurs tags
- décide automatiquement quoi faire :

| Tag | Action |
|------|--------|
| `No-HA` | ❌ La VM/LXC est ignorée |
| `archive` | ⚠️ La VM/LXC est retirée automatiquement de la HA |
| aucun tag | ✔️ La VM/LXC est ajoutée à la HA si nécessaire |

Le script est conçu pour être **totalement silencieux** et propre pour un usage CRON.

---

## 🕒 Configuration CRON

Lors de l’installation, vous choisissez :

- ⏱️ toutes les 15 minutes  
- ⏱️ toutes les heures  
- ⏱️ toutes les 24 heures  

La ligne CRON ressemble à :

```
*/15 * * * * /root/scripts/auto_add_ha_silent.sh
```

(Variable selon votre choix.)

---

## 🧹 Désinstallation complète

Relancez simplement :

```bash
./auto_ha_vm_lxc_installer.sh
```

Puis sélectionnez :

```
2) Supprimer complètement Auto-HA
```

Cela supprimera :

- le script HA  
- l’installateur dans `/root/scripts/`  
- la tâche CRON associée  

---

## 📂 Structure finale

```
/root/scripts/
│── auto_add_ha_silent.sh      # Script HA silencieux
└── auto_ha_vm_lxc_installer.sh         # Installateur / Désinstallateur auto-copié
```

---

## 🧪 Tests actuels

- Testé sur Proxmox VE 9.x en environnement de lab
- Non encore validé en cluster de production

Vos retours sont les bienvenus pour améliorer la fiabilité du projet.

---
