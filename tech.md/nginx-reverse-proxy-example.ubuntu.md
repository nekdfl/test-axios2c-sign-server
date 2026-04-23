# Пример reverse-proxy Nginx к demo-sign-server (Axis2/C)

Ниже — **пример** конфигурации: Nginx на порту **8081** проксирует на встроенный HTTP-сервер Axis2 на **127.0.0.1:8080** (тот, что поднимает `demo-sign-server` через **`./scripts/run.sh`**).

Сохраните фрагмент, например, в `/etc/nginx/sites-available/demo-sign` (или в `conf.d/`), приведите пути к политике вашей ОС, проверьте и перезагрузите Nginx:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

## Фрагмент `nginx.conf` / `sites-enabled`

```nginx
upstream demo_sign_backend {
    server 127.0.0.1:8080;
    keepalive 32;
}

server {
    listen 8081;
    server_name _;

    # Прокси к Apache Axis2/C simple HTTP server
    location / {
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://demo_sign_backend;
    }
}
```

- **8080** — порт процесса `demo-sign-server` (см. опция `-p` / переменная `PORT` в `./scripts/run.sh`).
- **8081** — внешний порт Nginx; при необходимости смените `listen` и `server_name`.
- Сервисы Axis2 обычно доступны по путям вида `/services/...` — прокси на корень (`/`) передаёт тот же URL path бэкенду, что и у клиента.

См. также [`environment.ubuntu.md`](environment.ubuntu.md) (сборка и запуск на Linux) и корневой [`README.ubuntu.md`](../README.ubuntu.md).
