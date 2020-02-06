import { Connection } from 'typeorm';
import { Parcel } from '../entity/parcel.entity';
import {ParcelTracking} from '../entity/parcel.tracking.entity';

export const parcelProviders = [
  {
    provide: 'PARCEL_REPOSITORY',
    useFactory: (connection: Connection) => connection.getRepository(Parcel),
    inject: ['DATABASE_CONNECTION'],
  },
];

export const parcelTrackingProviders = [
  {
    provide: 'PARCEL_TRACKING_REPOSITORY',
    useFactory: (connection: Connection) => connection.getRepository(ParcelTracking),
    inject: ['DATABASE_CONNECTION'],
  },
];
