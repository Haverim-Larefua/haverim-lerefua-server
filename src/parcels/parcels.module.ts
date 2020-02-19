import { Module } from '@nestjs/common';
import { ParcelsController } from './parcels.controller';
import { ParcelsService } from './parcels.service';
import {parcelProviders, parcelTrackingProviders} from './parcel.providers';
import { DatabaseModule } from '../db/database.modules';
import { UsersModule } from '../users/users.module';
import {pushTokenProvider} from '../push-token/push-token.providers';

@Module({
  imports: [DatabaseModule, UsersModule],
  providers: [...parcelProviders, ...parcelTrackingProviders, ...pushTokenProvider, ParcelsService],
  controllers: [ParcelsController],
  exports: [],
})
export class ParcelsModule {}
