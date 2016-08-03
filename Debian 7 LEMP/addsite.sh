#!/bin/bash
# Script de création de compte pour site web
#
# Auteur :
# dwitgsi - 04/2015

# Test que le script est lance en root
if [ $EUID -ne 0 ]; then
  echo "Le script doit être lancé en root: # sudo $0" 1>&2
  exit 1
fi

#--------------------------
# Création de l'utilisateur
#--------------------------
echo "Quel nom d'utilisateur souhaitez-vous creer ? "
read USER
USER=${USER,,} # En minuscule
echo "Mot de passe de l'utilisateur "$USER" : "
read -s PASS

# Test si utilisateur existe
if grep "^$USER:" /etc/passwd > /dev/null;
then
	echo "L'utilisateur existe !"
	exit 1
else
	useradd -p $PASS -m -s /bin/bash $USER
	echo "Utilisateur "$USER" cree."
fi

# Création du répertoire web de l'utilisateur
mkdir /home/$USER/www
mkdir /home/$USER/tmp
mkdir -p /home/$USER/logs/nginx
mkdir /home/$USER/logs/php-fpm
mkdir /home/$USER/ssl
chown -R $USER:$USER /home/$USER/
chown root:root /home/$USER/ssl
usermod -a -G $USER www-data # Pour nginx

#-----------------------
# Configuration de nginx
#-----------------------

if [ -f site.vhost ]; then
	cp site.vhost /etc/nginx/sites-available/$USER
	sed -i 's/USER/'$USER'/g' /etc/nginx/sites-available/$USER
	echo "Quel est l'adresse du site web (FQDN) ?"
	read FQDN
	sed -i 's/SITEWEB/'$FQDN'/g' /etc/nginx/sites-available/$USER
	ln -s /etc/nginx/sites-available/$USER /etc/nginx/sites-enabled/$USER
	echo "Virtual host cree, configure et actif."
else
	echo "Le fichier site.vhost n'est pas present dans "$(pwd)"."
	echo "Vous devrez configurer le vhost manuellement."
fi

service nginx reload

#-------------------------
# Configuration de php-fpm
#-------------------------

if [ -f phpfpm.conf ]; then
	cp phpfpm.conf /etc/php5/fpm/pool.d/$USER.conf
	sed -i 's/USER/'$USER'/g' /etc/php5/fpm/pool.d/$USER.conf
	echo "Le pool php-fpm est bien configure."
else
	echo "Le fichier phpfpm.conf n'est pas present dans "$(pwd)"."
	echo "Vous devrez configurer le pool php-fpm manuellement."
fi

service php5-fpm reload

#-----------------------
# Configuration de MySQL
#-----------------------
CHECK="KO"

while [ $CHECK != "OK" ];
do
	echo "Utilisateur administrateur des bases de donnees ?"
	read ADMBDD
	echo "Creation de la base de donnees de "$USER"."
	echo "create database $USER ; " > /tmp/$$.tmp.sql
	echo "grant all on $USER.* to $USER@'localhost' identified by '$PASS' ; " >> /tmp/$$.tmp.sql
	echo "exit " >> /tmp/$$.tmp.sql
	echo " "
	echo "Connexion MySQL ..."
	echo " "
	mysql -u $ADMBDD -p < /tmp/$$.tmp.sql
	if ! [ $? = "0" ]
		then
			echo "Probleme de connexion MySQL."
		else
			echo "Base de donnees creee."
			CHECK="OK"
	fi 
	rm /tmp/$$.tmp.sql
done
#-----------------------

echo "Le site web "$FQDN" est pret a l'emploi."

# Fin du scripts