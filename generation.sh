#!/bin/sh
# Constantes
CHALLENGE_PATH="/home/vlt-sys/Engine/static/.well-known/acme-challenge/"
PATH_CERT_VULTURE="/home/vlt-sys/Engine/conf/"
PATH_CERT_ACME="/usr/local/etc/ssl/acme/"
TargetDB="vulture"
TargetCol="s_s_l_certificate"
TargetField="cn"

domaine=$1

cat /dev/null > certfiledomaine.txt

RED='\e[38;32m'
NC='\e[33;0m' # No Color

# verification de l'environnement
# Il faut que le repertoire /home/vlt-sys/Engine/static/.well-known/acme-challenge/ existe
# Si ce n'est pas le cas, il faut creer l'arborescence

if [ ! -d $CHALLENGE_PATH ]; then

mkdir -p /home/vlt-sys/Engine/static/.well-known/acme-challenge/
chown daemon:daemon /home/vlt-sys/Engine/static/.well-known/acme-challenge/
chmod 550 /home/vlt-sys/Engine/static/.well-known/acme-challenge/

fi

# Verification que le template vulture est bien configure

grep "<Directory \/home\/vlt-sys\/Engine\/static\/>" /home/vlt-gui/vulture/vulture_toolkit/templates/vulture_httpd.conf

if [ $? -ne 0 ]
  then
   sed -i '.bkp' 's/<Directory \/home\/vlt-sys\/Engine>/<Directory \/home\/vlt-sys\/Engine\/static\/>\
        Require all granted\
    <\/Directory>\
    <Directory \/home\/vlt-sys\/Engine>/g' /home/vlt-gui/vulture/vulture_toolkit/templates/vulture_httpd.conf
fi



# Recuperation de tous les sous-domaine utilisant lets encrypt

certfile=''
domaine=''
count=0
for i in `ls -1 "$PATH_CERT_VULTURE""SSLCertificateFile"*`
do

  openssl x509 -text -noout -in "$i" | grep letsencrypt > /dev/null

  if [ $? -eq 0 ]
  then
    certfile=$i
    domaine=`openssl x509 -text -noout -in "$i" | grep DNS | cut -f2 -d:`

        # On lance la commande de mise a jour des certificats

        resultat=`acme-client -vFNnmC /home/vlt-sys/Engine/static/.well-known/acme-challenge/ $domaine`

        # On traite pour remplacer le certificat importe dans Vulture

        # Creation du fichier certificat
        cat $PATH_CERT_ACME$domaine"/cert.pem" > $certfile
        cat $PATH_CERT_ACME$domaine"/chain.pem" >> $certfile
        echo -e "Le fichier $certfile du sous-domaine ${RED}$domaine${NC} a bien ete mis a jour"
		
		# Modification du certificat dans la base de données MongoDB :
		certcontenu=`awk 'NF {sub(/\r/, ""); printf "%s",$0;}' "$PATH_CERT_ACME""$domaine""/cert.pem"`
		certexpdate=$(openssl x509 -text -noout -enddate -in "$PATH_CERT_ACME""$domaine""/cert.pem" | grep notAfter | cut -f2 -d=)

		dateformat=$(/bin/date -j -f "%b %d %T %Y %Z" "$certexpdate" "+%Y-%m-%d %H:%M:%S")

		certexpdate="$dateformat+00:00"
		
		certfrom=$(openssl x509 -text -noout -dates -in "$PATH_CERT_ACME""$domaine""/cert.pem" | grep notBefore | cut -f2 -d=)

        dateformat=$(/bin/date -j -f "%b %d %T %Y %Z" "$certfrom" "+%Y-%m-%d %H:%M:%S")

        certfrom="$dateformat+00:00"

		exp="db.s_s_l_certificate.update({\"cn\" : \""$domaine"\",\"issuer\" : \"/C=US/O=Let"\'"s Encrypt/CN=Let"\'"s Encrypt Authority X3\" }, {\$set : {\"cert\" : \""$certcontenu"\",\"validtill\" : \""$certexpdate"\",\"validfrom\" : \""$certfrom"\"}})"
		echo -e $exp > test.js
		mongo --ssl `hostname`:9091/$TargetDB --sslPEMKeyFile /var/db/mongodb/mongod.pem --sslCAFile /var/db/mongodb/ca.pem < test.js
		

		
		
 fi

done

echo /dev/null > test.js

# Recharger les interfaces HTTPS
for ii in `ls -1 "$PATH_CERT_VULTURE"*"-443.conf"`
do
 /home/vlt-sys/Engine/bin/httpd -f "$ii" -k graceful
 echo -e "rechargement des interfaces https ${RED}$ii${NC}"
done
