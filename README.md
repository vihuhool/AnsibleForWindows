# AnsibleForWindows
Базовая настройка ПК под управлением Windows посредством Ansible

## Содержание
- [Подготовка](#подготовительный-этап)

# Подготовительный этап
### Стартовый набор:

- ПК под уравлением Linux, либо же ПК под управлением Windows с WSL.
- Ansible + установленная библиотека для управления Windows-хостами.
- Целевой ПК (или группа ПК) с чистой Windows и доступом в интернет (хотя бы через Proxy).

#### Подготовка целевых ПК
*В Powershell* от админа необходимо выполнить два скрипта, предварительно перед этим разрешить исполнение сценариев:
```ps
# Разрешить выполнение сценариев
Set-ExecutionPolicy RemoteSigned
# Разрешаем взаимодействие Windows+Ansible с помощью CredSSP
~/ConfigureRemotingForAnsible.ps1 -EnableCredSSP
# Пропишем Powershell в PATH
~/EditPath.ps1
```

#### Файл hosts (/etc/ansible/hosts)
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

#### Playbooks (/etc/ansible/playbooks/*)
В данной директории следует располагать нужные плейбуки, которые в дальнешем будут выполняться.
