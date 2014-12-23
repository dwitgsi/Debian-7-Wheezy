#!/bin/bash
# Script de configuration de vim
#
# Auteur :
# dwitgsi - 12/2014
VERSION="1.0"

# Emplacement du fichier de configuration
FILE="/etc/vim/vimrc"

# Test que le script est lance en root
if [ $EUID -ne 0 ]; then
  echo "Le script doit être lancé en root: # sudo $0" 1>&2
  exit 1
fi

# Backup du fichier de configuration s'il n'existe pas
if ! [ -f $FILE.bkp ]; then
	cp -a $FILE $FILE.bkp
	echo "Creation de "$FILE".bkp"
fi

# Activation de la coloration syntaxique
LINENUMBER=$(grep -n '\"syntax on' $FILE | awk -F':' '{ print $1 }')
sed -i ''$LINENUMBER',+0 s/^\"//g' $FILE

# Même emplacement à la réouverture du fichier
LINENUMBER=$(grep -n 'BufReadPost' $FILE | awk -F':' '{ print $1 }')
LINENUMBER=$((--LINENUMBER))
sed -i ''$LINENUMBER',+2 s/^\"//g' $FILE

# Utilisation de la souris
LINENUMBER=$(grep -n 'set mouse=a' $FILE | awk -F':' '{ print $1 }')
sed -i ''$LINENUMBER',+0 s/^\"//g' $FILE

# Ajout d'une ligne horizontale à l'emplacement du curseur
echo "\" Ligne horizontale" >> $FILE
echo "set cursorline" >> $FILE
echo "highlight CursorLine guibg=#001000" >> $FILE

# Fin de script