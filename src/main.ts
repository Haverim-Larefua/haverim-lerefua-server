import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import {INestApplication, Logger, ValidationPipe} from '@nestjs/common';
import * as cors from 'cors';
import {environment} from './env';
import {DocumentBuilder, SwaggerModule} from '@nestjs/swagger';

/**
 * Swagger will not be established in case SWAGGER_UP flag is false
 *
 * @param app
 */
function setupSwagger(app: INestApplication) {
  if (environment.SWAGGER_UP) {
    // Swagger Setup
    const options = new DocumentBuilder()
        .setTitle('Haverim Lerfua')
        .setDescription('Haverim Lerfua description')
        .setVersion('1.0')
        .addServer('http://')
        .build();
    const document = SwaggerModule.createDocument(app, options);
    SwaggerModule.setup('swagger', app, document);
  }
}

var corsOptions = {
  origin: '*',
  optionsSuccessStatus: 200 // some legacy browsers (IE11, various SmartTVs) choke on 204 
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(cors(corsOptions));
  app.useGlobalPipes(new ValidationPipe());
  setupSwagger(app);
  Logger.log(`app is listening on port: ${environment.SERVER.PORT}`);
  await app.listen(environment.SERVER.PORT);
}
bootstrap();
