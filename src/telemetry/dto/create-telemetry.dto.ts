import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  IsNumber,
  IsDateString,
  Min,
  Max,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class CreateTelemetryDto {
  @ApiProperty({
    description: 'Device ID',
    example: 'device-123',
  })
  @IsUUID()
  @IsNotEmpty()
  deviceId: string;

  @ApiProperty({
    description: 'Session ID (optional)',
    example: 'session-456',
    required: false,
  })
  @IsUUID()
  @IsOptional()
  sessionId?: string;

  @ApiProperty({
    description: 'Device timestamp (ISO 8601)',
    example: '2025-12-03T21:00:00Z',
  })
  @IsDateString()
  @IsNotEmpty()
  tsDevice: string;

  @ApiProperty({
    description: 'Heart rate in BPM',
    example: 75,
    minimum: 0,
    maximum: 255,
    required: false,
  })
  @IsNumber()
  @IsOptional()
  @Min(0)
  @Max(255)
  heartRate?: number;

  @ApiProperty({
    description: 'Steps since last telemetry',
    example: 120,
    minimum: 0,
    required: false,
  })
  @IsNumber()
  @IsOptional()
  @Min(0)
  stepsDelta?: number;

  @ApiProperty({
    description: 'Calories burned since last telemetry',
    example: 15.5,
    required: false,
  })
  @Transform(({ value }) => parseFloat(value))
  @IsNumber()
  @IsOptional()
  caloriesDelta?: number;

  @ApiProperty({
    description: 'Battery level (0-100%)',
    example: 85.5,
    minimum: 0,
    maximum: 100,
    required: false,
  })
  @Transform(({ value }) => parseFloat(value))
  @IsNumber()
  @IsOptional()
  @Min(0)
  @Max(100)
  battery?: number;

  @ApiProperty({
    description: 'Accelerometer X-axis',
    example: 0.123,
    required: false,
  })
  @Transform(({ value }) => parseFloat(value))
  @IsNumber()
  @IsOptional()
  ax?: number;

  @ApiProperty({
    description: 'Accelerometer Y-axis',
    example: -0.456,
    required: false,
  })
  @Transform(({ value }) => parseFloat(value))
  @IsNumber()
  @IsOptional()
  ay?: number;

  @ApiProperty({
    description: 'Accelerometer Z-axis',
    example: 9.81,
    required: false,
  })
  @Transform(({ value }) => parseFloat(value))
  @IsNumber()
  @IsOptional()
  az?: number;

  @ApiProperty({
    description: 'Message ID for idempotency',
    example: 'msg-789',
    required: false,
  })
  @IsString()
  @IsOptional()
  messageId?: string;
}
