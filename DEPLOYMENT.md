# Production Deployment Guide

## Требования на сервере

### 1. Установленное ПО
```bash
# Docker
sudo apt-get update
sudo apt-get install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker

# Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Git (для pull обновлений)
sudo apt-get install git -y

# Проверка установки
docker --version
docker-compose --version
```

### 2. Подготовка директорий

```bash
# Создаем структуру на сервере
sudo mkdir -p /opt/ksaers
sudo mkdir -p /opt/ksaers/app
sudo mkdir -p /opt/ksaers/certs
sudo mkdir -p /opt/ksaers/npm-cache

# Выдаем права
sudo chown -R $USER:$USER /opt/ksaers
sudo chmod -R 755 /opt/ksaers
```

## Первичная установка

### Способ 1: Клонирование из Git (рекомендуется)

```bash
# 1. Переходим в директорию
cd /opt/ksaers/app

# 2. Клонируем репозиторий
git clone https://github.com/ksaers/KsaersWebsite.git .

# 3. Переходим в папку проекта
cd v4

# 4. Создаем файл с переменными окружения
cp .env.example .env

# 5. Редактируем .env при необходимости
nano .env

# 6. Копируем production compose файл
cp docker-compose.prod.yml docker-compose.yml

# 7. Собираем и запускаем контейнер
docker-compose up -d

# 8. Проверяем статус
docker-compose ps
docker-compose logs web
```

### Способ 2: Прямое копирование файлов

```bash
# На локальной машине:
scp -r v4/* user@server:/opt/ksaers/app/

# На сервере:
cd /opt/ksaers/app
cp docker-compose.prod.yml docker-compose.yml
docker-compose up -d
```

## Обновление проекта на сервере

```bash
# 1. Переходим в директорию
cd /opt/ksaers/app/v4

# 2. Скачиваем последние изменения
git pull origin main

# 3. Пересобираем контейнер
docker-compose up -d --build

# 4. Проверяем логи
docker-compose logs -f web
```

### Автоматическое обновление через cron

```bash
# Открываем crontab
crontab -e

# Добавляем строку (обновление каждый час)
0 * * * * cd /opt/ksaers/app/v4 && git pull origin main && docker-compose up -d --build

# Или каждый день в 02:00
0 2 * * * cd /opt/ksaers/app/v4 && git pull origin main && docker-compose up -d --build
```

## HTTPS (SSL/TLS) конфигурация

### С Let's Encrypt 

```bash
# 1. Устанавливаем certbot
sudo apt-get install certbot -y

# 2. Генерируем сертификат
sudo certbot certonly --standalone -d ksaers.com -d www.ksaers.com

# 3. Копируем сертификаты в нашу папку
sudo cp /etc/letsencrypt/live/ksaers.com/fullchain.pem /opt/ksaers/certs/
sudo cp /etc/letsencrypt/live/ksaers.com/privkey.pem /opt/ksaers/certs/
sudo chown $USER:$USER /opt/ksaers/certs/*

# 4. Обновляем nginx.conf для HTTPS (смотри ниже)

# 5. Пересобираем контейнер
docker-compose up -d --build
```

### Обновление Nginx config для HTTPS

```bash
# Отредактируйте nginx.conf:
nano /opt/ksaers/app/v4/nginx.conf
```

Добавьте блок для HTTPS:

```nginx
server {
    listen 80;
    server_name ksaers.com www.ksaers.com;
    
    # Редирект с HTTP на HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ksaers.com www.ksaers.com;
    root /usr/share/nginx/html;
    index index.html;

    # SSL сертификаты
    ssl_certificate /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;

    # SSL параметры
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Остальная конфигурация nginx из исходного файла...
    gzip on;
    gzip_types text/plain text/css text/javascript application/javascript application/json;
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location ~* \.html?$ {
        expires 24h;
        add_header Cache-Control "public";
    }

    location / {
        try_files $uri $uri/ /index.html;
    }

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
}
```

### Автоматическое обновление сертификатов

```bash
# Добавляем в crontab (каждый месяц)
0 0 1 * * sudo certbot renew --quiet && sudo cp /etc/letsencrypt/live/ksaers.com/* /opt/ksaers/certs/ && cd /opt/ksaers/app/v4 && docker-compose up -d --build
```

## Мониторинг

### Просмотр логов

```bash
# Логи контейнера
docker-compose logs web

# Логи в реальном времени
docker-compose logs -f web --tail 100

# Логи Nginx внутри контейнера
docker exec ksaers-website tail -f /var/log/nginx/access.log
```

### Проверка здоровья

```bash
# Статус контейнера
docker-compose ps

# Подробная информация
docker inspect ksaers-website | grep -A 10 "Health"

# Ручная проверка доступности
curl http://localhost/
```

### Использование ресурсов

```bash
# Реальное время
docker stats

# Или конкретного контейнера
docker stats ksaers-website
```

## Резервное копирование

```bash
# Резервная копия всех файлов
sudo tar -czf /backup/ksaers-backup-$(date +%Y%m%d).tar.gz /opt/ksaers/

# Или просто исходного кода
sudo tar -czf /backup/ksaers-code-backup-$(date +%Y%m%d).tar.gz /opt/ksaers/app/

# Автоматическое резервное копирование (ежедневно в 03:00)
0 3 * * * sudo tar -czf /backup/ksaers-backup-$(date +\%Y\%m\%d).tar.gz /opt/ksaers/ && find /backup -name "ksaers-backup-*.tar.gz" -mtime +7 -delete
```

## Очистка и переустановка

```bash
# Остановить и удалить контейнер
docker-compose down

# Удалить образ
docker rmi ksaers-website

# Очистить npm кэш
rm -rf /opt/ksaers/npm-cache/*

# Пересобрать с нуля
docker-compose up -d --build
```

## Структура на сервере

```
/opt/ksaers/
├── app/                          # Исходный код проекта
│   ├── v4/
│   │   ├── Dockerfile
│   │   ├── Dockerfile.nginx
│   │   ├── docker-compose.yml
│   │   ├── nginx.conf
│   │   ├── package.json
│   │   ├── src/
│   │   ├── content/
│   │   └── ...
│   └── ...
├── certs/                        # SSL сертификаты
│   ├── fullchain.pem
│   └── privkey.pem
├── npm-cache/                    # Кэш npm (ускоряет пересборки)
└── backups/                      # Резервные копии (опционально)
```

## Troubleshooting

### Контейнер не стартует

```bash
# Проверить логи
docker-compose logs web

# Проверить, не занят ли порт 80
sudo lsof -i :80

# Убить процесс на порте
sudo kill -9 <PID>
```

### Permission denied

```bash
# Если ошибки доступа к файлам
sudo chown -R $USER:$USER /opt/ksaers
sudo chmod -R 755 /opt/ksaers
```

### Контейнер постоянно перезагружается

```bash
# Проверить health checks
docker inspect --format='{{json .State.Health}}' ksaers-website | jq

# Отключить health check временно в docker-compose.yml
```

### Port 80 занят другим приложением

```bash
# Используйте другой порт
ports:
  - "8080:80"

# Или используйте reverse proxy (nginx, apache)
```

## Reverse Proxy за Nginx (если нужно несколько приложений)

```nginx
# /etc/nginx/sites-available/ksaers
upstream ksaers_backend {
    server 127.0.0.1:8080;
}

server {
    listen 80;
    server_name ksaers.com www.ksaers.com;
    
    location / {
        proxy_pass http://ksaers_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Активируем:
```bash
sudo ln -s /etc/nginx/sites-available/ksaers /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

В docker-compose.yml используйте:
```yaml
ports:
  - "8080:80"
```
