import { Test, TestingModule } from '@nestjs/testing';
import { DeliveryDaysController } from './delivery-days.controller';

describe('DeliveryDays Controller', () => {
  let controller: DeliveryDaysController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [DeliveryDaysController],
    }).compile();

    controller = module.get<DeliveryDaysController>(DeliveryDaysController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
