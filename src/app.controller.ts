import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('/__coverage__')
  // tslint:disable: no-string-literal
  getCoverage() {
    if (global['__coverage__']) {
      return { coverage: global['__coverage__'] };
    }

    return null;
  }
}
