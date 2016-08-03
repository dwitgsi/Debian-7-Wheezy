#!/bin/bash
# Script d'installation et de configurationeur de MySQL sur Debian 7.0 aka Wheezy
#
# Auteur :
# dwitgsi - 04/2015

#=============================================================================
# Liste des applications à installer
LISTE="mysql-server php5-mysql mysql-common"
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

# Script post-install MySQL
/usr/bin/mysql_secure_installation

# Création du super utilisateur dans MySQL
echo "Creation du super utilisateur de MySQL."
USER=""
CHOIX=0

while [ $CHOIX != "OK" ];
do
	read -p "Utilisateur existant ? [1] - Creer un nouvel utilisateur ? [2]" CHOIX
	case $CHOIX in
		1)
			echo "Nom de l'utilisateur :"
			read USER
			# Test si utilisateur existe
			if grep "^$USER:" /etc/passwd > /dev/null;
			then
				echo "Utilisateur OK"
				echo "Mot de passe de l'utilisateur pour MySQL :"
				read -s PASS
				CHOIX="OK"
			else
				echo "L'utilisateur n'existe pas !"
			fi
		;;
		2)
			echo "Nom de l'utilisateur :"
			read USER
			# Test si utilisateur existe
			if grep "^$USER:" /etc/passwd > /dev/null;
			then
				echo "L'utilisateur existe !"
			else
				USER=${USER,,} # En minuscule
				echo "Mot de passe de l'utilisateur :"
				read -s PASS
				useradd -p $PASS -m -s /bin/false $USER
				echo "Utilisateur "$USER" cree."
				CHOIX="OK"
			fi
	esac
done

# Execution du script SQL
echo "use mysql;" > /tmp/$$.tmp.sql
echo "GRANT ALL PRIVILEGES ON *.* TO $USER@'localhost' IDENTIFIED BY '$PASS' WITH GRANT OPTION;" >> /tmp/$$.tmp.sql
echo "FLUSH PRIVILEGES;" >> /tmp/$$.tmp.sql
echo "exit " >> /tmp/$$.tmp.sql
echo " "
echo "Connexion MySQL ..."
echo " "
mysql -u root -p < /tmp/$$.tmp.sql
if ! [ $? = "0" ]
	then
		echo "Probleme de connexion MySQL"
	else
		echo "Super utilisateur cree."
		echo "-------------------------------"
		echo "Installation de MySQL terminee."
fi 
rm /tmp/$$.tmp.sql



# Fin du scripts