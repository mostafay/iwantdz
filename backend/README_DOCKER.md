# MySQL Setup with Docker for Codespaces

## Quick Start

1. Start MySQL container:
```bash
docker-compose up -d
```

2. Wait for MySQL to be ready (about 10-15 seconds)

3. Start the server:
```bash
cd backend
node server.js
```

## Stop MySQL
```bash
docker-compose down
```

## View MySQL logs
```bash
docker-compose logs mysql
```

## Connect to MySQL directly
```bash
docker exec -it iwantdz_mysql mysql -u root -p
# Password: rootpassword
```

## Database Credentials
- Host: localhost
- Port: 3306
- User: root
- Password: rootpassword
- Database: iwantdz_db
