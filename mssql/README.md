# MSSQL Server

A Docker Compose configuration for running Microsoft SQL Server locally.

This setup provides a containerized SQL Server instance for development and testing purposes.

## Usage

Start the SQL Server:

```bash
docker-compose up -d
```

Stop the SQL Server:

```bash
docker-compose down
```

## Connection Details

Connect to the SQL Server using:

- **Server**: localhost
- **Port**: 1433 (default)
- **Username**: sa (system administrator)
- **Password**: Check your docker-compose.yml file for the SA_PASSWORD

You can connect using tools like:
- SQL Server Management Studio (SSMS)
- Azure Data Studio
- sqlcmd CLI tool
- Any SQL client application

## Notes

- The default SQL Server edition is Express (if not specified otherwise in docker-compose.yml)
- Data is typically stored in a Docker volume for persistence across container restarts
