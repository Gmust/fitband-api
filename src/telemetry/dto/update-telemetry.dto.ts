import { PartialType } from '@nestjs/mapped-types';
import { CreateTelemetryDto } from './create-telemetry.dto';

export class UpdateTelemetryDto extends PartialType(CreateTelemetryDto) {}
