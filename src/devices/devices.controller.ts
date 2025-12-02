import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Logger,
} from '@nestjs/common';
import { ApiResponse } from '@nestjs/swagger';
import { DevicesService } from './devices.service';
import { CreateDeviceDto } from './dto/create-device.dto';
import { UpdateDeviceDto } from './dto/update-device.dto';

@Controller('devices')
export class DevicesController {
  private readonly logger = new Logger(DevicesController.name);

  constructor(private readonly devicesService: DevicesService) {}

  @Post()
  @ApiResponse({ status: 201, description: 'Device created successfully' })
  create(@Body() dto: CreateDeviceDto) {
    this.logger.log(`POST - Device creation initiated successfully`);
    return this.devicesService.create(dto);
  }

  @Get()
  @ApiResponse({ status: 200, description: 'List of all devices' })
  findAll() {
    return this.devicesService.findAll();
  }

  @Get(':id')
  @ApiResponse({ status: 200, description: 'Device found' })
  @ApiResponse({ status: 404, description: 'Device not found' })
  findOne(@Param('id') id: string) {
    return this.devicesService.findOne(id);
  }

  @Patch(':id')
  @ApiResponse({ status: 200, description: 'Device updated' })
  @ApiResponse({ status: 404, description: 'Device not found' })
  update(@Param('id') id: string, @Body() dto: UpdateDeviceDto) {
    return this.devicesService.update(id, dto);
  }

  @Delete(':id')
  @ApiResponse({ status: 200, description: 'Device deleted' })
  @ApiResponse({ status: 404, description: 'Device not found' })
  remove(@Param('id') id: string) {
    return this.devicesService.remove(id);
  }
}
