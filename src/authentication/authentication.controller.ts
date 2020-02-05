import {Body, Controller, Get, Logger, Post} from '@nestjs/common';
import {ILoginRequest} from '../entity/login.model';
import {AuthenticationService} from './authentication.service';
import {User} from '../entity/user.entity';

export interface IToken {
  token: string;
}

@Controller('auth')
export class AuthenticationController {
  constructor(private readonly authenticationService: AuthenticationService) {}

  @Post()
  login(@Body() login: ILoginRequest): Promise<{ user: User, token: string }> {
    Logger.log(`[AuthenticationController] login() username: ${login.username}, password: '*****'`);
    return this.authenticationService.login(login.username, login.password);
  }

}
