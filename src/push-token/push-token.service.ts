import {Injectable, Inject, Logger} from '@nestjs/common';
import { Repository } from 'typeorm';
import {PushToken} from '../entity/push-token.entity';

@Injectable()
export class PushTokenService {

  constructor(
    @Inject('PUSH_TOKEN_REPOSITORY') private readonly pushTokenRepository: Repository<PushToken>,
  ) {}

  async getAllPushTokens() {
    const pushTokens = await this.pushTokenRepository.find({});
    return pushTokens;
  }

  async updateAddPushToken(userId: number, pushToken: string): Promise<void> {
    const tokenEntity: PushToken = await this.pushTokenRepository.findOne({ userId });
    Logger.log(`[PushTokenService] updateAddPushToken(${userId}, ${pushToken})`);
    if (!tokenEntity) {
      // Create new recorder
      Logger.log(`[PushTokenService] updateAddPushToken() user not found in push tokens list, adding new push token`);
      await this.pushTokenRepository.save({
        token: pushToken,
        userId,
      } as PushToken);
    } else {
      // Update existing record
      Logger.log(`[PushTokenService] updateAddPushToken() user found in push tokens list, updating push token`);
      await this.pushTokenRepository.update(tokenEntity.id, {
        token: pushToken,
      } as PushToken);
    }
  }

}
