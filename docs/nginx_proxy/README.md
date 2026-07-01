# Nginx Reverse Proxy & WebSocket Configuration

Putting TalkDeskly behind a reverse proxy like Nginx is highly recommended for production setups. Nginx handles SSL/TLS certificates (e.g. Let's Encrypt), WebSocket upgrade headers, caching, gzip compression, and basic rate limiting.

---

## 🔒 Production Nginx Server Block

Add the following file to `/etc/nginx/sites-available/talkdeskly` and symlink it to `/etc/nginx/sites-enabled/`:

```nginx
# Define rate limiting parameters to guard against socket flood
limit_req_zone $binary_remote_addr zone=chat_limit:10m rate=15r/s;

server {
    listen 80;
    server_name chat.yourdomain.com;
    
    # Force HTTP to HTTPS redirection
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name chat.yourdomain.com;

    # SSL / TLS Certificate paths (Managed by Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/chat.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/chat.yourdomain.com/privkey.pem;

    # Recommended Secure SSL Protocols and Ciphers
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384";
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    # Hardened Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: ws: wss: data: blob: 'unsafe-inline'" always;

    # 1. API and Frontend Asset Routing
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Static file compression
        gzip on;
        gzip_min_length 1000;
        gzip_types text/plain text/css application/json application/javascript text/xml;
    }

    # 2. WebSocket Real-Time Channel Routing
    location /ws {
        # Apply strict rate limits on websocket upgrade attempts
        limit_req zone=chat_limit burst=30 nodelay;

        proxy_pass http://localhost:8080/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket active timeout config (prevents Nginx closing idle sockets)
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
```

---

## 🛠️ Testing and Reloading

1. Check configuration syntax for errors:
   ```bash
   nginx -t
   ```
2. Reload Nginx to apply changes without dropping active client connections:
   ```bash
   systemctl reload nginx
   ```
