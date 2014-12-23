#!/bin/bash
# Script d'installation et de configurationeur de MySQL et PhpMyAdmin sur Debian 7.0 aka Wheezy
#
# Auteur :
# dwitgsi - 12/2014
VERSION="1.0"

#=============================================================================
# Liste des applications � installer
LISTE="mysql-server phpmyadmin"
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

# Cr�ation de l'utilisateur phpmyadmin
echo -n "Mot de passe de l'utilisateur phpmyadmin : "
read -s PASS
echo ""
useradd -p $PASS -m -s /bin/bash phpmyadmin

# Cr�ation du r�pertoire web de phpmyadmin
mkdir /home/phpmyadmin/public_html

# Copie des fichiers de phpmyadmin et modification des droits pour respecter la s�curit� de Suphp
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

# Configuration de vhost si domaine li�
echo -n "Souaitez-vous configurer un virtual host li� � votre domaine ? (o/N) : "
read VHOST
if [[ $VHOST = "o" || $VHOST = "O" ]]; then
	if [ -f phpmyadmin.vhost ]
		then
			echo -n "Quel FQDN pour acc�der a phpmyadmin ? "
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

# Red�marrage d'Apache
service apache2 restart

# Fin du scripts