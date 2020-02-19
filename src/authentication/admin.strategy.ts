import {Injectable, Logger, UnauthorizedException} from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import {environment} from '../env';
import {IAppTokenPayload} from './authentication.service';
import {AdminsService} from '../admins/admins.service';
import {Admin} from '../entity/admin.entity';

@Injectable()
export class AdminStrategy extends PassportStrategy(Strategy, 'admin') {
    constructor(private readonly adminService: AdminsService) {
        super({
            jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
            secretOrKey: environment.JWT_TOKEN_SECRET,
        });
    }

    async validate(payload: IAppTokenPayload): Promise<Admin> {
        Logger.debug(`[AdminStrategy] validate() payload: ${payload}`);
        const admin = await this.adminService.getAdminById(payload.id);
        if (!admin) {
            Logger.error(`[AdminStrategy] validate() can not find admin with payload: ${JSON.stringify(payload)}`);
            throw new UnauthorizedException();
        }
        Logger.debug(`[AdminStrategy] validate() admin validated successfully`);
        return admin;
    }
}
