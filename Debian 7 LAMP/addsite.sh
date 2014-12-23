#!/bin/bash
# Script de création de compte pour site web
#
# Auteur :
# dwitgsi - 12/2014
VERSION="1.0"

# Test que le script est lance en root
if [ $EUID -ne 0 ]; then
  echo "Le script doit être lancé en root: # sudo $0" 1>&2
  exit 1
fi

# Création de l'utilisateur
#--------------------------
echo "Quel nom d'utilisateur souhaitez-vous creer ? "
read USER
USER=${USER,,} # En minuscule
echo "Mot de passe de l'utilisateur "$USER" : "
read -s PASS
echo "Adresse mail technique du site web : "
read MAIL
echo ""

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
mkdir /home/$USER/public_html
chown -R $USER:$USER /home/$USER/public_html
#--------------------------

# Configuration d'Apache
#-----------------------
mkdir /var/log/apache2/$USER
if [ -f site.vhost ]
	then
		cp site.vhost /etc/apache2/sites-available/$USER.vhost
	else
		echo "Le fichier site.vhost n'est pas present."
		exit 1
fi

# Configuration de vhost si domaine lié
echo -n "Souaitez-vous configurer un virtual host lié à votre domaine ? (o/N) : "
read VHOST
if [[ $VHOST = "o" || $VHOST = "O" ]]; then
	echo -n "Quel est le FQDN pour acceder au site "$USER" ? "
	read FQDN
	sed -i 's/#ServerName utilisateur.domaine.tld/ServerName '$FQDN'/g' /etc/apache2/sites-available/$USER.vhost
fi

sed -i 's/utilisateur/'$USER'/g' /etc/apache2/sites-available/$USER.vhost
sed -i 's/contact@domaine.tld/'$MAIL'/g' /etc/apache2/sites-available/$USER.vhost

a2ensite $USER.vhost
echo "Virtual host bien configure et active."

# Rechargement d'Apache
service apache2 reload
#-----------------------

# Configuration de MySQL
#-----------------------
echo "Creation de la base de donnees de "$USER"."
echo "create database $USER ; " > /tmp/$$.tmp.sql
echo "grant all on $USER.* to $USER@'localhost' identified by '$PASS' ; " >> /tmp/$$.tmp.sql
echo "exit " >> /tmp/$$.tmp.sql
echo " "
echo "Connexion MySQL ..."
echo " "
mysql -u root -p < /tmp/$$.tmp.sql
if ! [ $? = "0" ]
	then
		echo "Probleme de connexion MySQL"
	else
		echo "Base de donnees cree."
fi 
rm /tmp/$$.tmp.sql
#-----------------------

echo "Le site web "$USER" est pret a l'emploi."

# Fin du scripts