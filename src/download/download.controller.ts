import { Controller, Get, Res, Logger } from '@nestjs/common';
import { Response } from "express";
import path = require('path');

@Controller('download')
export class DownloadController {
    private readonly fileName = "FFH.apk";
    private readonly filePath = path.join(__dirname, "../", "assets/downloads");

    @Get()
    downloadAPKFile(@Res() res: Response): void {
        Logger.log(`[DownloadController] downloadAPKFile()`);
        // Todo: handle error
        res.download(`${this.filePath}/${this.fileName}`);
    }
}