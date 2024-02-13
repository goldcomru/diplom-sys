Загружаю zabbix-server через   [ansible-zabbix-server.yml](https://github.com/goldcomru/diplom-sys/blob/main/files/ansible-playbook-zabbix-server.yml)

<details>

![image](https://github.com/goldcomru/SysAdmin/blob/main/db/ansiblezabbix.png)

</details>

Далее загружаю на zabbix машину docker и docker compose через [ansible-docker.yml](https://github.com/goldcomru/diplom-sys/blob/main/files/ansible-playbook-docker.yml)

<details>

![image](https://github.com/goldcomru/SysAdmin/blob/main/db/dockeransible.png)

</details>

Далее запускаю на нём контейнер с Mysql [compose.yml](https://github.com/goldcomru/diplom-sys/blob/main/files/compose.yml) через [ansible-db.yml](https://github.com/goldcomru/diplom-sys/blob/main/files/ansible-playbook-db.yml)

<details>

![image](https://github.com/goldcomru/SysAdmin/blob/main/db/dockeransible2.png)
![image](https://github.com/goldcomru/SysAdmin/blob/main/db/db1.png)
![image](https://github.com/goldcomru/SysAdmin/blob/main/db/db3.png)

</details>

Пытаюсь поставить настройки в контейнер исходя из инструкции с официального сайта Zabbix через [ansible-db-command.yml](https://github.com/goldcomru/diplom-sys/blob/main/files/ansible-playbook-db-command.yml). Однако здесь сталкиваюсь с проблемой - я не понимаю как в контейнер c базой данных нужно залить базу данных zabbix (и как можно использовать пайплайны через docker-compose exec) и как дать понять zabbix серверу где находится его база данных. В интернете ничего толкового не нашёл, прошу Вашей помощи.



