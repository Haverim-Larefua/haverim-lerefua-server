import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { UsersModule } from './users/users.module';
import { ParcelsModule } from './parcels/parcels.module';
import { PushModule } from './pushNotification/push.module';
import { ConfigModule } from '@nestjs/config';

@Module({
  imports: [UsersModule, ParcelsModule, PushModule, TypeOrmModule.forRoot(),  ConfigModule.forRoot()],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
