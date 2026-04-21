$express_project_sequelizerc = @"
    const path = require('path');

    module.exports = {
        'config': path.resolve('config', 'sequelize-cli.js'),
        'models-path': path.resolve('database', 'models'),
        'seeders-path': path.resolve('database', 'seeder'),
        'migrations-path': path.resolve('database', 'migrations')
    };
"@

function express_project_config_database_content {
    param([Parameter(Mandatory = $true)][string]$DB_DIALECT)
    return @"
        const { Sequelize } = require('sequelize');
        const path = require('path');

        const sequelize = new Sequelize({
            dialect: '$DB_DIALECT',
            host: process.env.DB_HOST,
            port: Number(process.env.DB_PORT),
            username: process.env.DB_USERNAME,
            password: process.env.DB_PASSWORD ?? '',
            database: process.env.DB_DATABASE,
            models: [path.join(__dirname, '../models')],
            logging: false,
            pool: {
                max: 10,
                min: 0,
                acquire: 20000,
                idle: 5000,
            },
        });

        module.exports = sequelize;
"@
}

function express_project_sequelize_cli_content {
    param([Parameter(Mandatory = $true)][string]$DB_DIALECT)

    if ($DB_DIALECT -eq 'postgres') {
        $PORT = 5432
    } else {
        $PORT = 3306
    }

    return @"
        require('dotenv').config();

        module.exports = {
            development: {
                username: process.env.DB_USERNAME,
                password: process.env.DB_PASSWORD,
                database: process.env.DB_DATABASE,
                host: process.env.DB_HOST,
                port: process.env.DB_PORT || $PORT,
                dialect: '$DB_DIALECT',
            },
            test: {
                username: process.env.DB_USERNAME,
                password: process.env.DB_PASSWORD,
                database: process.env.DB_DATABASE,
                host: process.env.DB_HOST,
                port: process.env.DB_PORT || $PORT,
                dialect: '$DB_DIALECT',
            },
            production: {
                username: process.env.DB_USERNAME,
                password: process.env.DB_PASSWORD,
                database: process.env.DB_DATABASE,
                host: process.env.DB_HOST,
                port: process.env.DB_PORT || $PORT,
                dialect: '$DB_DIALECT',
            },
        };
"@
}


$express_project_readme_sequelize_content = @'
# Sequelize CLI Commands

This project uses Sequelize ORM. Here is a complete list of all useful commands for database management, migrations, seeds, and models.

---

## Database Management

### Create database:

```bach
npm run db:create
```

### Drop database:

```bach
npm run db:drop
```

---


## Migrations

### Run all pending migrations:

```bach
npm run db:migrate
```

### Undo last migration:

```bach
npm run db:migrate:fresh
```

### Undo all migrations (reset database):

```bach
npm run db:migrate:fresh:all
```

---

## Models

### Generate a new model with migration:

```bach
npx sequelize-cli model:generate --name User --attributes name:string,email:string
```

---

## Seeds

### Run all seed files:

```bach
npm run db:seed
```

### Undo last seed:

```bach
npm run db:seed:fresh
```

### Undo all seeds:

```bach
npm run db:seed:fresh:all
```

### Generate a new seed file:

```bach
npx sequelize-cli seed:generate --name user_seeder
```
'@

function Express-Database {
    if (-Not (Test-Path "package.json")) {
        Write-Host "package.json not found. Please run this command inside a Node.js project."
        exit 1
    }

    Write-Host "Installing Sequelize dependencies..."
    npm install sequelize uuid

    Write-Host "Installing Sequelize development dependencies..."
    npm install --save-dev sequelize-cli

    Write-Host "Select the database you want to use:"
    Write-Host "1) MySQL"
    Write-Host "2) MariaDB"
    Write-Host "3) PostgreSQL"

    $DB_CHOICE = Read-Host "Enter your choice (1-3)"

    switch ($DB_CHOICE) {
        "1" {
            $DB_DIALECT = "mysql"
            npm install mysql2
        }
        "2" {
            $DB_DIALECT = "mariadb"
            npm install mariadb
        }
        "3" {
            $DB_DIALECT = "postgres"
            npm install pg pg-hstore
        }
        default {
            Write-Host "Invalid choice. Using PostgreSQL by default."
            $DB_DIALECT = "postgres"
            npm install pg pg-hstore
        }
    }

    Write-Host "Database driver successfully installed for $DB_DIALECT"

    Set-Content ".sequelizerc" -Value $express_project_sequelizerc -Encoding UTF8
    npx sequelize-cli init

    $config_database_content = express_project_config_database_content $DB_DIALECT
    if (-Not (Test-Path "config")) { New-Item -ItemType Directory -Path "config" | Out-Null }
    Set-Content "config/database.js" -Value $config_database_content -Encoding UTF8

    $sequelize_cli_content = express_project_sequelize_cli_content $DB_DIALECT
    Set-Content "config/sequelize-cli.js" -Value $sequelize_cli_content -Encoding UTF8

    npm pkg set scripts.db:create="npx sequelize-cli db:create"
    npm pkg set scripts.db:drop="npx sequelize-cli db:drop"
    npm pkg set scripts.db:migrate="npx sequelize-cli db:migrate"
    npm pkg set scripts.db:migrate:fresh="npx sequelize-cli db:migrate:undo"
    npm pkg set scripts.db:migrate:fresh:all="npx sequelize-cli db:migrate:undo:all"
    npm pkg set scripts.db:seed="npx sequelize-cli db:seed:all"
    npm pkg set scripts.db:seed:fresh="npx sequelize-cli db:seed:undo"
    npm pkg set scripts.db:seed:fresh:all="npx sequelize-cli db:seed:undo:all"

    if ($DB_DIALECT -eq 'postgres') {
        $PORT = 5432
        $USER = 'postgres'
    } else {
        $PORT = 3306
        $USER = 'root'
    }

    $files = @(".env", ".env.example")
    $db_vars = @{
        "DB_HOST" = "localhost"
        "DB_PORT" = "$PORT"
        "DB_USERNAME" = $USER
        "DB_PASSWORD" = "db_password"
        "DB_DATABASE" = "db_name"
    }

    foreach ($file in $files) {
        if (-Not (Test-Path $file)) {
            New-Item -ItemType File -Path $file | Out-Null
        }

        $content = Get-Content $file -Raw

        foreach ($key in $db_vars.Keys) {
            # Use multiline regex to check if the key already exists in the file
            if ($content -notmatch "(?m)^$key=") {
                Add-Content -Path $file -Value "$key=$($db_vars[$key])"
            }
        }
    }

    Write-Host "Formatting project code..."
    npm run format

    Set-Content "README_SEQUELIZE.md" -Value $express_project_readme_sequelize_content -Encoding UTF8

    Write-Host "Sequelize setup completed successfully!"
    Write-Host "Configuration files generated and environment variables initialized."
    Write-Host "You can now run: npm run db:migrate"
}
