import {Body, Controller, Logger, Post} from '@nestjs/common';
import {ILoginRequest} from '../entity/login.model';
import {AuthenticationService} from './authentication.service';
import {User} from '../entity/user.entity';
import {Admin} from '../entity/admin.entity';

export interface IToken {
  token: string;
}

@Controller('auth')
export class AuthenticationController {
  constructor(private readonly authenticationService: AuthenticationService) {}

  @Post('user')
  loginUser(@Body() login: ILoginRequest): Promise<{ user: User, token: string }> {
    Logger.log(`[AuthenticationController] loginUser() username: ${login.username}, password: '*****'`);
    return this.authenticationService.loginUser(login.username, login.password);
  }

  @Post('admin')
  loginAdmin(@Body() login: ILoginRequest): Promise<{ admin: Admin, token: string }> {
    Logger.log(`[AuthenticationController] loginAdmin() username: ${login.username}, password: '*****'`);
    return this.authenticationService.loginAdmin(login.username, login.password);
  }

}
