import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  HttpCode,
  HttpStatus,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ApiResponse } from '@nestjs/swagger';
import { DeviceService } from './device.service';
import { CreateDeviceDto } from './dto/create-device.dto';
import { UpdateDeviceDto } from './dto/update-device.dto';
import { JwtAuthGuard } from '../common/guards/auth.guard';

@Controller('devices')
export class DeviceController {
  constructor(private readonly deviceService: DeviceService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiResponse({ status: 201, description: 'Device created successfully' })
  create(@Body() createDeviceDto: CreateDeviceDto) {
    return this.deviceService.create(createDeviceDto);
  }

  @Get()
  @ApiResponse({ status: 200, description: 'List of all devices' })
  findAll() {
    return this.deviceService.findAll();
  }

  @Get('my-device')
  @UseGuards(JwtAuthGuard)
  @ApiResponse({ status: 200, description: 'User\'s device' })
  @ApiResponse({ status: 404, description: 'Device not found' })
  findMyDevice(@Request() req) {
    const userId = req.user.userId;
    return this.deviceService.findByUserId(userId);
  }

  @Get(':id')
  @ApiResponse({ status: 200, description: 'Device found' })
  @ApiResponse({ status: 404, description: 'Device not found' })
  findOne(@Param('id') id: string) {
    return this.deviceService.findOne(id);
  }

  @Patch(':id')
  @ApiResponse({ status: 200, description: 'Device updated' })
  @ApiResponse({ status: 404, description: 'Device not found' })
  update(@Param('id') id: string, @Body() updateDeviceDto: UpdateDeviceDto) {
    return this.deviceService.update(id, updateDeviceDto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiResponse({ status: 204, description: 'Device deleted' })
  @ApiResponse({ status: 404, description: 'Device not found' })
  remove(@Param('id') id: string) {
    return this.deviceService.remove(id);
  }
}
