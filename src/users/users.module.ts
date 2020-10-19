import { Module } from '@nestjs/common';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { userProviders } from './users.providers';
import { DatabaseModule } from '../db/database.modules';
import { ParcelsModule } from '../parcels/parcels.module';

@Module({
  imports: [
      DatabaseModule,
      ParcelsModule,
  ],
  providers: [...userProviders, UsersService],
  controllers: [UsersController],
  exports: [UsersService],
})
export class UsersModule {}
