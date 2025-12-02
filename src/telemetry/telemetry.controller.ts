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
  Logger,
} from '@nestjs/common';
import { ApiResponse } from '@nestjs/swagger';
import { TelemetryService } from './telemetry.service';
import { CreateTelemetryDto } from './dto/create-telemetry.dto';
import { UpdateTelemetryDto } from './dto/update-telemetry.dto';

@Controller('telemetry')
export class TelemetryController {
  private readonly logger = new Logger(TelemetryController.name);

  constructor(private readonly telemetryService: TelemetryService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiResponse({ status: 201, description: 'Telemetry created successfully' })
  create(@Body() createTelemetryDto: CreateTelemetryDto) {
    this.logger.log(`POST - Telemetry creation initiated successfully with status ${HttpStatus.CREATED}`);
    return this.telemetryService.create(createTelemetryDto);
  }

  @Get()
  @ApiResponse({ status: 200, description: 'List of all telemetry data' })
  findAll(
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
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
  @ApiResponse({ status: 200, description: 'List of telemetry data for the device' })
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

  @Get('session/:sessionId')
  @ApiResponse({ status: 200, description: 'List of telemetry data for the session' })
  findBySession(
    @Param('sessionId') sessionId: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    const limitNum = limit ? parseInt(limit, 10) : undefined;
    const offsetNum = offset ? parseInt(offset, 10) : undefined;
    return this.telemetryService.findBySession(sessionId, limitNum, offsetNum);
  }

  @Patch(':id')
  @ApiResponse({ status: 200, description: 'Telemetry updated' })
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
