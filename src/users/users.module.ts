import { Module } from '@nestjs/common';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { userProviders } from './users.providers';
import { DatabaseModule } from '../db/database.modules';

@Module({
  imports: [
      DatabaseModule,
  ],
  providers: [...userProviders, UsersService],
  controllers: [UsersController],
  exports: [],
})
export class UsersModule {}
