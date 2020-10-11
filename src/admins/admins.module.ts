import { Module } from '@nestjs/common';
import { AdminsController } from './admins.controller';
import { AdminsService } from './admins.service';
import { adminProviders } from './admins.providers';
import { DatabaseModule } from '../db/database.modules';
import { AuthenticationModule } from 'src/authentication/authentication.module';

@Module({
  imports: [
     DatabaseModule,
     AuthenticationModule,
    ],
  providers: [...adminProviders, AdminsService],
  controllers: [AdminsController],
  exports: [],
})
export class AdminsModule {}
