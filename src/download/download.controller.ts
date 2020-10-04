import { Controller, Get, Res, Logger } from '@nestjs/common';
import { Response } from "express";
import path = require('path');

@Controller('download')
export class DownloadController {
    private readonly fileAPKName = "FFH.apk";
    private readonly fileIPhoneName = "IPhone.apk";
    private readonly filePath = path.join(__dirname, "../", "assets/downloads");

    @Get("android")
    downloadAPKFile(@Res() res: Response): void {
        Logger.log(`[DownloadController] downloadAPKFile()`);
        // Todo: handle error
        res.download(`${this.filePath}/${this.fileAPKName}`);
    }

    @Get("iphone")
    downloadIPhoneFile(@Res() res: Response): void {
        Logger.log(`[DownloadController] downloadIPhoneFile()`);
        // Todo: handle error
        res.download(`${this.filePath}/${this.fileIPhoneName}`);
    }
}