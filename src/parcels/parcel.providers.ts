import { Connection, Repository } from 'typeorm';
import { Parcel } from '../entity/parcel.entity';
export const parcelProviders = [
  {
    provide: 'PARCEL_REPOSITORY',
    useFactory: (connection: Connection) => connection.getRepository(Parcel),
    inject: ['DATABASE_CONNECTION'],
  },
];
