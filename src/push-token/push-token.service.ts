import { Injectable, Inject } from '@nestjs/common';
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

}
