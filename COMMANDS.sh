#!/bin/bash

# Шпаргалка по командам для деплоя проекта
# Копируйте и вставляйте команды по необходимости

# ============================================
# ЛОКАЛЬНО - Подготовка перед деплоем
# ============================================

# Проверить, что всё работает локально
npm start

# Собрать production версию
npm run build

# Протестировать локально в Docker
docker-compose up -d
docker-compose ps
docker-compose logs -f web

# Остановить локальный контейнер
docker-compose down

# ============================================
# НА СЕРВЕРЕ - Первичная установка
# ============================================

# Способ 1: Автоматический скрипт (РЕКОМЕНДУЕТСЯ)
ssh user@your-server.com
curl -O https://raw.githubusercontent.com/ksaers/KsaersWebsite/main/v4/deploy.sh
chmod +x deploy.sh
./deploy.sh

# Способ 2: Ручная установка
ssh user@your-server.com

# Установить Docker
sudo apt-get update
sudo apt-get install docker.io -y
sudo systemctl start docker

# Установить Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Создать папки
sudo mkdir -p /opt/ksaers/{app,certs,npm-cache}
sudo chown $USER:$USER /opt/ksaers -R

# Клонировать проект
git clone https://github.com/ksaers/KsaersWebsite.git /opt/ksaers/app
cd /opt/ksaers/app/v4

# Скопировать production конфиг
cp docker-compose.prod.yml docker-compose.yml

# Запустить
docker-compose up -d --build

# ============================================
# НА СЕРВЕРЕ - Проверка статуса
# ============================================

# Проверить, что контейнер работает
docker-compose ps

# Посмотреть логи
docker-compose logs web

# Логи в реальном времени
docker-compose logs -f web

# Логи последние 50 строк
docker-compose logs -f --tail 50 web

# Проверить доступность сайта
curl http://localhost/

# Статистика ресурсов
docker stats ksaers-website

# ============================================
# НА СЕРВЕРЕ - Обновления
# ============================================

# Обновить код с GitHub
cd /opt/ksaers/app/v4
git pull origin main

# Пересобрать контейнер после обновления
docker-compose up -d --build

# Перезапустить контейнер (без пересборки)
docker-compose restart web

# Остановить контейнер
docker-compose down

# Запустить контейнер
docker-compose up -d

# ============================================
# НА СЕРВЕРЕ - HTTPS (Let's Encrypt)
# ============================================

# Установить Certbot
sudo apt-get install certbot -y

# Остановить контейнер
docker-compose down

# Сгенерировать сертификат
sudo certbot certonly --standalone -d ksaers.com -d www.ksaers.com

# Скопировать сертификаты
sudo cp /etc/letsencrypt/live/ksaers.com/fullchain.pem /opt/ksaers/certs/
sudo cp /etc/letsencrypt/live/ksaers.com/privkey.pem /opt/ksaers/certs/
sudo chown $USER:$USER /opt/ksaers/certs/*

# Отредактировать nginx.conf (добавить HTTPS блок)
nano nginx.conf

# Запустить контейнер с HTTPS
docker-compose up -d --build

# Проверить HTTPS
curl https://ksaers.com/

# Настроить автоматическое обновление сертификатов (ежемесячно)
crontab -e
# Добавить строку:
# 0 0 1 * * sudo certbot renew --quiet && sudo cp /etc/letsencrypt/live/ksaers.com/* /opt/ksaers/certs/ && cd /opt/ksaers/app/v4 && docker-compose up -d --build

# ============================================
# НА СЕРВЕРЕ - Автоматические обновления
# ============================================

# Открыть crontab
crontab -e

# Добавить для ежедневного обновления в 02:00
0 2 * * * cd /opt/ksaers/app/v4 && git pull origin main && docker-compose up -d --build >> /tmp/ksaers-update.log 2>&1

# Или каждые 6 часов
0 */6 * * * cd /opt/ksaers/app/v4 && git pull origin main && docker-compose up -d --build >> /tmp/ksaers-update.log 2>&1

# Просмотреть логи обновлений
tail -f /tmp/ksaers-update.log

# ============================================
# НА СЕРВЕРЕ - Работа с контейнером
# ============================================

# Войти в контейнер (shell)
docker-compose exec web /bin/sh

# Просмотр логов Nginx
docker exec ksaers-website tail -f /var/log/nginx/access.log

# Проверить конфиг Nginx
docker exec ksaers-website nginx -t

# Перезагрузить Nginx (внутри контейнера)
docker exec ksaers-website nginx -s reload

# ============================================
# НА СЕРВЕРЕ - Резервное копирование
# ============================================

# Резервная копия всего проекта
tar -czf /backup/ksaers-backup-$(date +%Y%m%d).tar.gz /opt/ksaers/

# Резервная копия только исходного кода
tar -czf /backup/ksaers-code-$(date +%Y%m%d).tar.gz /opt/ksaers/app/

# Автоматическое резервное копирование (ежедневно в 03:00)
crontab -e
# Добавить:
# 0 3 * * * tar -czf /backup/ksaers-backup-$(date +\%Y\%m\%d).tar.gz /opt/ksaers/ && find /backup -name "ksaers-backup-*.tar.gz" -mtime +7 -delete

# ============================================
# НА СЕРВЕРЕ - Очистка и переустановка
# ============================================

# Остановить контейнер
docker-compose down

# Удалить образ
docker rmi ksaers-website

# Удалить все неиспользуемые Docker объекты
docker system prune -a

# Очистить npm кэш
rm -rf /opt/ksaers/npm-cache/*

# Пересоберить с нуля
docker-compose up -d --build

# ============================================
# НА СЕРВЕРЕ - Troubleshooting
# ============================================

# Проверить конфиг docker-compose
docker-compose config

# Проверить, какой процесс занимает порт 80
sudo lsof -i :80

# Убить процесс на порте 80
sudo kill -9 <PID>

# Проверить системные логи Docker
journalctl -u docker -n 50

# Проверить ошибки при build
docker-compose build --no-cache

# Проверить занятое место на диске
df -h

# Проверить размер контейнера
docker ps -s

# ============================================
# НА СЕРВЕРЕ - Автозапуск при перезагрузке
# ============================================

# Создать systemd сервис
sudo bash -c 'cat > /etc/systemd/system/ksaers-website.service << EOF
[Unit]
Description=Ksaers Website Docker Container
After=docker.service
Requires=docker.service

[Service]
Type=forking
User=$USER
WorkingDirectory=/opt/ksaers/app/v4
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF'

# Активировать сервис
sudo systemctl daemon-reload
sudo systemctl enable ksaers-website.service
sudo systemctl start ksaers-website.service

# Проверить статус сервиса
sudo systemctl status ksaers-website.service

# Просмотреть логи сервиса
sudo journalctl -u ksaers-website.service -n 50 -f

# ============================================
# ПОЛЕЗНЫЕ ПЕРЕМЕННЫЕ
# ============================================

# Переменные окружения из .env.example
export NODE_ENV=production
export GATSBY_SITE_URL=https://ksaers.com

# ============================================
# ССЫЛКИ И СПРАВКА
# ============================================

# Документация:
# - SERVER_SETUP.md       → Пошаговое руководство
# - DEPLOYMENT.md         → Расширенные инструкции
# - QUICK_START.md        → Быстрый старт
# - SERVER_REQUIREMENTS.md → Требования к серверу
# - DOCKER.md             → Информация о Docker

# Посмотреть полную документацию
cat SERVER_SETUP.md
cat DEPLOYMENT.md
cat QUICK_START.md
