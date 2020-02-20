import {Body, Controller, Get, Logger, Param, Put} from '@nestjs/common';
import {PushTokenService} from './push-token.service';

@Controller('push-token')
export class PushTokenController {
  constructor(private readonly pushTokenService: PushTokenService) {}

  @Get()
  getAllPushTokens() {
    Logger.log(`[PushTokenController] getAllPushTokens()`);
    return this.pushTokenService.getAllPushTokens();
  }

  @Put('update/:userId')
  updateAddPushToken(
      @Param('userId') userId: number,
      @Body() body: { token: string }): Promise<void> {
    Logger.log(`[PushTokenController] updateAddPushToken(${userId}, ${JSON.stringify(body)})`);
    return this.pushTokenService.updateAddPushToken(userId, body.token);
  }

  @Put('push/:userId')
  notifyUser(
    @Param('userId') userId: number,
    @Body() body:{title: string, subtitle: string, message: string}) : Promise<void> {
      return this.pushTokenService.notifyUser(userId, body.title, body.subtitle, body.message);
  }

}
