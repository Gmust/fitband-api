import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { CommonModule } from './common/common.module';
import { DevicesModule } from './devices/devices.module';

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true }), CommonModule, DevicesModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
