import { Connection, Repository } from 'typeorm';
import { DeliveryDays } from '../entity/deliveyDays.entity';
export const DeliveryDaysProviders = [
  {
    provide: 'DELIVERY_DAYS_REPOSITORY',
    useFactory: (connection: Connection) =>
      connection.getRepository(DeliveryDays),
    inject: ['DATABASE_CONNECTION'],
  },
];
