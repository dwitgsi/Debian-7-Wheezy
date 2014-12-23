#!/bin/bash
# Script d'installation et de configurationeur de PHP
# Sécurisation avec SuExec et SuPhp
#
# Auteur :
# dwitgsi - 12/2014
VERSION="1.0"

#=============================================================================
# Liste des applications à installer
LISTE="libapache2-mod-php5 php5 php5-common php5-curl php5-dev php5-gd php5-idn php-pear php5-imagick php5-imap php5-json php5-mcrypt php5-memcache php5-mhash php5-ming php5-mysql php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl php-apc"
#=============================================================================

# Test que le script est lance en root
if [ $EUID -ne 0 ]; then
  echo "Le script doit être lancé en root: # sudo $0" 1>&2
  exit 1
fi

# Mise à jour de la liste des depots
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

# Redémarrage d'Apache
service apache2 restart

# Configuration
#--------------

# Php5
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 10M/g' /etc/php5/apache2/php.ini

# Installation SuExec et SuPhp et configuration
echo "Installation de SuExec et SuPhp"
aptitude -y install apache2-suexec-custom libapache2-mod-suphp

# Suexec
if ! [ -f /etc/apache2/suexec/www-data.bkp ]; then
	cp -a /etc/apache2/suexec/www-data /etc/apache2/suexec/www-data.bkp
fi
sed -i 's/\/var\/www/\/home/g' /etc/apache2/suexec/www-data
sed -i 's/public_html\/cgi-bin/public_html/g' /etc/apache2/suexec/www-data

# Suphp
if ! [ -f /etc/suphp/suphp.conf.bkp ]; then
	cp -a /etc/suphp/suphp.conf /etc/suphp/suphp.conf.bkp
fi
sed -i 's/check_vhost_docroot=true/check_vhost_docroot=false/g' /etc/suphp/suphp.conf
sed -i 's/umask=0077/umask=0022/g' /etc/suphp/suphp.conf

a2dismod php5
a2enmod suexec
a2enmod suphp

# Supprime la ligne commentée pour éviter les erreurs
sed '/#/d' /etc/php5/cgi/conf.d/ming.ini

# Backup du php.ini de PHP-CGI
if ! [ -f /etc/php5/cgi/php.ini.bkp ]; then
	cp -a /etc/php5/cgi/php.ini /etc/php5/cgi/php.ini.bkp
fi

# Remplacement du php.ini de PHP-CGI par celui de PHP5
cp /etc/php5/apache2/php.ini /etc/php5/cgi/php.ini

# Redémarrage du service apache
service apache2 restart

# Fin du scripts