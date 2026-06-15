import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  home() {
    return {
      project: 'Ambulance Service',
      status: 'Running',
    };
  }
}