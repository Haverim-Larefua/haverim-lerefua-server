import { AdminStrategy } from './admin.strategy';
import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import {environment} from '../env';
import {AuthenticationController} from './authentication.controller';
import {AuthenticationService} from './authentication.service';
import {UsersService} from '../users/users.service';
import {AppStrategy} from './app.strategy';
import {userProviders} from '../users/users.providers';
import {DatabaseModule} from '../db/database.modules';
import {adminProviders} from '../admins/admins.providers';
import {AdminsService} from '../admins/admins.service';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    DatabaseModule,
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.register({
      secret: environment.JWT_TOKEN_SECRET,
      signOptions: {
        expiresIn: environment.JWT_TOKEN_LIFE,
      },
    }),
    UsersModule,
  ],
  controllers: [AuthenticationController],
  providers: [AuthenticationService, AppStrategy, ...adminProviders, AdminsService, AdminStrategy],
  exports: [PassportModule, AuthenticationService],
})
export class AuthenticationModule {}
