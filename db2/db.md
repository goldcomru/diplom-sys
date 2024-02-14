Успешно запускаю создание zabbix сервера

![image](https://github.com/goldcomru/SysAdmin/blob/main/db/1.png)

Но при создании с network_mode: host сервер не хочет подключаться к БД. Без этого параметра всё хорошо. В чём причина я так и не нашёл 
         
![image](https://github.com/goldcomru/SysAdmin/blob/main/db/2.png)

Хотя все 3 контейнера в 1 сети, они продолжают не видеть друг друга в network_mode: host

![image](https://github.com/goldcomru/SysAdmin/blob/main/db/3.png)         
