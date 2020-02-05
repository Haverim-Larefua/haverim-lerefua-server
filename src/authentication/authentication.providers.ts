import { Connection } from 'typeorm';
import {ParcelStatus} from '../entity/parcel.status.entity';
import {Role} from '../entity/role.entity';

export const statusProvider = [
  {
    provide: 'CONFIGURATION_STATUS_REPOSITORY',
    useFactory: (connection: Connection) => connection.getRepository(ParcelStatus),
    inject: ['DATABASE_CONNECTION'],
  },
];

export const roleProvider = [
  {
    provide: 'CONFIGURATION_ROLE_REPOSITORY',
    useFactory: (connection: Connection) => connection.getRepository(Role),
    inject: ['DATABASE_CONNECTION'],
  },
];
