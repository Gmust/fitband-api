import {
  Controller,
  Get,
  Body,
  Patch,
  Param,
  Delete,
  HttpCode,
  HttpStatus,
  UseGuards,
} from '@nestjs/common';
import { ApiResponse, ApiBody, ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { DeviceService } from './device.service';
import { UpdateDeviceDto } from './dto/update-device.dto';
import { AuthGuard } from '../common/guards/auth.guard';
import { GetUser } from '../common/decorators/get-user.decorator';
import { User } from '@prisma/client';

@ApiTags('Devices')
@Controller('devices')
@ApiBearerAuth('access-token')
export class DeviceController {
  constructor(private readonly deviceService: DeviceService) {}

  @Get()
  @ApiResponse({ status: 200, description: 'List of all devices' })
  findAll() {
    return this.deviceService.findAll();
  }

  @Get('my-device')
  @UseGuards(AuthGuard)
  @ApiResponse({ status: 200, description: "User's device" })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 404, description: 'Device not found' })
  findMyDevice(@GetUser() user: User) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-member-access
    return this.deviceService.findByUserId(user.id);
  }

  @Get(':id')
  @ApiResponse({ status: 200, description: 'Device found' })
  @ApiResponse({ status: 404, description: 'Device not found' })
  findOne(@Param('id') id: string) {
    return this.deviceService.findOne(id);
  }

  @Patch(':id')
  @ApiBody({ type: UpdateDeviceDto })
  @ApiResponse({ status: 200, description: 'Device updated' })
  @ApiResponse({ status: 400, description: 'Bad request' })
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
