import { Module, Global } from '@nestjs/common';
import { PushService } from './push.service';
import { PushController } from './push.controller';
import { ConfigModule } from '@nestjs/config';

// @Global()
@Module({
  imports: [ConfigModule.forRoot({envFilePath: './vapid.env'})],
  controllers: [PushController],
  providers: [PushService],
  exports: [PushService]
})
export class PushModule {}
