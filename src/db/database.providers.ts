import { createConnection } from 'typeorm';
import {environment} from '../env';

export const databaseProviders = [
  {
    provide: 'DATABASE_CONNECTION',
    useFactory: async () =>
      await createConnection({
        type: 'mysql',
        host: environment.DB.HOST,
        port: environment.DB.PORT,
        username: environment.DB.USERNAME,
        password: environment.DB.PASSWORD,
        database: environment.DB.NAME,
        entities: [__dirname + '/../**/*.entity{.ts,.js}'],
        synchronize: environment.DB.SYNCHRONIZE,
      }),
  },
];
