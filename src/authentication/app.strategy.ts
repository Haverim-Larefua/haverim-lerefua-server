import {Injectable, Logger, UnauthorizedException} from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import {environment} from '../env';
import {IAppTokenPayload} from './authentication.service';
import {UsersService} from '../users/users.service';
import {User} from "../entity/user.entity";

@Injectable()
export class AppStrategy extends PassportStrategy(Strategy, 'app') {
    constructor(private readonly userService: UsersService) {
        super({
            jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
            secretOrKey: environment.JWT_SECRET,
        });
    }

    async validate(payload: IAppTokenPayload): Promise<User> {
        Logger.debug(`[v] validate() payload: ${payload}`);
        const user = await this.userService.getUserById(payload.id);
        if (!user) {
            Logger.error(`[AppStrategy] validate() can not find user with payload: ${JSON.stringify(payload)}`);
            throw new UnauthorizedException();
        }
        Logger.debug(`[AppStrategy] validate() user validated successfully`);
        return user;
    }
}
