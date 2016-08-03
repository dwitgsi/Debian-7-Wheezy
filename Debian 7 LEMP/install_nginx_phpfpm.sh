#!/bin/bash
# Script d'installation et de configuration de nginx et php-fpm sur Debian 7.0 aka Wheezy
#
# Auteur :
# dwitgsi - 04/2015

#=============================================================================
# Liste des applications à installer
LISTE="nginx php5-fpm php-apcu php5-cgi php5-mysql php5-curl"
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
echo -n "Mettre a jour le système ? (o/N) : "
read UPGRADE
if [[ $UPGRADE = "o" || $UPGRADE = "O" ]]; then
	aptitude safe-upgrade
fi

# Installation
echo "Installation des logiciels suivants: $LISTE"
aptitude -y install $LISTE

# Configuration nginx
#--------------------

# Informations de nginx
echo "Suppression des informations de version de nginx"
if ! [ -f /etc/nginx/nginx.conf.bkp ]; then
	cp -a /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bkp
fi
sed -i 's/# server_tokens off;/server_tokens off;/g' /etc/nginx/nginx.conf

# Configuration PHP
echo "Configuration de PHP"
if ! [ -f /etc/php5/fpm/php.ini.bkp ]; then
	cp -a /etc/php5/fpm/php.ini /etc/php5/fpm/php.ini.bkp
fi
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php5/fpm/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 30M/g' /etc/php5/fpm/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 30M/g' /etc/php5/fpm/php.ini

# Statistiques APC
echo -n "Mettre les statistiques APC (cache PHP) ? (o/N) : "
read APC
if [[ $APC = "o" || $APC = "O" ]]; then
	if [ -f apc.php ]; then
		mv  apc.php /usr/share/nginx/www/
	else
		echo "Le fichier apc.php n'est pas present dans "$(pwd)"."
	fi
fi

# Configuration fail2ban pour nginx
if [ -f fail2ban/regles.txt ]; then
	cat fail2ban/regles.txt >> /etc/fail2ban/jail.conf
else
	echo "Le fichier regles.txt n'est pas present dans "$(pwd)"/fail2ban/."
fi
if [ -f fail2ban/nginx-auth.conf ]; then
	mv fail2ban/nginx-auth.conf /etc/fail2ban/filter.d/
else
	echo "Le fichier nginx-auth.conf n'est pas present dans "$(pwd)"/fail2ban/."
fi
if [ -f fail2ban/nginx-login.conf ]; then
	mv fail2ban/nginx-login.conf /etc/fail2ban/filter.d/
else
	echo "Le fichier nginx-login.conf n'est pas present dans "$(pwd)"/fail2ban/."
fi
if [ -f fail2ban/nginx-noscript.conf ]; then
	mv fail2ban/nginx-noscript.conf /etc/fail2ban/filter.d/
else
	echo "Le fichier nginx-noscript.conf n'est pas present dans "$(pwd)"/fail2ban/."
fi
if [ -f fail2ban/nginx-proxy.conf ]; then
	mv fail2ban/nginx-proxy.conf /etc/fail2ban/filter.d/
else
	echo "Le fichier nginx-proxy.conf n'est pas present dans "$(pwd)"/fail2ban/."
fi
if [ -f fail2ban/nginx-w00tw00t.conf ]; then
	mv fail2ban/nginx-w00tw00t.conf /etc/fail2ban/filter.d/
else
	echo "Le fichier nginx-w00tw00t.conf n'est pas present dans "$(pwd)"/fail2ban/."
fi


# Redémarrage des services
service nginx restart
service php5-fpm restart
service fail2ban restart

# Fin
#-----
echo "Pensez a modifier le firewall (/etc/init.d/firewall.sh) en ajoutant le port 80 et/ou 443 dans TCP_SERVICES."
# Fin du script