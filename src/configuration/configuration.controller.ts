import { Controller, Get, Logger } from '@nestjs/common';
import {ConfigurationService} from './configuration.service';

@Controller('configuration')
export class ConfigurationController {
  constructor(private readonly configurationService: ConfigurationService) {}

  @Get()
  getConfiguration() {
    Logger.log(`[configuration] getConfiguration()`);
    return this.configurationService.getConfiguration();
  }

}
