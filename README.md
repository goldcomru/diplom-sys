#  Дипломная работа по профессии «Системный администратор» Попова А.В.

<details>

Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)
* [Выполнение работы](#Выполнение-работы)
* [Критерии сдачи](#Критерии-сдачи)
* [Как правильно задавать вопросы дипломному руководителю](#Как-правильно-задавать-вопросы-дипломному-руководителю) 

---------

## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible.  

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal  

Важно: используйте по-возможности **минимальные конфигурации ВМ**:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая. 

**Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.**

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh.  Эта вм будет реализовывать концепцию  [bastion host]( https://cloud.yandex.ru/docs/tutorials/routing/bastion) . Синоним "bastion host" - "Jump host". Подключение  ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью  [ProxyCommand](https://docs.ansible.com/ansible/latest/network/user_guide/network_debug_troubleshooting.html#network-delegate-to-vs-proxycommand) . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

### Дополнительно
Не входит в минимальные требования. 

1. Для Zabbix можно реализовать разделение компонент - frontend, server, database. Frontend отдельной ВМ поместите в публичную подсеть, назначте публичный IP. Server поместите в приватную подсеть, настройте security group на разрешение трафика между frontend и server. Для Database используйте [Yandex Managed Service for PostgreSQL](https://cloud.yandex.com/en-ru/services/managed-postgresql). Разверните кластер из двух нод с автоматическим failover.
2. Вместо конкретных ВМ, которые входят в target group, можно создать [Instance Group](https://cloud.yandex.com/en/docs/compute/concepts/instance-groups/), для которой настройте следующие правила автоматического горизонтального масштабирования: минимальное количество ВМ на зону — 1, максимальный размер группы — 3.
3. В Elasticsearch добавьте мониторинг логов самого себя, Kibana, Zabbix, через filebeat. Можно использовать logstash тоже.
4. Воспользуйтесь Yandex Certificate Manager, выпустите сертификат для сайта, если есть доменное имя. Перенастройте работу балансера на HTTPS, при этом нацелен он будет на HTTP веб-серверов.

## Выполнение работы
На этом этапе вы непосредственно выполняете работу. При этом вы можете консультироваться с руководителем по поводу вопросов, требующих уточнения.

⚠️ В случае недоступности ресурсов Elastic для скачивания рекомендуется разворачивать сервисы с помощью docker контейнеров, основанных на официальных образах.

**Важно**: Ещё можно задавать вопросы по поводу того, как реализовать ту или иную функциональность. И руководитель определяет, правильно вы её реализовали или нет. Любые вопросы, которые не освещены в этом документе, стоит уточнять у руководителя. Если его требования и указания расходятся с указанными в этом документе, то приоритетны требования и указания руководителя.

## Критерии сдачи
1. Инфраструктура отвечает минимальным требованиям, описанным в [Задаче](#Задача).
2. Предоставлен доступ ко всем ресурсам, у которых предполагается веб-страница (сайт, Kibana, Zabbix).
3. Для ресурсов, к которым предоставить доступ проблематично, предоставлены скриншоты, команды, stdout, stderr, подтверждающие работу ресурса.
4. Работа оформлена в отдельном репозитории в GitHub или в [Google Docs](https://docs.google.com/), разрешён доступ по ссылке. 
5. Код размещён в репозитории в GitHub.
6. Работа оформлена так, чтобы были понятны ваши решения и компромиссы. 
7. Если использованы дополнительные репозитории, доступ к ним открыт. 

## Как правильно задавать вопросы дипломному руководителю
Что поможет решить большинство частых проблем:
1. Попробовать найти ответ сначала самостоятельно в интернете или в материалах курса и только после этого спрашивать у дипломного руководителя. Навык поиска ответов пригодится вам в профессиональной деятельности.
2. Если вопросов больше одного, присылайте их в виде нумерованного списка. Так дипломному руководителю будет проще отвечать на каждый из них.
3. При необходимости прикрепите к вопросу скриншоты и стрелочкой покажите, где не получается. Программу для этого можно скачать [здесь](https://app.prntscr.com/ru/).

Что может стать источником проблем:
1. Вопросы вида «Ничего не работает. Не запускается. Всё сломалось». Дипломный руководитель не сможет ответить на такой вопрос без дополнительных уточнений. Цените своё время и время других.
2. Откладывание выполнения дипломной работы на последний момент.

</details>

# Выполнение работы

1. Все файлы (плейбуки, конфиг файлы, дата файл, хосты) для выполнения работы хранятся в папке `files`;   
2. Все операции по развёртке инфраструктуры выполнялись в Terraform и Ansible;
3. Ansible был установлен на Bastion host, ssh подключение к ВМ велось также с Bastion host;
4. Все конфигурационные файлы загружались через ansible-playbook соответствующего сервиса находящегося в папке `files`;
5. Группы безопасности создавались на каждом этапе, окончательные настройки портов выдавались после создания всей инфраструктуры через `terraform apply` соответствующего сервиса.


## Ход выполнения задания

Создаю VPC, внешнюю и внутреннюю подсеть, Bastion хост на базе NAT_instance, статичную маршрутизацию через ip Bastion хоста в [bastion.tf](https://github.com/goldcomru/diplom-sys/blob/main/files/bastion.tf)

<details>

![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/%D0%9F%D0%BE%D0%B4%D1%81%D0%B5%D1%82%D0%B8.png)

![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/bastion.png)

</details>

___

Создаю 2 web сервера, таргет и бэкэнд группы, http роутер и балансировщик в [nginx.tf](https://github.com/goldcomru/diplom-sys/blob/main/files/nginx.tf). 

<details>
   
![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/l7.png)

</details>

Далее по ssh подключаюсь к bastion и устанавливаю ansible. Создаю [ansible-playbook-nginx.yml](https://github.com/goldcomru/diplom-sys/blob/main/files/ansible-playbook-nginx.yml) и [index.nginx-debian.html](https://github.com/goldcomru/diplom-sys/blob/main/files/index.nginx-debian.html). Правлю файл [hosts](https://github.com/goldcomru/diplom-sys/blob/main/files/hosts) в /etc/ansible/hosts используя FQDN имена. Также правлю ansible.cfg поменяв `forks=10` и `host_key_checking=false` 

<details>
   
![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/nginx1.png)

</details>

Успешно устанавливаю nginx на web сервера 

<details>
   
![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/nginx2.png)

</details>

Проверяю доступность web серверов через ip балансировщика командой `curl -v 158.160.133.41:80`. Страничка также доступна по http://158.160.133.41/

<details>
   
![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/nginx3.png)
   
</details>

___

Создаю ВМ zabbix через [zabbix.tf](https://github.com/goldcomru/diplom-sys/blob/main/files/zabbix.tf). На bastion через плейбук [ansible-playbook-zabbix-server.yml](https://github.com/goldcomru/diplom-sys/blob/main/files/ansible-playbook-zabbix-server.yml) запускаю установку zabbix-server 6.0 на ubuntu 20.04.

<details>
   
![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/zabbixserver1.png)
   
</details> 

На этом этапе у меня возникла проблема с установкой PostgreSQL 13.14 через плейбук, пришлось подключаться к ВМ через SSH и ставить вручную. 

<details>
   
![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/psql.png)

</details>

Когда сервер был запущен и доступен, запустил [ansible-playbook-zabbix-agent.yml](https://github.com/goldcomru/diplom-sys/blob/main/files/ansible-playbook-zabbix-agent.yml) поменяв в файле [zabbix_agentd.conf](https://github.com/goldcomru/diplom-sys/blob/main/files/zabbix_agentd.conf) на внутренний (internal) ip сервера значение `Server=192.168.10.10`

<details>
   
![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/zabbixagent1.png)
   
</details>

После этого настроил Дашборды в Zabbix, на мой взгляд соответствующие требованиям. Однако я так нигде в шаблонах и не нашёл отслеживание http трафика, шаблон nginx http не реагирует.

<details>
   
![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/zabbixdash1.png)

![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/zabbixdash2.png)

![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/zabbixdash3.png)

</details>

----

Создаю ВМ Elasticsearch через [ansible-playbook-elastic.yml](https://github.com/goldcomru/diplom-sys/blob/main/files/ansible-playbook-elastic.yml). В [elasticsearch.yml](https://github.com/goldcomru/diplom-sys/blob/main/files/elasticsearch.yml) выставляю имя кластера 'popov-diplom'.

По команде `curl localhost:9200/_cluster/health?pretty` проверяю работоспособность.

<details>
   
![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/health.png)

</details>

----

Аналогичным образом создаю ВМ Kibana через [ansible-playbook-kibana.yml](https://github.com/goldcomru/diplom-sys/blob/main/files/ansible-playbook-kibana.yml). В [kibana.yml](https://github.com/goldcomru/diplom-sys/blob/main/files/kibana.yml) выставляю внутренний (internal) ip `elasticsearch.hosts=["http://192.168.20.6:9200"]`

В консоли Kibana `http://158.160.99.208:5601/app/dev_tools#/console` по команде `GET /_cluster/health?pretty` проверяю работоспособность.

<details>

![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/health2.png)

</details>

----

Абсолютно аналогичным образом загружаю агентов filebeat на все хосты через [ansible-playbook-filebeat.yml](https://github.com/goldcomru/diplom-sys/blob/main/files/ansible-playbook-filebeat.yml). В [filebeat.yml](https://github.com/goldcomru/diplom-sys/blob/main/files/filebeat.yml) выставляю Kibana внутренний (internal) ip `host: "192.168.10.18:5601"`, Elasticsearch `output.elasticsearch: hosts: ["192.168.20.6:9200"]`. Также прописываю пути ко всем логам на всех сервисах.

<details>
   
![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/logs.png)

</details>

Однако Kibana не видит только себя. Догадываюсь, что необходим Logstash, но его я решил не разворачивать.

<details>
   
![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/gdekibana.png)

</details>

----

Разворачиваю Snapshot через [snapshot.tf](https://github.com/goldcomru/diplom-sys/blob/main/files/snapshot.tf). Все снимки дисков ВМ запланированы на ежедневное копирование в течение недели.

<details>
   
![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/snapshot.png)

</details>

## Заключение

Согласно требованиям, web сервера и elasticsearch во время развёртки были помещены во внутреннюю подсеть. Сервера Zabbix, Kibana, балансировщика и Bastion host во время развёртки были помещены в публичную подсеть. Группы безопасности также настроены согласно требованиям:

<details>
   
![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/%D0%BE%D0%B1%D1%89%D0%B5%D0%B51.png)

</details>

В финале для Bastion host открываю единственный доступный порт - 22. 

<details>
   
![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/gs1.png)

![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/gs2.png)

![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/gs3.png)

![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/gs4.png)

![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/gs5.png)

</details>

**Сервисы доступны по ссылкам:**

1. Web сервера: http://158.160.133.41/
2. Zabbix-server: http://158.160.107.161/zabbix
3. Kibana: http://158.160.99.208:5601/

**Инфраструктура развёрнута**

![image](https://github.com/goldcomru/SysAdmin/blob/main/%D1%81%D0%BA%D1%80%D0%B8%D0%BD%D1%8B%20%D0%B4%D0%B8%D0%BF%D0%BB%D0%BE%D0%BC%D0%B0/%D0%BE%D0%B1%D1%89%D0%B5%D0%B5%20%D1%84%D0%B8%D0%BD%D0%B0%D0%BB1.png)

---

_Пробовал настроить HTTPS, но так окончательно и не разобрался с настройкой Бакетов и Балансировщика через Terraform. Я не нашёл правильной версии написания файла терраформа для балансировщика с перенаправлением на HTTPS_
