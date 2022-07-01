#!/bin/bash
clear
echo "America/Sao_Paulo" > /etc/timezone
ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime > /dev/null 2>&1
dpkg-reconfigure --frontend noninteractive tzdata > /dev/null 2>&1
IP=$(wget -qO- ipv4.icanhazip.com)
clear
echo -e "\E[44;1;37m    INSTALAR ULTRAPANELSSH     \E[0m" 
echo ""
echo -ne "\n\033[1;32mESTABLEZCA UNA CONTRASEÑA PARA\033[1;33m MYSQL\033[1;37m: "; read senha
echo -ne "\n\033[1;32mESTABLEZCA UN DOMINIO\033[1;33m (panel.example.com)\033[1;37m: "; read domain
echo -ne "\n\033[1;32mESTABLEZCA UN CORREO\033[1;33m (admin@example.com)\033[1;37m: "; read mail
echo -e "\n\033[1;36mINICIANDO INSTALACION \033[1;33mESPERE..."
apt-get update -y > /dev/null 2>&1
apt-get install cron curl unzip -y > /dev/null 2>&1
echo -e "\n\033[1;36mINSTALANDO APACHE2 \033[1;33mESPERE...\033[0m"
apt-get install apache2 -y > /dev/null 2>&1
apt-get install php5 libapache2-mod-php5 php5-mcrypt -y > /dev/null 2>&1
apt-get install php-ssh2 -y > /dev/null 2>&1
service apache2 restart > /dev/null 2>&1
echo -e "\n\033[1;36mINSTALANDO MYSQL \033[1;33mESPERE...\033[0m"
echo "debconf mysql-server/root_password password $senha" | debconf-set-selections
echo "debconf mysql-server/root_password_again password $senha" | debconf-set-selections
apt-get install mysql-server -y > /dev/null 2>&1
mysql_install_db > /dev/null 2>&1
(echo $senha; echo n; echo y; echo y; echo y; echo y)|mysql_secure_installation > /dev/null 2>&1
echo -e "\n\033[1;36mGENERANDO CERTIFICADO SSL\033[1;33mESPERE...\033[0m"
sudo apt install certbot python3-certbot-apache -y > /dev/null 2>&1
certbot --nginx --redirect --no-eff-email --email "$mail" -d "$domain"  > /dev/null 2>&1
echo -e "\n\033[1;36mINSTALANDO PHPMYADMIN \033[1;33mESPERE...\033[0m"
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $senha" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $senha" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $senha" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
apt-get install phpmyadmin -y > /dev/null 2>&1
php5enmod mcrypt > /dev/null 2>&1
service apache2 restart > /dev/null 2>&1
ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
apt-get install libssh2-1-dev libssh2-php -y > /dev/null 2>&1
if [ "$(php -m |grep ssh2)" = "ssh2" ]; then
  true
else
  clear
  echo -e "\033[1;31m ERROR CRITICO\033[0m"
  echo -e "\033[1;31m Contactar con NovaNetwork\033[0m"
  rm $HOME/install.sh
  exit
fi
apt-get install php5-curl > /dev/null 2>&1
service apache2 restart > /dev/null 2>&1
clear
echo ""
echo -e "\033[1;31m ATENCION \033[1;33m!!!"
echo ""
echo -ne "\033[1;32m INGRESE LA CONTRASEÑA MYSQL\033[1;37m: "; read senha
sleep 1
mysql -h localhost -u root -p$senha -e "CREATE DATABASE sshplus"
clear
echo -e "\033[1;36m FINALIZANDO INSTALACION\033[0m"
echo ""
echo -e "\033[1;33m ESPERE..."
echo ""

cd /var/www/html
wget https://www.dropbox.com/s/sjzgmbjkrzxa5wc/v20.zip > /dev/null 2>&1
unzip v20.zip > /dev/null 2>&1
rm -rf v20.zip index.html > /dev/null 2>&1
service apache2 restart > /dev/null 2>&1
sleep 1
if [[ -e "/var/www/html/pages/system/pass.php" ]]; then
sed -i "s;1010;$senha;g" /var/www/html/pages/system/pass.php > /dev/null 2>&1
fi
sleep 1
cd
wget https://raw.githubusercontent.com/KalixCloud/ULTRAPANELSSH/main/banco.sql > /dev/null 2>&1
sleep 1
if [[ -e "$HOME/banco.sql" ]]; then
    mysql -h localhost -u root -p$senha --default_character_set utf8 sshplus < banco.sql
    rm /root/banco.sql
else
    clear
    echo -e "\033[1;31m ERROR AL IMPORTAR BASE DE DATOS\033[0m"
    sleep 2
    rm /root/install.sh > /dev/null 2>&1
    exit
fi
service apache2 restart > /dev/null 2>&1
clear
echo '* * * * * root /usr/bin/php /var/www/html/pages/system/cron.php' >> /etc/crontab
echo '* * * * * root /usr/bin/php /var/www/html/pages/system/cron.ssh.php ' >> /etc/crontab
echo '* * * * * root /usr/bin/php /var/www/html/pages/system/cron.sms.php' >> /etc/crontab
echo '* * * * * root /usr/bin/php /var/www/html/pages/system/cron.online.ssh.php' >> /etc/crontab
echo '10 * * * * root /usr/bin/php /var/www/html/pages/system/cron.servidor.php' >> /etc/crontab
echo '*/30 * * * * root /usr/bin/php /var/www/html/pages/system/cron.limpeza.php' >> /etc/crontab
echo '*/1 * * * * root /bin/html.sh' >> /etc/crontab
cd /bin
wget https://raw.githubusercontent.com/KalixCloud/ULTRAPANELSSH/main/html.sh > /dev/null 2>&1 && chmod 777 html.sh && sed -i -e 's/\r$//' html.sh && ./html.sh
/etc/init.d/cron reload > /dev/null 2>&1
/etc/init.d/cron restart > /dev/null 2>&1
cd
chmod 777 /var/www/html/admin/pages/servidor/ovpn
chmod 777 /var/www/html/admin/pages/download
chmod 777 /var/www/html/admin/pages/faturas/comprovantes
service apache2 restart > /dev/null 2>&1
clear
echo -e "\033[1;32m PANEL INSTALADO CON EXITO!"
echo ""
echo -e "\033[1;36m SU PANEL:\033[1;37m https://$domain/admin\033[0m"
echo -e "\033[1;36m USUARIO:\033[1;37m ultrapanel\033[0m"
echo -e "\033[1;36m CONTRASEÑA:\033[1;37m admin\033[0m"
echo ""
echo -e "\033[1;33m Al ingresar al panel combie la contraseña en >> Configuracion >> Contraseña Anterior: admin >> Nueva Contraseña: \033[0m"
cat /dev/null > ~/.bash_history && history -c
rm /root/install
