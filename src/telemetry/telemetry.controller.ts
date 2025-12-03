import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  HttpCode,
  HttpStatus,
  ParseIntPipe,
} from '@nestjs/common';
import { ApiResponse, ApiBody, ApiTags, ApiQuery } from '@nestjs/swagger';
import { TelemetryService } from './telemetry.service';
import { CreateTelemetryDto } from './dto/create-telemetry.dto';
import { UpdateTelemetryDto } from './dto/update-telemetry.dto';

@ApiTags('Telemetry')
@Controller('telemetry')
export class TelemetryController {
  constructor(private readonly telemetryService: TelemetryService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiBody({ type: CreateTelemetryDto })
  @ApiResponse({ status: 201, description: 'Telemetry created successfully' })
  @ApiResponse({ status: 400, description: 'Bad request' })
  create(@Body() createTelemetryDto: CreateTelemetryDto) {
    return this.telemetryService.create(createTelemetryDto);
  }

  @Get()
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'offset', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'List of all telemetry data' })
  findAll(@Query('limit') limit?: string, @Query('offset') offset?: string) {
    const limitNum = limit ? parseInt(limit, 10) : undefined;
    const offsetNum = offset ? parseInt(offset, 10) : undefined;
    return this.telemetryService.findAll(limitNum, offsetNum);
  }

  @Get(':id')
  @ApiResponse({ status: 200, description: 'Telemetry found' })
  @ApiResponse({ status: 404, description: 'Telemetry not found' })
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.telemetryService.findOne(id);
  }

  @Get('device/:deviceId')
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'offset', required: false, type: Number })
  @ApiResponse({
    status: 200,
    description: 'List of telemetry data for the device',
  })
  findByDevice(
    @Param('deviceId') deviceId: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    const limitNum = limit ? parseInt(limit, 10) : undefined;
    const offsetNum = offset ? parseInt(offset, 10) : undefined;
    return this.telemetryService.findByDevice(deviceId, limitNum, offsetNum);
  }

  @Get('device/:deviceId/latest')
  @ApiResponse({ status: 200, description: 'Latest telemetry for the device' })
  getLatestByDevice(@Param('deviceId') deviceId: string) {
    return this.telemetryService.getLatestByDevice(deviceId);
  }

  @Patch(':id')
  @ApiBody({ type: UpdateTelemetryDto })
  @ApiResponse({ status: 200, description: 'Telemetry updated' })
  @ApiResponse({ status: 400, description: 'Bad request' })
  @ApiResponse({ status: 404, description: 'Telemetry not found' })
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateTelemetryDto: UpdateTelemetryDto,
  ) {
    return this.telemetryService.update(id, updateTelemetryDto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiResponse({ status: 204, description: 'Telemetry deleted' })
  @ApiResponse({ status: 404, description: 'Telemetry not found' })
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.telemetryService.remove(id);
  }
}
