#!/bin/bash
# Script de configuration de bash
#
# Auteur :
# dwitgsi - 12/2014
VERSION="1.0"

# Test que le script est lance en root
if [ $EUID -ne 0 ]; then
  echo "Le script doit être lancé en root: # sudo $0" 1>&2
  exit 1
fi

# Demande le nom d'utilisateur non root
echo -n "Nom de l'utilisateur non root : "
read USER
# Test si utilisateur existe
if grep "^$USER:" /etc/passwd > /dev/null;
then
	echo "Utilisateur OK"
else
	echo "L'utilisateur n'existe pas !"
	exit 1
fi

# Initialisation des variables
FILE_ROOT="/root/.bashrc"
FILE_USER="/home/"$USER"/.bashrc"

# Backups des fichiers de configuration s'ils n'éxistent pas
if ! [ -f $FILE_ROOT.bkp ]; then
	cp -a $FILE_ROOT $FILE_ROOT.bkp
	echo "Creation de "$FILE_ROOT".bkp"
fi
if ! [ -f $FILE_USER.bkp ]; then
	cp -a $FILE_USER $FILE_USER.bkp
	echo "Creation de "$FILE_USER".bkp"
fi

# Quelques alias
echo "" >> $FILE_ROOT
echo "" >> $FILE_USER
echo "# Alias" >> $FILE_ROOT
echo "# Alias" >> $FILE_USER
echo "alias ll='ls -ahl --color=auto'" >> $FILE_ROOT
echo "alias ll='ls -ahl --color=auto'" >> $FILE_USER
echo "" >> $FILE_ROOT
echo "" >> $FILE_USER

#==========================================================================
# Customisation du prompt root

# Test de la présence du fichier de customisation
if [ -f promptcusto.txt ]
then
	echo "# Customisation du prompt" >> $FILE_ROOT
	echo "# Customisation du prompt" >> $FILE_USER
	cat promptcusto.txt >> $FILE_ROOT
	cat promptcusto.txt >> $FILE_USER
else
	echo "Le fichier promptcusto.txt n'est pas present."
fi
#==========================================================================

# Fin du script