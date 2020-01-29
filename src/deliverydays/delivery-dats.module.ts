import { Module } from '@nestjs/common';
import { DeliveryDaysController } from './delivery-days.controller';
import { DeliveryDaysService } from './deliver-days.service';
import { DeliveryDaysProviders } from './delivery-days.providers';
import { DatabaseModule } from '../db/database.modules';

@Module({
  imports: [DatabaseModule],
  providers: [...DeliveryDaysProviders, DeliveryDaysService],
  controllers: [DeliveryDaysController],
  exports: [],
})
export class DeliveryDaysModule {}
