import { Module } from '@nestjs/common';
import { DatabaseModule } from '../db/database.modules';
import { UsersModule } from '../users/users.module';
import {pushTokenProvider} from './push-token.providers';
import {PushTokenController} from './push-token.controller';
import {PushTokenService} from './push-token.service';

@Module({
  imports: [DatabaseModule, UsersModule],
  providers: [...pushTokenProvider, PushTokenService],
  controllers: [PushTokenController],
  exports: [],
})
export class PushTokenModule {}
