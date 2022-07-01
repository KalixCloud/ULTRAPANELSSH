#!/bin/bash
clear
echo "America/Sao_Paulo" > /etc/timezone
ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata
rm *.sh > /dev/null 2>&1
apt install unzip -y > /dev/null 2>&1
wget sshplus.xyz/scripts/utilitarios/syncpainel/modulos.zip > /dev/null 2>&1
unzip modulos.zip > /dev/null 2>&1
chmod 777 *sh
service ssh restart
echo -e "\n\033[1;32mINSTALACION COMPLETADA!\033[0m"
sleep 1.5
cat /dev/null > ~/.bash_history && history -c && clear
echo -e "\033[1;36mENTRA EN EL DASHBOARD Y CREA UNA CUENTA SSH PARA VER SI TODO ESTÁ BIEN!\033[0m"
rm inst modulos.zip > /dev/null 2>&1