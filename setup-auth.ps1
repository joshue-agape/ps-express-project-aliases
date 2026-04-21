$express_project_auth_service_content = @'
    "use strict";

    const jwt = require("jsonwebtoken");
    const bcrypt = require("bcrypt");

    class PasswordService {
        static SALT_ROUNDS = 10;

        static async hashPassword(password) {
            return bcrypt.hash(password, PasswordService.SALT_ROUNDS);
        }

        static async comparePassword(password, hash) {
            return bcrypt.compare(password, hash);
        }
    }

    class JwtService {
        static CLIENT_SECRET = process.env.CLIENT_SECRET || "client-secret";
        static ACCESS_TOKEN_EXPIRATION = "15m";

        static async generateTokens(userId, email, rememberMe = false) {
            const refreshDelay = remember_me
                ? 60 * 60 * 24 * 7 // 7 days
                : 60 * 60 * 24; // 24 hours

            const accessToken = jwt.sign(
                { id: userId, email },
                JwtService.CLIENT_SECRET,
                { expiresIn: JwtService.ACCESS_TOKEN_EXPIRATION }
            );

            const refreshToken = jwt.sign(
                { id: userId },
                JwtService.CLIENT_SECRET,
                { expiresIn: refreshDelay }
            );

            return {
                accessToken,
                refreshToken,
            };
        }
    }

    module.exports = { JwtService, PasswordService };
'@


$express_project_auth_middleware_content = @'
    "use strict";

    const jwt = require("jsonwebtoken");
    const { error } = require("../services/response.service");

    const authMiddleware = async (req, res, next) => {
        try {
            const authHeader = req.headers.authorization;

            if (!authHeader) {
                return res.send(error(401, "Authorization header is missing", { code: "AUTH_HEADER_MISSING" }));
            }

            if (!authHeader.startsWith("Bearer ")) {
                return res.send(error(401, "Invalid authorization format", { code: "INVALID_AUTH_FORMAT" }));
            }

            const token = authHeader.split(" ")[1];

            const decoded = jwt.verify(token, process.env.CLIENT_SECRET || "client-secret");

            if (!decoded || !decoded.id) {
                return res.send(error(403, "Invalid token payload", { code: "INVALID_TOKEN_PAYLOAD" }));
            }

            req.user = decoded;
            next();
        } catch (err) {
            console.error("Auth error:", err);
            return res.send(error(403, "Authentication failed", { code: "AUTH_FAILED" }));
        }
    };

    module.exports = { authMiddleware };
'@


function Express-Auth {
    if (-Not (Test-Path "package.json")) {
        Write-Host "package.json not found. Run this inside a Node.js project."
        exit 1
    }

    Write-Host "Installing authentication dependencies..."
    npm install bcrypt jsonwebtoken uuid

    $dirs = @(
        "app/services",
        "app/middlewares"
    )
    foreach ($d in $dirs) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

    Set-Content "app/services/auth.service.js" -Value $express_project_auth_service_content -Encoding UTF8
    Set-Content "app/middlewares/auth.middleware.js" -Value $express_project_auth_middleware_content -Encoding UTF8

    $files = @(".env", ".env.example")

    $auth_vars = @{
        "CLIENT_SECRET" = "client-secret"
    }

    foreach ($file in $files) {

        if (-Not (Test-Path $file)) {
            New-Item -ItemType File -Path $file | Out-Null
        }

        $content = Get-Content $file -Raw

        foreach ($key in $auth_vars.Keys) {
            if ($content -notmatch "(?m)^$key=") {
                Add-Content -Path $file -Value "`n$key='$($auth_vars[$key])'"
            }
        }
        Add-Content -Path $file -Value "`n"
    }

    Write-Host "Formatting project code..."
    npm run format

    Write-Host "Authentication setup completed successfully!"
    Write-Host "JWT service and auth middleware are ready to use."
    Write-Host "Protect your routes using authMiddleware."
}


function Setup-Express-Auth {
    Express-Auth
}