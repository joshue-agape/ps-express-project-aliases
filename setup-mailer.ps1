$express_project_email_service_content = @'
    'use strict';

    const nodemailer = require('nodemailer');
    const ejs = require('ejs');
    const path = require('path');

    class EmailService {
        static createTransporter() {
            return nodemailer.createTransport({
                host: process.env.SMTP_HOST,
                port: Number(process.env.SMTP_PORT) || 587,
                secure: process.env.SMTP_SECURE === 'true',
                auth: {
                    user: process.env.SMTP_USER,
                    pass: process.env.SMTP_PASS,
                },
            });
        }

        /**
        * Send an email using an EJS template
        */
        static async sendEmailTemplate({ to, subject, template, variables = {} }) {
            const transporter = EmailService.createTransporter();

            const templatePath = path.join(
                __dirname,
                '..',
                'templates',
                `${template}.ejs`
            );

            const html = await ejs.renderFile(templatePath, {
                ...variables,
                subject,
            });

            const mailOptions = {
                from: process.env.SMTP_FROM || process.env.SMTP_USER,
                to,
                subject,
                html,
            };

            try {
                const info = await transporter.sendMail(mailOptions);
                console.log('Email sent:', info.messageId);
                return info;
            } catch (err) {
                console.error('Email sending error:', err);
                throw err;
            }
        }
    }

    module.exports = EmailService;
'@


$express_project_example_template_content = @'
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8" />
        <title><%= subject %></title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    </head>
    <body style="margin:0; padding:0; background-color:#f4f6f8; font-family: Arial, Helvetica, sans-serif;">
        <p style="margin:0 0 16px 0; font-size:16px;">
            Hello <strong><%= name %></strong>,
        </p>
    </body>
</html>
'@


$express_project_email_controller_content = @'
    const { EmailService } = require("../services/email.service");
    const { success, error } = require('../services/response.service');

    /**
     * Send a test email using a template
     */
    exports.sendTestEmail = (req, res) => {
        try {
            const { to, name } = req.body;

            if (!to) {
                return res.send(error(400, "Recipient email (to) is required"));
            }

            await EmailService.sendEmailTemplate({
                to,
                subject: "Test Email",
                template: "example",
                variables: {
                    name: name || "User",
                },
            });

            return res.send(error(200, "Email sent successfully"));
        } catch (error) {
            console.error("EmailController error:", error);
            return res.send(error(500, "Failed to send email"));
        }
    }
'@


$express_project_email_route_content = @'
    const express = require("express");
    const EmailController = require("../../controllers/email.controller");

    module.exports = () => {
        const router = express.Router();

        router.post("/send", EmailController.sendTestEmail);

        return router;
    };
'@


function Express-Mailer {
    if (-Not (Test-Path "package.json")) {
        Write-Host "package.json not found. Run this inside a Node.js project."
        exit 1
    }

    Write-Host "Installing email dependencies..."
    npm install nodemailer ejs

    $dirs = @(
        "app/services",
        "app/controllers",
        "app/routes/groups",
        "app/templates"
    )
    foreach ($d in $dirs) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

    Set-Content "app/services/email.service.js" -Value $express_project_email_service_content -Encoding UTF8
    Set-Content "app/templates/example.ejs" -Value $express_project_example_template_content -Encoding UTF8
    Set-Content "app/controllers/email.controller.js" -Value $express_project_email_controller_content -Encoding UTF8
    Set-Content "app/routes/groups/email.js" -Value $express_project_email_route_content -Encoding UTF8

    $files = @(".env", ".env.example")
    $db_vars = @{
        "SMTP_HOST" = "smtp.gmail.com"
        "SMTP_PORT" = "587"
        "SMTP_SECURE" = "false"
        "SMTP_USER" = "your-email@example.com"
        "SMTP_PASS" = "your-email-password"
        "SMTP_FROM" = "App Name <your-email@example.com>"
    }

    foreach ($file in $files) {
        if (-Not (Test-Path $file)) {
            New-Item -ItemType File -Path $file | Out-Null
        }

        $content = Get-Content $file -Raw

        foreach ($key in $db_vars.Keys) {
            if ($content -notmatch "^$key=") {
                Add-Content -Path $file -Value "$key=$($db_vars[$key])"
            }
        }
        Add-Content -Path $file -Value "`n"
    }

    Write-Host "Formatting project code..."
    npm run format

    Write-Host "Email service setup completed successfully!"
    Write-Host "SMTP configuration has been added to your .env files."
    Write-Host "You can now use EmailService to send emails."
}
