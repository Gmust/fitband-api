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

export class CreateTelemetryDto {
  @IsUUID()
  @IsNotEmpty()
  deviceId: string;

  @IsUUID()
  @IsOptional()
  sessionId?: string;

  @IsDateString()
  @IsNotEmpty()
  tsDevice: string;

  @IsNumber()
  @IsOptional()
  @Min(0)
  @Max(255)
  heartRate?: number;

  @IsNumber()
  @IsOptional()
  @Min(0)
  stepsDelta?: number;

  @Transform(({ value }) => parseFloat(value))
  @IsNumber()
  @IsOptional()
  caloriesDelta?: number;

  @Transform(({ value }) => parseFloat(value))
  @IsNumber()
  @IsOptional()
  @Min(0)
  @Max(100)
  battery?: number;

  @Transform(({ value }) => parseFloat(value))
  @IsNumber()
  @IsOptional()
  ax?: number;

  @Transform(({ value }) => parseFloat(value))
  @IsNumber()
  @IsOptional()
  ay?: number;

  @Transform(({ value }) => parseFloat(value))
  @IsNumber()
  @IsOptional()
  az?: number;

  @IsString()
  @IsOptional()
  messageId?: string;
}
