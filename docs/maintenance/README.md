# TalkDeskly Maintenance, Backups & Troubleshooting

This guide covers operational tasks such as using the built-in database management CLI, performing back-up operations, checking health statuses, and troubleshooting common issues.

---

## 🗄️ Database CLI Tools

The TalkDeskly backend executable has built-in database maintenance utilities. Run these commands directly on the server to manage the database:

### Migration Commands
* **Run migrations**: Updates schemas to the latest versions.
  ```bash
  ./talkdeskly migrate run
  ```
* **Migration status**: Lists table schemas and checks migration status.
  ```bash
  ./talkdeskly migrate status
  ```
* **Reset migrations**: Drops all tables and re-runs migrations.
  ```bash
  ./talkdeskly migrate reset
  ```
  *WARNING: This drops all data!*

### Database Information Commands
* **Connection check**: Verifies connection pool statuses.
  ```bash
  ./talkdeskly db status
  ```
* **Database overview**: Outputs table information and row counts.
  ```bash
  ./talkdeskly db info
  ```
* **Seed database**: Populates the database with default admin accounts, channels, and simulated customer conversations.
  ```bash
  ./talkdeskly seed run
  ```

---

## 💾 Backups & Disaster Recovery

### PostgreSQL database backups
Set up a daily cron job to dump database contents using `pg_dump`:
```bash
#!/bin/bash
BACKUP_DIR="/var/backups/talkdeskly"
DATE=$(date +%Y-%m-%d)
pg_dump -U postgres -d talkdeskly | gzip > "$BACKUP_DIR/db_backup_$DATE.sql.gz"
# Keep backups for 30 days
find "$BACKUP_DIR" -type f -mtime +30 -name "*.sql.gz" -delete
```

### Redis cache backups
To prevent WebSocket message drops during restart, enable standard append-only persistence in `redis.conf`:
```ini
appendonly yes
appendfsync everysec
```
Backup the generated `appendonly.aof` or `dump.rdb` file regularly.

---

## 🔍 System Monitoring & Health Checks

TalkDeskly exposes a health endpoint to verify the API, DB, and Redis instances:
* **HTTP Ping Check**: Query `GET https://chat.yourdomain.com/health`
  - Returns HTTP `200 OK` (with JSON `{"status":"healthy"}`) if both SQL and Redis connections are responding.
  - Returns HTTP `503 Service Unavailable` if one of the connections is down.
* **SuperAdmin Dashboard**: Detailed system statistics and health metrics are visible inside the SuperAdmin panel under `System Health`.

---

## ❓ Troubleshooting Common Issues

### Issue 1: WebSocket Disconnection (HTTP Status 1006)
* **Symptoms**: The widget disconnects from the chat room every 60 seconds.
* **Reason**: Reverse proxies (like Nginx, Cloudflare, AWS ALB) close TCP connections if they are idle for too long.
* **Fix**: Ensure `proxy_read_timeout` and `proxy_send_timeout` are configured to `86400s` (24 hours) in your Nginx config. Also, verify WebSocket ping/pong intervals are enabled in the backend settings.

### Issue 2: Cross-Origin Resource Sharing (CORS) Violations
* **Symptoms**: Browser console reports blocked API queries when the chat widget loads on custom websites.
* **Reason**: The API server rejected calls originating from outside the admin URL.
* **Fix**: Open the backend configuration file or environment config and adjust CORS headers. Ensure the origin domain is whitelisted or set `AllowOrigins` to `*` in the backend service router configuration if the widget is designed for public embedding.

### Issue 3: E-mail Sending Failures
* **Symptoms**: welcome emails, invitations, and password reset codes are not sent.
* **Reason**: Cloud environments (like AWS EC2, DigitalOcean) block SMTP outgoing port `25` by default to prevent spam.
* **Fix**: Update SMTP configurations to secure ports (`587` for TLS or `465` for SSL) and supply valid login credentials.
