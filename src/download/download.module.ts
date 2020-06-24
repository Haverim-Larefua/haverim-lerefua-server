import { Module } from '@nestjs/common';
import { DownloadController } from './download.controller';

@Module({
  controllers: [DownloadController],
  providers: []
})
export class DownloadModule {}
