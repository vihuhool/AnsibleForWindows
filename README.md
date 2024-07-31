# AnsibleForWindows
Базовая настройка ПК под управлением Windows посредством Ansible

## Содержание
+ [Подготовка](#подготовительный-этап)
+ [Playbooks](#playbooks)
  - [Настройка параметров Windows под ETU](#настройка-параметров-windows-под-etu).
  - [Установка бесплатных приложений](#установка-бесплатных-приложений).


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
Разберем по шагам, что делает этот плейбук:
#### 1. Переменные
```ps
vars_prompt:
    - name: admin_password
      prompt: "Enter the password for the Administrator account" # Задаем пароль для локального администратора
      private: yes
    - name: ansible_user
      prompt: "Enter the username for the Ansible connection" # Здесь нужно указать пользовтеля для подключения. Если рабочая станция в домене - подойдет доменный админ, иначе - можно выполнить под автоматически созданной при установке системы учеткой User\Test
      private: yes
    - name: ansible_password
      prompt: "Enter the password for the Ansible connection"  # Пароль от учетки, от имени которой будет выполняться плейбук
      private: yes
    - name: new_computer_name
      prompt: "Enter new computer name" # Новое имя компьютера (Не вводит в домен, но если комп уже в домене, то с правами доменного админа имя будет изменено)
      private: no
```
#### 2. Задачи

2.1. Создание временного расположения
```ps
   - name: Create Temp directory on remote host
    win_file:
      path: C:\Temp
      state: directory
```
2.2. Активация учетной записи локального администратора
```ps
  - name: Copy PowerShell script to configure Administrator
    win_copy:
      content: |
        $password = ConvertTo-SecureString "{{ admin_password }}" -AsPlainText -Force
        Set-LocalUser -Name Administrator -Password $password
        Enable-LocalUser -Name Administrator
      dest: C:\Temp\configure_admin.ps1

  - name: Run PowerShell script to configure Administrator
    win_shell: powershell.exe -ExecutionPolicy ByPass -File C:\Temp\configure_admin.ps1
```
2.3. Стандратная настройка ПК для ETU
```ps
  - name: Copy PowerShell script to change computer name
    win_copy:
      src: /mnt/d/Scripts/etuconf.ps1
      dest: C:\Temp\new_pc.ps1
      force: yes
```
Скрипт выполнит следующее:
- настрйока сетевого адапетра (dns, ipv6 off...);
- настройка параметров электропитания;
- включение SMB1 Client;
- разметка дискового пространства (200 Gb под систему, остальное под D:).
 
2.4. Переимнование рабочей станции
```ps
  - name: Run PowerShell script to change computer name
    win_shell: | Rename-Computer -NewName "{{ new_computer_name }}" -Force -Restart
    when: new_computer_name != ""
```
2.5. Завершение работы скрипта
```ps
  - name: Wait for the machine to reboot
    wait_for_connection:
      delay: 300 # Периодичность проверки подключения после перезагрузки (в секундах)
      sleep: 60 # Время ожидания подключения после перезагрузки (в секундах), в данном случае 5 минут

  - name: Delete C:\Temp
    win_file:
      path: C:\Temp
      state: absent
```
### Установка бесплатных приложений
```
ansible-playbook freesoft.yml --ask-pass
```
С помощью данного плейбука монжо установить следующий список приложений посредством Chocolatey:
- Mozilla Firefox
- Yandex Browser
- Google Chrome
- Adobe Reader
- 7-zip
- FAR Manager
- Jitsi

#### Особенности:
1. Прокси
```ps
    - name: Set proxy environment variables
      win_shell: |
        $proxy = "http://10.136.2.7:3128/"
        [System.Environment]::SetEnvironmentVariable('http_proxy', $proxy, 'Machine')
        [System.Environment]::SetEnvironmentVariable('https_proxy', $proxy, 'Machine')
        setx http_proxy $proxy
        setx https_proxy $proxy
```
В начале плейбук задает системные настройки прокси. Это необходимо для chocolatey в случае работы на стандартном шлюзе.
Однако также в каждой задаче далее явно указывается прокси (требуется тестировать, чтобы понять, действительно ли есть в необходимость)

