#!/bin/bash
# Script d'installation et de configurationeur PhpMyAdmin sur Debian 7.0 aka Wheezy
#
# Auteur :
# dwitgsi - 04/2015

#=============================================================================
# Liste des applications à installer
LISTE="phpmyadmin"
#=============================================================================

# Test que le script est lance en root
if [ $EUID -ne 0 ]; then
  echo "Le script doit être lancé en root: # sudo $0" 1>&2
  exit 1
fi

# Mise a jour de la liste des depots
#-----------------------------------

# Update 
echo "Mise a jour de la liste des depots"
aptitude update

# Upgrade
echo -n "Mettre a jour le systeme ? (o/N) : "
read UPGRADE
if [[ $UPGRADE = "o" || $UPGRADE = "O" ]]; then
	aptitude safe-upgrade
fi

# Installation
echo "Installation des logiciels suivants: $LISTE"
aptitude -y install $LISTE


# Configuration
#--------------

# Test si utilisateur existe
if grep "^phpmyadmin:" /etc/passwd > /dev/null;
then
	echo "Utilisateur phpmyadmin deja cree."
else
	# Création de l'utilisateur phpmyadmin
	echo -n "Mot de passe de l'utilisateur phpmyadmin : "
	read -s PASS
	echo ""
	useradd -p $PASS -m -s /bin/false phpmyadmin
fi

# Création des répertoires
mkdir /home/phpmyadmin/tmp
mkdir -p /home/phpmyadmin/logs/php-fpm
mkdir /home/phpmyadmin/logs/nginx
chown -R phpmyadmin:phpmyadmin /home/phpmyadmin

# Ajout de www-data dans le groupe phpmyadmin pour que nginx puisse exécuter les pages web
usermod -a -G phpmyadmin www-data

# Configuration de phpfpm pour phpmyadmin
if [ -f phpfpm.conf ]; then
	cp phpfpm.conf /etc/php5/fpm/pool.d/phpmyadmin.conf
	sed -i 's/USER/phpmyadmin/g' /etc/php5/fpm/pool.d/phpmyadmin.conf
else
	echo "Le fichier phpfpm.conf n'est pas present dans "$(pwd)"."
fi

# Ne pas autoriser l'authentification avec root
echo "\$cfg['Servers'][\$i]['AllowRoot'] = FALSE;" >> /etc/phpmyadmin/config.inc.php

# Droit pour phpmyadmin sur certains fichiers
chgrp phpmyadmin /var/lib/phpmyadmin/blowfish_secret.inc.php
chgrp phpmyadmin /etc/phpmyadmin/config-db.php
chgrp phpmyadmin /etc/phpmyadmin/htpasswd.setup

# Modification du virtual host

# Activation des pages d'erreurs
#LINENUMBER=$(grep -n 'error_page 500' /etc/nginx/sites-available/default | awk -F':' '{ print $1 }')
#sed -i ''$LINENUMBER',+3 s/^\t#/\t/g' /etc/nginx/sites-available/default

# Backup du vhost default et nouveau
if [ -f phpmyadmin.vhost ]; then
	if ! [ -f /etc/nginx/sites-available/default.bkp ]; then
		cp -a /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bkp
	fi
	mv phpmyadmin.vhost /etc/nginx/sites-available/default
else
	echo "Le fichier phpmyadmin.vhost n'est pas present dans "$(pwd)"."
fi

# Modification du propriétaire et groupe
chown -R phpmyadmin:phpmyadmin /usr/share/phpmyadmin
chown -R phpmyadmin:phpmyadmin /var/lib/phpmyadmin

# Redémarrage des services
service nginx restart
service php5-fpm restart

# Fin du script