#!/bin/bash
# Script d'installation et de configuration de proftpd sur Debian 7.0 aka Wheezy
#
# Auteur :
# dwitgsi - 12/2014
VERSION="1.0"

#=============================================================================
# Liste des applications Ã Â  installer
LISTE="proftpd"
#=============================================================================

# Test que le script est lance en root
if [ $EUID -ne 0 ]; then
  echo "Le script doit être lancé en root: # sudo $0" 1>&2
  exit 1
fi

# Mise à jour de la liste des depots
#-----------------------------------

# Update 
echo "Mise à jour de la liste des dépots"
aptitude update

# Upgrade
echo -n "Mettre à jour le système ? (o/N) : "
read UPGRADE
if [[ $UPGRADE = "o" || $UPGRADE = "O" ]]; then
	aptitude safe-upgrade
fi

# Installation
echo "Installation des logiciels suivants: $LISTE"
aptitude -y install $LISTE

# Configuration
#--------------

# Backup du fichier de conf
if ! [ -f /etc/proftpd/proftpd.conf.bkp ]; then
	cp -a /etc/proftpd/proftpd.conf /etc/proftpd/proftpd.conf.bkp
fi

# Chroot des utilisateurs dans leur public_html
sed -i 's/# DefaultRoot.*~/DefaultRoot ~\/public_html/g' /etc/proftpd/proftpd.conf

# Redémarrage du service
service proftpd restart

echo "N'oubliez pas de rajouter les ports 21 et 49152:65534 (listage ftp) au firewall."

# Fin du script