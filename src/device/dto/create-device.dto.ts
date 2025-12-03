import { IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateDeviceDto {
  @ApiProperty({
    description: 'Device name',
    example: 'My Fitband',
  })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({
    description: 'Device secret for HMAC signature verification',
    example: 'secret-key-123',
  })
  @IsString()
  @IsNotEmpty()
  secret: string;
}
