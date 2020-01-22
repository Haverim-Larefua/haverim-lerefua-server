import { Module } from '@nestjs/common';
import { ParcelsController } from './parcels.controller';
import { ParcelsService } from './parcels.service';
import { parcelProviders } from './parcel.providers';
import { DatabaseModule } from '../db/database.modules';

@Module({
  imports: [DatabaseModule],
  providers: [...parcelProviders, ParcelsService],
  controllers: [ParcelsController],
  exports: [],
})
export class ParcelsModule {}
