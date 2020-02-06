import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { UsersModule } from './users/users.module';
import { ParcelsModule } from './parcels/parcels.module';
import {AuthenticationModule} from './authentication/authentication.module';
import {environment} from './env';
import {join} from 'path';
import {PushTokenModule} from './push-token/push-token.module';

@Module({
  imports: [
    UsersModule,
    TypeOrmModule.forRoot({
      type: 'mysql',
      host: environment.DB.HOST,
      port: environment.DB.PORT,
      database: environment.DB.NAME,
      username: environment.DB.USERNAME,
      password: environment.DB.PASSWORD,
      entities: [join(__dirname, '**/**.entity{.ts,.js}')],
      synchronize: environment.DB.SYNCHRONIZE,
    }),
    ParcelsModule,
    AuthenticationModule,
    PushTokenModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
