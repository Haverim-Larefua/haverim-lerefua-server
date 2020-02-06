import { Module } from '@nestjs/common';
import { ParcelsController } from './parcels.controller';
import { ParcelsService } from './parcels.service';
import {parcelProviders, parcelTrackingProviders} from './parcel.providers';
import { DatabaseModule } from '../db/database.modules';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [DatabaseModule, UsersModule],
  providers: [...parcelProviders, ...parcelTrackingProviders, ParcelsService],
  controllers: [ParcelsController],
  exports: [],
})
export class ParcelsModule {}
