$express_project_multer_service_content = @'
    "use strict";

    const multer = require("multer");
    const path = require("path");
    const fs = require("fs");

    const ensureDirExists = (dirPath) => {
        if (!fs.existsSync(dirPath)) {
            fs.mkdirSync(dirPath, { recursive: true });
        }
    };

    const IMAGE_EXT = /\.(jpeg|jpg|png|gif)$/;
    const DOC_EXT = /\.(pdf|doc|docx|xls|xlsx)$/;

    const IMAGE_MIME = ["image/jpeg", "image/png", "image/gif"];

    const DOC_MIME = [
        "application/pdf",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/vnd.ms-excel",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    ];

    // ================= IMAGES =================

    const imageStorage = multer.diskStorage({
        destination: (req, file, cb) => {
            const dir = path.join(process.cwd(), "private/images");
            ensureDirExists(dir);
            cb(null, dir);
        },
        filename: (req, file, cb) => {
            const uniqueName =
                Date.now() +
                "-" +
                Math.round(Math.random() * 1e9) +
                path.extname(file.originalname).toLowerCase();

            cb(null, uniqueName);
        },
    });

    const imageFilter = (req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase();
        const isExtValid = IMAGE_EXT.test(ext);
        const isMimeValid = IMAGE_MIME.includes(file.mimetype);

        if (isExtValid && isMimeValid) {
            cb(null, true);
        } else {
            cb(new Error("Only image files (jpeg, jpg, png, gif) are allowed"), false);
        }
    };

    const uploadImage = multer({
        storage: imageStorage,
        fileFilter: imageFilter,
        limits: { fileSize: 5 * 1024 * 1024 },
    });

    // ================= DOCS =================

    const docsStorage = multer.diskStorage({
        destination: (req, file, cb) => {
            const dir = path.join(process.cwd(), "private/docs");
            ensureDirExists(dir);
            cb(null, dir);
        },
        filename: (req, file, cb) => {
            const uniqueName =
                Date.now() +
                "-" +
                Math.round(Math.random() * 1e9) +
                path.extname(file.originalname).toLowerCase();

            cb(null, uniqueName);
        },
    });

    const docsFilter = (req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase();
        const isExtValid = DOC_EXT.test(ext);
        const isMimeValid = DOC_MIME.includes(file.mimetype);

        if (isExtValid && isMimeValid) {
            cb(null, true);
        } else {
            cb(new Error("Only document files (pdf, doc, docx, xls, xlsx) are allowed"), false);
        }
    };

    const uploadDocs = multer({
        storage: docsStorage,
        fileFilter: docsFilter,
        limits: { fileSize: 5 * 1024 * 1024 },
    });

    // ================= IMAGE OR DOCS =================

    const storage = multer.diskStorage({
        destination: (req, file, cb) => {
            const ext = path.extname(file.originalname).toLowerCase();
            const isImage = IMAGE_EXT.test(ext);

            const baseDir = isImage ? "images" : "docs";

            const dir = path.join(
                process.cwd(),
                "private/files",
                baseDir,
                file.fieldname
            );

            ensureDirExists(dir);
            cb(null, dir);
        },

        filename: (req, file, cb) => {
            const uniqueName =
                Date.now() +
                "-" +
                Math.round(Math.random() * 1e9) +
                path.extname(file.originalname).toLowerCase();

            cb(null, uniqueName);
        },
    });

    const fileFilter = (req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase();

        const isImage =
            IMAGE_EXT.test(ext) && IMAGE_MIME.includes(file.mimetype);

        const isDoc =
            DOC_EXT.test(ext) && DOC_MIME.includes(file.mimetype);

        if (isImage || isDoc) {
            cb(null, true);
        } else {
            cb(new Error("File type not allowed"), false);
        }
    };

    const uploadFiles = multer({
        storage,
        fileFilter,
        limits: { fileSize: 10 * 1024 * 1024 },
    });

    module.exports = {
        uploadImage,
        uploadDocs,
        uploadFiles,
    };
'@


$express_project_multer_controller_content = @'
    "use strict";

    const path = require("path");
    const fs = require("fs");
    const { success, error } = require("../services/response.service");

    const getImage = (req, res) => {
        const { filename } = req.params;
        const filePath = path.join(process.cwd(), "private/images", filename);

        if (!fs.existsSync(filePath)) {
            return res.send(error(404, "Image not found"));
        }

        return res.sendFile(filePath);
    };

    const updateImage = async (req, res) => {
        try {
            if (!req.file) {
                return res.send(error(400, "Image file is required"));
            }

            const imageUrl = `${req.protocol}://${req.get("host")}/api/v1/multer/image/${req.file.filename}`;

            return res.send(success(200, "Image uploaded successfully", { imageUrl }));
        } catch (err) {
            console.error("Upload error:", err);
            return res.send(error(500, "Internal server error"));
        }
    };

    module.exports = { getImage, updateImage };
'@


$express_project_upload_router_content = @'
    "use strict";

    const express = require("express");
    const MulterController = require("../../controllers/multer.controller");
    const { uploadImage } = require("../../services/multer.service");

    module.exports = () => {
        const router = express.Router();

        router.get("/image/:filename", MulterController.getImage);

        router.put(
            "/image/update",
            uploadImage.single("image"),
            MulterController.updateImage
        );

        return router;
    };
'@


function Express-Multer {
    if (-Not (Test-Path "package.json")) {
        Write-Host "package.json not found. Run this inside a Node.js project."
        exit 1
    }

    Write-Host "Installing Multer..."
    npm install multer path fs

    $dirs = @(
        "app/services",
        "app/controllers",
        "app/routes/groups",
        "private"
    )
    foreach ($d in $dirs) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

    Set-Content "app/services/multer.service.js" -Value $express_project_multer_service_content -Encoding UTF8
    Set-Content "app/controllers/multer.controller.js" -Value $express_project_multer_controller_content -Encoding UTF8
    Set-Content "app/routes/groups/multer.route.js" -Value $express_project_upload_router_content -Encoding UTF8

    Write-Host "Formatting project code..."
    npm run format

    Write-Host "Multer setup completed successfully!"
    Write-Host "File upload service is ready (images & documents)."
    Write-Host "Use /api/v1/multer/image/update to upload files."
}


function Setup-Express-Multer {
    Express-Multer
}
