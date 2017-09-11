# vulture3-letsencrypt


Créez le répertoire qui va bien :
 
mkdir -p /home/vlt-sys/Engine/static/.well-known/acme-challenge/<br />
chown daemon:daemon /home/vlt-sys/Engine/static/.well-known/acme-challenge/<br />
chmod 550 /home/vlt-sys/Engine/static/.well-known/acme-challenge/<br />
 
Ajoutez ce répertoire dans le template /home/vlt-gui/vulture/vulture_toolkit/templates/vulture_httpd.conf, ligne 579.
Votre configuration doit ressembler à ça (Très important d’avoir les 2 sections Directory avec le deuxième en « denied ») :

<Directory /home/vlt-sys/Engine/static/ ><br />
        Require all granted<br />
</Directory><br />
<Directory /home/vlt-sys/Engine><br />
       Require all denied<br />
</Directory><br />


 
Ensuite vous faites une règle de réécriture pour dire à vulture de servir localement le répertoire /.well-known/

En SSH : 

Installer acme-client

pkg install acme-client


Lancer la création du challenge :


acme-client -vNmnC /home/vlt-sys/Engine/static/.well-known/acme-challenge/ www.mon-domaine.fr mondomaine.fr


Importer le certificat dans les PKI vulture
Créer le profile correspondant, l'appliquer à votre application puis recharger les interfaces HTTPS

Pour mettre à jour régulèrement le certificat let's encrypt, il faut placer le script generation.sh sur votre serveur.
Se connecter en root : sudo su<br />
editer le crontab : crontab -e<br />
et mettre : <br />
* * */30 * * /bin/sh /chemin_du_script/generation.sh<br />


