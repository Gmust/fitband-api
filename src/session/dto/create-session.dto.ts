import { IsNotEmpty, IsOptional, IsString, IsUUID } from 'class-validator';

export class CreateSessionDto {
  @IsUUID()
  @IsNotEmpty()
  deviceId: string;

  @IsString()
  @IsOptional()
  notes?: string;
}
