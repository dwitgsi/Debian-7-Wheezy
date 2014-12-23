#!/bin/bash
# Mon script de post installation serveur Debian 7.0 aka Wheezy
#
# Sources :
# Nicolargo - 05/2013
# GPL
#
# Ajusté par dwitgsi - 12/2014
#
# Syntaxe: # su - -c "./wheezyserverpostinstall.sh"
# Syntaxe: or # sudo ./wheezyserverpostinstall.sh
VERSION="1.0"

#=============================================================================
# Liste des applications à installer: A adapter a vos besoins
# Voir plus bas les applications necessitant un depot specifique
# Securite
LISTE="cron-apt fail2ban logwatch lsb-release vim postfix"
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
echo "Mise a jour du systeme"
aptitude safe-upgrade

# Installation
echo "Installation des logiciels suivants: $LISTE"
aptitude -y install $LISTE

# Configuration
#--------------

# Pour éviter les messages de Warning de Perl
# Source: http://charles.lescampeurs.org/2009/02/24/debian-lenny-and-perl-locales-warning-messages
dpkg-reconfigure locales

echo -n "Adresse mail pour les rapports de securite: "
read MAIL 
# cron-apt
cp -a /etc/cron-apt/config /etc/cron-apt/config.bkp
# sed -i 's/# MAILTO="root"/MAILTO="'$MAIL'"/g' /etc/cron-apt/config
echo "APTCOMMAND=/usr/bin/aptitude" >> /etc/cron-apt/config
echo "MAILTO="$MAIL"" >> /etc/cron-apt/config
# fail2ban
cp -a /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf.bkp
sed -i 's/destemail = root@localhost/destemail = '$MAIL'/g' /etc/fail2ban/jail.conf
# logwatch
mkdir /root/backups
cp -a /etc/cron.daily/00logwatch /root/backups/00logwatch.bkp
sed -i 's/logwatch --output mail/logwatch --mailto '$MAIL' --detail high/g' /etc/cron.daily/00logwatch

# Déplacement et activation du service firewall.sh
if [ -f firewall.sh ]; then
	mv firewall.sh /etc/init.d/
fi
if [ -f /etc/init.d/firewall.sh ]
	then
		update-rc.d firewall.sh defaults 20
	else
		echo "Le script firewall.sh n'est pas present."
fi

# Autres actions
echo "Autres action à faire si besoin:"
echo "- Securiser le serveur avec un Firewall"
echo "  > http://www.debian.org/doc/manuals/securing-debian-howto/ch-sec-services.en.html"
echo "  > https://raw.github.com/nicolargo/debianpostinstall/master/firewall.sh"
echo "- Securiser le daemon SSH"
echo "  > http://www.debian-administration.org/articles/455"
echo "- Permettre l'envoi de mail"
echo "  > http://blog.nicolargo.com/2011/12/debian-et-les-mails-depuis-la-ligne-de-commande.html"

# Fin du script