#!/bin/bash
# Script d'installation et de configurationeur de MySQL et PhpMyAdmin sur Debian 7.0 aka Wheezy
#
# Auteur :
# dwitgsi - 12/2014
VERSION="1.0"

#=============================================================================
# Liste des applications à installer
LISTE="mysql-server phpmyadmin"
#=============================================================================

# Test que le script est lance en root
if [ $EUID -ne 0 ]; then
  echo "Le script doit être lancé en root: # sudo $0" 1>&2
  exit 1
fi

# Mise a jour de la liste des depots
#-----------------------------------

# Update 
echo "Mise à jour de la liste des depots"
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

# Création de l'utilisateur phpmyadmin
echo -n "Mot de passe de l'utilisateur phpmyadmin : "
read -s PASS
echo ""
useradd -p $PASS -m -s /bin/bash phpmyadmin

# Création du répertoire web de phpmyadmin
mkdir /home/phpmyadmin/public_html

# Copie des fichiers de phpmyadmin et modification des droits pour respecter la sécurité de Suphp
cp -R /usr/share/phpmyadmin/* /home/phpmyadmin/public_html/
chown -R phpmyadmin:phpmyadmin /home/phpmyadmin/public_html/
chmod -R g-w,o-w /home/phpmyadmin/public_html/

# Backup du fichier de conf
if ! [ -f /etc/phpmyadmin/apache.conf.bkp ]; then
	cp -a /etc/phpmyadmin/apache.conf /etc/phpmyadmin/apache.conf.bkp
fi

# Configuration /etc/phpmyadmin/apache.conf
sed -i 's/\/usr\/share\/phpmyadmin/\/home\/phpmyadmin\/public_html/g' /etc/phpmyadmin/apache.conf

# Droit pour phpmyadmin sur certains fichiers
chgrp phpmyadmin /var/lib/phpmyadmin/blowfish_secret.inc.php
chgrp phpmyadmin /etc/phpmyadmin/config-db.php
chgrp phpmyadmin /etc/phpmyadmin/htpasswd.setup

# Configuration de vhost si domaine lié
echo -n "Souaitez-vous configurer un virtual host lié à votre domaine ? (o/N) : "
read VHOST
if [[ $VHOST = "o" || $VHOST = "O" ]]; then
	if [ -f phpmyadmin.vhost ]
		then
			echo -n "Quel FQDN pour accéder a phpmyadmin ? "
			read FQDN
			echo -n "Quel adresse mail technique ? "
			read MAIL
			mv phpmyadmin.vhost /etc/apache2/sites-available/
			mkdir /var/log/apache2/phpmyadmin
			sed -i 's/webmaster@localhost/'$MAIL'/g' /etc/apache2/sites-available/phpmyadmin.vhost
			sed -i 's/phpmyadmin.domain.tld/'$FQDN'/g' /etc/apache2/sites-available/phpmyadmin.vhost
			a2ensite phpmyadmin.vhost
		else
			echo "Le fichier phpmyadmin.vhost n'est pas present."
	fi	
fi

# Redémarrage d'Apache
service apache2 restart

# Fin du scripts