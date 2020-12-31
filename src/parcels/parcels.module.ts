import { Module } from '@nestjs/common';
import { ParcelsController } from './parcels.controller';
import { ParcelsService } from './parcels.service';
import {parcelProviders, parcelTrackingProviders} from './parcel.providers';
import { DatabaseModule } from '../db/database.modules';
import {pushTokenProvider} from '../push-token/push-token.providers';
import {PushTokenService} from '../push-token/push-token.service';
import { userProviders } from 'src/users/users.providers';

@Module({
  imports: [DatabaseModule],
  providers: [...parcelProviders, ...parcelTrackingProviders, ...pushTokenProvider, ...userProviders, ParcelsService, PushTokenService],
  controllers: [ParcelsController],
  exports: [ParcelsService],
})
export class ParcelsModule {}
