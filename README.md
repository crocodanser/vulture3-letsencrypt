# vulture3-letsencrypt


Créez le répertoire qui va bien :
 
<code>mkdir -p /home/vlt-sys/Engine/static/.well-known/acme-challenge/
chown daemon:daemon /home/vlt-sys/Engine/static/.well-known/acme-challenge/
chmod 550 /home/vlt-sys/Engine/static/.well-known/acme-challenge/</code>
 
Ajoutez ce répertoire dans le template /home/vlt-gui/vulture/vulture_toolkit/templates/vulture_httpd.conf, ligne 579.
Votre configuration doit ressembler à ça (Très important d’avoir les 2 sections Directory avec le deuxième en « denied ») :
<code> 
<Directory /home/vlt-sys/Engine/static/ >
        Require all granted
</Directory>
<Directory /home/vlt-sys/Engine>
       Require all denied
</Directory>
</code>

 
Ensuite vous faites une règle de réécriture pour dire à vulture de servir localement le répertoire /.well-known/

En SSH : 

Installer acme-client
<code>
pkg install acme-client
</code>

Lancer la création du challenge :

<code>
acme-client -vNmnC /home/vlt-sys/Engine/static/.well-known/acme-challenge/ www.mon-domaine.fr mondomaine.fr
</code>

Importer le certificat dans les PKI vulture
Créer le profile correspondant, l'appliquer à votre application puis recharger les interfaces HTTPS

Pour mettre à jour régulèrement le certificat let's encrypt, il faut placer le script generation.sh sur votre serveur.
Se connecter en root : sudo su
editer le crontab : crontab -e
et mettre : 
* * */30 * * /bin/sh /chemin_du_script/generation.sh


