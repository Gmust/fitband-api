import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { CommonModule } from './common/common.module';
import { DeviceModule } from './device/device.module';
import { TelemetryModule } from './telemetry/telemetry.module';
import { AuthModule } from './auth/auth.module';

@Module({
  imports: [CommonModule, DeviceModule, TelemetryModule, AuthModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
