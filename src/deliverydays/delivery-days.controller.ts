import { Controller, Get, Logger } from '@nestjs/common';
import { DeliveryDaysService } from './deliver-days.service';

@Controller('delivery-days')
export class DeliveryDaysController {
  constructor(private readonly deliveryDaysService: DeliveryDaysService) {}

  @Get()
  getAllDeliveryDays() {
    Logger.log(`call to getAllDeliveryDays()`);
    return this.deliveryDaysService.getAllDD();
  }
}
