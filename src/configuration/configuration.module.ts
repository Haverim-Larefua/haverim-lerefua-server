import { Module } from '@nestjs/common';
import { DatabaseModule } from '../db/database.modules';
import { UsersModule } from '../users/users.module';
import {ConfigurationService} from './configuration.service';
import {roleProvider, statusProvider} from './configuration.providers';
import {ConfigurationController} from './configuration.controller';

@Module({
  imports: [DatabaseModule, UsersModule],
  providers: [...statusProvider, ...roleProvider, ConfigurationService],
  controllers: [ConfigurationController],
  exports: [],
})
export class ConfigurationModule {}
