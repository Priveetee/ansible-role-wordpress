# Script fix-apache.sh
#!/bin/bash

echo "=== Correction Apache ==="

# Installer les outils nécessaires
echo "Installation des outils..."
ansible all -m package -a "name=procps state=present" --become
ansible all -m package -a "name=net-tools state=present" --become

# Corriger Apache Ubuntu
echo "Correction Apache Ubuntu..."
ansible wordpress-ubuntu -m shell -a "
service apache2 restart
sleep 2
service apache2 status
" --become

# Corriger Apache Rocky
echo "Correction Apache Rocky..."
ansible wordpress-rocky -m shell -a "
echo 'ServerName localhost' >> /etc/httpd/conf/httpd.conf
/usr/sbin/httpd -k stop || true
sleep 2
/usr/sbin/httpd -D FOREGROUND &
" --become

# Vérifier les résultats
echo "Vérification..."
sleep 5
curl -I http://localhost:8081
curl -I http://localhost:8082

echo "=== Fin des corrections ==="
