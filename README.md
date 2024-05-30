# AnsibleForWindows
Базовая настройка ПК под управлением Windows посредством Ansible

## Содержание
- [Подготовка](#подготовительный-этап)
- [Playbooks](#playbooks)

# Подготовительный этап
### Стартовый набор:

- ПК под уравлением Linux, либо же ПК под управлением Windows с WSL.
- Ansible + установленная библиотека для управления Windows-хостами.
- Целевой ПК (или группа ПК) с чистой Windows и доступом в интернет (хотя бы через Proxy).

### Подготовка целевых ПК
*В Powershell* от админа необходимо выполнить два скрипта, предварительно перед этим разрешить исполнение сценариев:
```ps
# Разрешить выполнение сценариев
Set-ExecutionPolicy RemoteSigned
# Разрешаем взаимодействие Windows+Ansible с помощью CredSSP
~/ConfigureRemotingForAnsible.ps1 -EnableCredSSP
# Пропишем Powershell в PATH
~/EditPath.ps1
```
### Подготовка ПК администратора
#### Файл hosts *(/etc/ansible/hosts)*
В этом файле указывается целевая группа компьютеров, на которых будет выполняться настройка параметров и установка софта:
```
all:
  hosts:
    *.*.*.*:
  vars:
    ansible_connection: winrm
    ansible_winrm_transport: credssp
    ansible_winrm_server_cert_validation: ignore
```

#### Playbooks *(/etc/ansible/playbooks/)*
В данной директории следует располагать нужные плейбуки, которые в дальнешем будут выполняться.

### Скрипты
Для корректного выполнения плейбуков, если не хочется их переписывать, необходимо разместить файл *etuconf.ps1* по пути *D:/Scripts/*

# Playbooks
### Настройка параметров Windows под ETU
```
ansible-playbook ConfigureETUPC.yml --ask-pass
```
Этот плейбук сделает следующие вещи:
- Запрашивает у пользователя пароль для учетной записи администратора, имя пользователя и пароль для подключения Ansible, а также новое имя компьютера.
- Активирует учетную запись администратора и здаает введенный пароль.
- Изменяет имя ПК на заданное.
- Настраивает сетевой адаптер (выключение IPv6, настройка DNS и т.д.).
- Изменяет параметры электропитания.
- Разбивает диск на C: объемом 200 ГБ и D:, который занимает весь оставшийся объем.
- Активирует Windows 10 Pro.
