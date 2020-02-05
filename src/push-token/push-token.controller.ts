import { Controller, Get, Logger } from '@nestjs/common';
import {PushTokenService} from './push-token.service';

@Controller('push')
export class PushTokenController {
  constructor(private readonly pushTokenService: PushTokenService) {}

  @Get()
  getAllPushTokens() {
    Logger.log(`[PushTokenController] getAllPushTokens()`);
    return this.pushTokenService.getAllPushTokens();
  }

}
