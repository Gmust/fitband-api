import { Module } from '@nestjs/common';
import { PrismaService } from './datasource/Prisma.Service';

@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class CommonModule {}
