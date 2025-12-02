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
  Put,
  Logger,
  UseGuards,
} from '@nestjs/common';
import { ApiResponse } from '@nestjs/swagger';
import { SessionService } from './session.service';
import { CreateSessionDto } from './dto/create-session.dto';
import { UpdateSessionDto } from './dto/update-session.dto';
import { JwtAuthGuard } from '../common/guards/auth.guard';

@Controller('sessions')
export class SessionController {
  private readonly logger = new Logger(SessionController.name);

  constructor(private readonly sessionService: SessionService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.CREATED)
  @ApiResponse({ status: 201, description: 'Session created successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  create(@Body() createSessionDto: CreateSessionDto) {
    this.logger.log(`POST - Session creation initiated successfully with status ${HttpStatus.CREATED}`);
    return this.sessionService.create(createSessionDto);
  }

  @Get()
  @ApiResponse({ status: 200, description: 'List of all sessions' })
  findAll() {
    return this.sessionService.findAll();
  }

  @Get(':id')
  @ApiResponse({ status: 200, description: 'Session found' })
  @ApiResponse({ status: 404, description: 'Session not found' })
  findOne(@Param('id') id: string) {
    return this.sessionService.findOne(id);
  }

  @Get('device/:deviceId')
  @ApiResponse({ status: 200, description: 'List of sessions for the device' })
  findByDevice(@Param('deviceId') deviceId: string) {
    return this.sessionService.findByDevice(deviceId);
  }

  @Get('device/:deviceId/active')
  @ApiResponse({ status: 200, description: 'Active session for the device' })
  findActiveByDevice(@Param('deviceId') deviceId: string) {
    return this.sessionService.findActiveByDevice(deviceId);
  }

  @Patch(':id')
  @ApiResponse({ status: 200, description: 'Session updated' })
  @ApiResponse({ status: 404, description: 'Session not found' })
  update(@Param('id') id: string, @Body() updateSessionDto: UpdateSessionDto) {
    return this.sessionService.update(id, updateSessionDto);
  }

  @Put(':id/end')
  @HttpCode(HttpStatus.OK)
  @ApiResponse({ status: 200, description: 'Session ended' })
  @ApiResponse({ status: 404, description: 'Session not found' })
  endSession(@Param('id') id: string) {
    return this.sessionService.endSession(id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiResponse({ status: 204, description: 'Session deleted' })
  @ApiResponse({ status: 404, description: 'Session not found' })
  remove(@Param('id') id: string) {
    return this.sessionService.remove(id);
  }
}
