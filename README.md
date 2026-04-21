# 🚀 Express Project Aliases – Documentation  

![GitHub repo size](https://img.shields.io/github/repo-size/joshue-agape/ps-express-project-aliases)
![GitHub stars](https://img.shields.io/github/stars/joshue-agape/ps-express-project-aliases?style=social)
![GitHub forks](https://img.shields.io/github/forks/joshue-agape/ps-express-project-aliases?style=social)
![GitHub issues](https://img.shields.io/github/issues/joshue-agape/ps-express-project-aliases)
![License](https://img.shields.io/github/license/joshue-agape/ps-express-project-aliases)
![PowerShell](https://img.shields.io/badge/PowerShell-Ready-blue?logo=powershell)

A practical guide to setting up Express.js project aliases in PowerShell to streamline your development workflow and boost command-line efficiency.  

## ⚙️ PowerShell Profile Setup  

Before using the aliases, you need to configure your PowerShell profile.  

### Check if the profile exists  

```bash
Test-Path $PROFILE
```

True → the profile already exists  
False → proceed to the next step  

### Create the profile

```bash
New-Item -Path $PROFILE -ItemType File -Force
```

### Open and edit the profile  

- Using Notepad:  

```bash
New-Item -Path $PROFILE -ItemType File -Force
```

- Or using VS Code:  

```bash
code $PROFILE
```

## 📦 Install Aliases  

### Clone the repository  

```bash
git clone https://github.com/joshue-agape/ps-express-project-aliases.git express-project-cli
```

### Copy alias files to config directory  

```bash
cp express-project-cli "$HOME\.config\alias\"
```

💡 Make sure the directory exists, otherwise create it:

```bash
mkdir -p "$HOME\.config\alias\"
```

### Import aliases into PowerShell  

Add the following line to your PowerShell profile  

```bash
. "$HOME\.config\alias\express-project-cli\index.ps1"
```

### Apply changes  

Reload your profile  

```bash
. $PROFILE
```

### ✅ Done  

Your aliases are now active 🎉  
You can start using them immediately to speed up your workflow.  

### ⚙️ CLI Commands

🚀 To Create a New Project  
Scaffold a new Express project in seconds using one of the following commands:  

```bash
New-Express project_name
```

```bash
Create-Express project_name
```

```bash
New-Express-Project project_name
```

```bash
Create-Express-Project project_name
```

🗄️ To Setup Database  
Initialize and configure the database for your Express application:  

```bash
Express-Database
```

```bash
Setup-Express-Database
```

📧 To Setup Mailer  
Enable and configure email services:  

```bash
Express-Mailer
```

```bash
Setup-Express-Mail
```

📦 To Setup Multer  
Configure file upload handling with Multer:  

```bash
Express-Multer
```

```bash
Setup-Express-Multer
```

🔐 To Setup Authentication  
Set up authentication for your Express application:  

```bash
Express-Auth
```

```bash
Setup-Express-Auth
```

💡 Tips  
Restart PowerShell if changes don’t apply  
Double-check file paths if aliases aren’t working  
Customize your aliases in index.ps1 to fit your needs  
