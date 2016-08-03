#!/bin/bash
# Script de g�n�ration de CSR pour certificat non-autog�n�r�
#
# Auteur :
# dwitgsi - 04/2015

# Test que le script est lance en root
if [ $EUID -ne 0 ]; then
  echo "Le script doit �tre lanc� en root: # sudo $0" 1>&2
  exit 1
fi

# Utilisateur du site
echo "Quel est le nom d'utilisateur du site ? "
read USER
USER=${USER,,} # En minuscule

# FQDN du site
echo "Quel est le FQDN du site web ?"
read FQDN

# Test du dossier ssl
if [ ! -d "/home/"$USER"/ssl" ]; then
	REP=o
	echo "Le dossier /home/"$USER"/ssl n'existe pas. Souhaitez-vous le creer ? (O/n) : "
	read REP
	if [[ $REP = "o" || $REP = "O" ]]; then
		mkdir /home/$USER/ssl
	fi
fi

# Exemple de r�ponses
echo "Voici un exemple de reponse : "
echo ""
echo "Country Name (2 letter code) [AU]: FR"
echo "State or Province Name (full name) [Some-State]: ."
echo "Locality Name (eg, city) []: Nantes"
echo "Organization Name (eg, company) [Internet Widgits Pty Ltd]: MaSoci�t�"
echo "Organizational Unit Name (eg, section) []: IT"
echo "Common Name (eg, YOUR name) []: sousdomaine.domaine.tld"
echo "Email Address []: technique@domaine.tld"
echo "A challenge password []: <- Optionnel"
echo "An optional company name []:"

# G�n�ration du CSR et de la cl� priv�e
openssl req -nodes -newkey rsa:2048 -sha256 -keyout /home/$USER/ssl/$FQDN.key -out /home/$USER/ssl/$FQDN.csr

# Affiche le CSR
echo "Contenu du CSR :"
echo ""
cat /home/$USER/ssl/$FQDN.csr

# Fin du script