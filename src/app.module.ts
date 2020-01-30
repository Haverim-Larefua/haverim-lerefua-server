import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { UsersModule } from './users/users.module';
import { ParcelsModule } from './parcels/parcels.module';

@Module({
  imports: [UsersModule, TypeOrmModule.forRoot(), ParcelsModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
