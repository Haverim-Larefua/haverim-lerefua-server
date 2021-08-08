import {Body, Controller, Logger, Post, Put} from '@nestjs/common';
import { User } from 'src/entity/user.entity';
import {ILoginRequest} from '../entity/login.model';
import {AuthenticationService, IAuthAdminResponse, IAuthUserResponse} from './authentication.service';

export interface IRefreshToken {
  refreshToken: string;
}

@Controller('auth')
export class AuthenticationController {
  constructor(private readonly authenticationService: AuthenticationService) {}

  @Post('user')
  loginUser(@Body() login: ILoginRequest): Promise<IAuthUserResponse> {
    Logger.log(`[AuthenticationController] loginUser() username: ${login.username}, password: '*****'`);
    return this.authenticationService.loginUser(login.username, login.password);
  }

  @Post('admin')
  loginAdmin(@Body() login: ILoginRequest): Promise<IAuthAdminResponse> {
    Logger.log(`[AuthenticationController] loginAdmin() username: ${login.username}, password: '*****'`);
    return this.authenticationService.loginAdmin(login.username, login.password);
  }

  @Post('token')
  refreshToken(@Body() refreshTokenObject: IRefreshToken): Promise<IAuthUserResponse> {
    Logger.log(`[AuthenticationController] refreshToken() refreshToken: ${JSON.stringify(refreshTokenObject)}`);
    return this.authenticationService.refreshToken(refreshTokenObject.refreshToken);
  }

  @Put('forgotPassword')
  forgotPassword(@Body() data: {phoneNumber: string}): Promise<User> {
    Logger.log(`[AuthenticationController] forgotPassword(${data.phoneNumber})`);
    return this.authenticationService.forgotPassword(data.phoneNumber);
  }
}
