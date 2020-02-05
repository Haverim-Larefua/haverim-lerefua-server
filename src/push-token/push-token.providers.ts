import { Connection } from 'typeorm';
import {PushToken} from '../entity/push-token.entity';

export const pushTokenProvider = [
  {
    provide: 'PUSH_TOKEN_REPOSITORY',
    useFactory: (connection: Connection) => connection.getRepository(PushToken),
    inject: ['DATABASE_CONNECTION'],
  },
];
