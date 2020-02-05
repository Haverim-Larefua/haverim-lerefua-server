import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import {Logger, ValidationPipe} from '@nestjs/common';
import * as cors from 'cors';
import {environment} from './env';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(cors());
  app.useGlobalPipes(new ValidationPipe());
  Logger.log(`app is listening on port: ${environment.SERVER.PORT}`);
  await app.listen(environment.SERVER.PORT);
}
bootstrap();
