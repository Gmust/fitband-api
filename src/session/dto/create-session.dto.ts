import { IsNotEmpty, IsOptional, IsString, IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateSessionDto {
  @ApiProperty({
    description: 'Device ID for the session',
    example: 'device-123',
  })
  @IsUUID()
  @IsNotEmpty()
  deviceId: string;

  @ApiProperty({
    description: 'Optional session notes',
    example: 'Morning workout session',
    required: false,
  })
  @IsString()
  @IsOptional()
  notes?: string;
}
