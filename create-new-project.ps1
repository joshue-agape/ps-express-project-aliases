$express_project_main_content = @'
    require("dotenv").config();
    const http = require("http");
    const path = require("path");
    const glob = require("glob");
    const YAML = require("yamljs");
    const merge = require("lodash.merge");
    const swaggerUi = require("swagger-ui-express");
    const app = require("./app/middlewares/bodyParse.middleware");
    const { socket } = require("./app/web-socket/websocket.config");

    // ENV VARIABLES
    const PORT = process.env.PORT || 3000;
    const HOST = process.env.HOST || "localhost";
    const PROTOCOL = process.env.PROTOCOL || "http";

    // SWAGGER CONFIG
    const options = {
        definition: {
            openapi: "3.0.3",
            info: {
                title: "ExpressJs API",
                version: "1.0.0",
                description: "API documentation for ExpressJs",
            },
            servers: [
                {
                    url: `${PROTOCOL}://${HOST}:${PORT}/api/v1`,
                    description: "Dynamic environment",
                },
            ],
        },
        apis: path.join(__dirname, "app/docs/**/*.yml"),
    };

    // LOAD & MERGE ALL YAML FILES
    const loadSwaggerFiles = () => {
        const files = glob.sync(options.apis);
        let swaggerDocument = { ...options.definition };

        files.forEach((file) => {
            const fileContent = YAML.load(file);
            swaggerDocument = merge(swaggerDocument, fileContent);
        });

        return swaggerDocument;
    };

    const swaggerSpec = loadSwaggerFiles();

    // SWAGGER UI
    app.use("/docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));

    // BASE ROUTE
    app.get("/", (_, res) => {
        res.json({
            message: "Hello! Your API is up and running.",
            baseUrl: `${PROTOCOL}://${HOST}:${PORT}`,
        });
    });

    // HTTP SERVER + SOCKET.IO
    const server = http.createServer(app);
    const io = socket(server);

    // API ROUTES
    const apiRoutes = require("./app/routes")(io);
    app.use("/api/v1", apiRoutes);

    // START SERVER
    server.listen(PORT, () => {
        console.log(`Server running on ${PROTOCOL}://${HOST}:${PORT}`);
        console.log(`Swagger Docs → ${PROTOCOL}://${HOST}:${PORT}/docs`);
        console.log(`WebSocket → ${PROTOCOL}://${HOST}:${PORT}/api/v1/socket.io`);
    });
'@


$express_project_body_parse_content = @'
    const express = require("express");
    const cors = require("cors");
    const session = require("express-session");
    const cookieParser = require("cookie-parser");

    const app = express();

    app.use(
        cors({
            origin: '*',
            allowedHeaders: ['Content-Type', 'Authorization'],
            methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
            preflightContinue: false,
            optionsSuccessStatus: 200,
            credentials: true,
        }),
    );
    app.use(express.json());
    app.use(express.urlencoded({ extended: true }));
    app.use(cookieParser());

    app.use(
        session({
            secret: process.env.SESSION_SECRET || "default_secret",
            resave: false,
            saveUninitialized: true,
        })
    );

    module.exports = app;
'@


$express_project_socket_config_content = @'
    const { Server } = require("socket.io");
    const events = require("./websocket.events");

    const socket = (server) => {
        const io = new Server(server, {
            path: "/api/v1/socket.io",
            cors: { origin: "*" },
        });

        events(io);
        return io;
    };

    module.exports = { socket };
'@


$express_project_socket_event_content = @'
    module.exports = (io) => {
        io.on("connection", (socket) => {
            socket.on("event", (data) => {
                io.emit("callback", data);
            });
        });
    };
'@


$express_project_response_service_content = @'
    /**
     *
     * @param { * } data
     * @param { string } message
     * @param { int } status_code
     */
    exports.success = (status_code = 200, message, data) => ({
        success: true,
        message,
        status_code,
        data,
    });

    /**
     *
     * @param { string } message
     * @param { int } status_code
     * @param { * } details
     */
    exports.error = (status_code = 500, message, details) => ({
        success: false,
        message,
        status_code,
        data: details,
    });
'@


$express_project_controller_content = @'
    const { success, error } = require('../services/response.service');

    exports.index = (req, res) => {
        const data = {
            author: "Joshué Agapé",
            email: "agapedev.dark@gmail.com",
        }
        return res.send(success(200, 'Your data example', data))
    };
'@


$express_project_doc_content = @'
    paths:
        /api/v1/health:
            get:
                tags:
                    - Example
                summary: Get example data
                description: >
                    Returns a static example object containing author information.
                    This endpoint is mainly used to validate the API structure.
                operationId: getExample
                responses:
                    "200":
                        description: Successful response
                        content:
                            application/json:
                            schema:
                                $ref: "#/components/schemas/ExampleResponse"
                            example:
                                author: "Joshué Agapé"
                                email: "agapedev.dark@gmail.com"
                    "500":
                        description: Internal server error
                        content:
                            application/json:
                            schema:
                                type: object
                                properties:
                                message:
                                    type: string
                                    example: "Internal server error"

    components:
        schemas:
            ExampleResponse:
                type: object
                properties:
                    author:
                        type: string
                        example: "Joshué Agapé"
                    email:
                        type: string
                        format: email
                        example: "agapedev.dark@gmail.com"
'@


$express_project_index_route_content = @'
    const express = require("express");
    const fs = require("fs");
    const path = require("path");

    module.exports = (io) => {
        const router = express.Router();
        const groupsPath = path.join(__dirname, "groups");

        if (!fs.existsSync(groupsPath)) {
            console.warn("routes/groups folder not found");
            return router;
        }

        fs.readdirSync(groupsPath)
            .filter(file => file.endsWith(".js") && !file.startsWith("_") && !file.includes(".test."))
            .forEach(file => {
                const fullPath = path.join(groupsPath, file);
                const routeName = file.replace(/\.route\.js$/, "").replace(/\.js$/, "");
                const routeModule = require(fullPath);
                const mountedRoute = typeof routeModule === "function" ? routeModule(io) : routeModule;
                router.use(`/${routeName}`, mountedRoute);
                console.log(`Route loaded: /${routeName}`);
            });

        return router;
    };
'@


$express_project_health_route_content = @'
    const express = require("express");
    const controller = require("../../controllers/controller");

    module.exports = () => {
        const router = express.Router();

        router.get("/", controller.index);

        return router;
    };
'@


$express_project_env_content = @'
NODE_ENV=development

PORT=3000
HOST=localhost
PROTOCOL=http

SESSION_SECRET=your-super-secret

'@


$express_project_git_ignore_ontent = @'
node_modules
.env
'@


$express_project_prettier_content = @'
    module.exports = {
        printWidth: 150,
        tabWidth: 4,
        useTabs: false,
        semi: true,
        singleQuote: true,
        trailingComma: "all",
        bracketSpacing: true,
        arrowParens: "always",
        bracketSameLine: false,
        proseWrap: "preserve",
        endOfLine: "lf",
        jsxSingleQuote: false,
        embeddedLanguageFormatting: "auto",
    };
'@


$express_project_prettier_ignore_content = @'
node_modules/
dist/
build/
.vite/
app/docs/*
'@


$express_project_readme_content = @"
# Run
\`\`\`
npm install
npm run dev
\`\`\`
"@

function New-Express {
    param(
        [string]$PROJECT_NAME
    )

    if (-not $PROJECT_NAME) {
        $PROJECT_NAME = Read-Host "Project name :"
    }

    New-Item -ItemType Directory -Path $PROJECT_NAME -Force | Out-Null
    Set-Location $PROJECT_NAME

    Write-Host "Initializing Node.js project"
    npm init

    Write-Host "Installing dependencies"
    npm install express dotenv fs path cors body-parser express-session socket.io swagger-ui-express yamljs glob lodash.merge cookie-parser

    Write-Host "Installing nodemon"
    npm install --save-dev nodemon eslint

    Write-Host "Installing Prettier..."
    npm install --save-dev prettier
    npm pkg set scripts.format="prettier --write ." | Out-Null

    Set-Content "prettier.config.js" -Value $express_project_prettier_content -Encoding UTF8
    Set-Content ".prettierignore" -Value $express_project_prettier_ignore_content -Encoding UTF8

    Write-Host "- Prettier has been successfully installed and configured!"
    Write-Host "- Run `npm run format` to format your project."

    $dirs = @(
        "app/docs",
        "app/controllers",
        "app/routes/groups",
        "app/middlewares",
        "app/web-socket",
        "app/services"
    )
    foreach ($d in $dirs) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

    Set-Content "main.js" -Value $express_project_main_content -Encoding UTF8
    Set-Content "app/middlewares/bodyParse.middleware.js" -Value $express_project_body_parse_content -Encoding UTF8
    Set-Content "app/web-socket/websocket.config.js" -Value $express_project_socket_config_content -Encoding UTF8
    Set-Content "app/web-socket/websocket.events.js" -Value $express_project_socket_event_content -Encoding UTF8
    Set-Content "app/services/response.service.js" -Value $express_project_response_service_content -Encoding UTF8
    Set-Content "app/controllers/controller.js" -Value $express_project_controller_content -Encoding UTF8
    Set-Content "app/docs/doc.yml" -Value $express_project_doc_content -Encoding UTF8
    Set-Content "app/routes/index.js" -Value $express_project_index_route_content -Encoding UTF8
    Set-Content "app/routes/groups/health.js" -Value $express_project_health_route_content -Encoding UTF8
    Set-Content ".env" -Value $express_project_env_content -Encoding UTF8
    Set-Content ".env.example" -Value $express_project_env_content -Encoding UTF8
    Set-Content ".gitignore" -Value $express_project_git_ignore_ontent -Encoding UTF8
    Set-Content "README.md" -Value $express_project_readme_content -Encoding UTF8

    npm pkg set main="main.js"
    npm pkg set type="commonjs"
    npm pkg set scripts.dev="nodemon main.js"
    npm pkg set scripts.start="nodemon main.js"
    npm pkg set scripts.build="node main.js"

    Write-Host "Formatting project code..."
    npm run format

    $GIT = Read-Host "Would you like to initialize Git? (Y/N)"
    if ($GIT.Trim() -match '^[Yy]') {
        git init
        git add -A
        git commit -m "Initial commit"
    }

    # Clear-Host
    npm run start
}

function New-Express-Project {
    param(
        [string]$PROJECT_NAME
    )

    New-Express $PROJECT_NAME
}

function Create-Express {
    param(
        [string]$PROJECT_NAME
    )

    New-Express $PROJECT_NAME
}

function Create-Express-Project {
    param(
        [string]$PROJECT_NAME
    )

    New-Express $PROJECT_NAME
}