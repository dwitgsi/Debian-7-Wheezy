#!/bin/bash
# Script d'installation et de configurationeur d'Apache sur Debian 7.0 aka Wheezy
#
# Auteur :
# dwitgsi - 12/2014
VERSION="1.0"

#=============================================================================
# Liste des applications � installer
LISTE="apache2"
#=============================================================================

# Test que le script est lance en root
if [ $EUID -ne 0 ]; then
  echo "Le script doit �tre lanc� en root: # sudo $0" 1>&2
  exit 1
fi

# Mise a jour de la liste des depots
#-----------------------------------

# Update 
echo "Mise � jour de la liste des depots"
aptitude update

# Upgrade
echo -n "Mettre � jour le syst�me ? (o/N) : "
read UPGRADE
if [[ $UPGRADE = "o" || $UPGRADE = "O" ]]; then
	aptitude safe-upgrade
fi

# Installation
echo "Installation des logiciels suivants: $LISTE"
aptitude -y install $LISTE

# Configuration
#--------------

# Adresse mail technique
echo -n "Adresse mail de l'administrateur : "
read MAIL

# Enlever les informations du serveur web
echo "" >> /etc/apache2/apache2.conf
echo "ServerSignature Off" >> /etc/apache2/apache2.conf

# Le module Rewrite : Permet d'activer la r��criture d'URl (URL rewriting)
# et donc d'obtenir des URL plus propres.
a2enmod rewrite

# Le module Userdir : Permet de cr�er un utilisateur syst�me par site.
# Chaque site sera donc attribu� � un utilisateur et se situera dans le r�pertoire /home/utilisateur/public_html de ce dernier.
a2enmod userdir

# Vhost
sed -i 's/webmaster@localhost/'$MAIL$'/g' /etc/apache2/sites-available/default
sed -i 's/webmaster@localhost/'$MAIL$'/g' /etc/apache2/sites-available/default-ssl

# Red�marrage du service apache
service apache2 restart

# Fin
#-----
echo "Pensez à  modifier le firewall (/etc/init.d/firewall.sh) en ajoutant le port 80 et/ou 443 dans TCP_SERVICES."
# Fin du script