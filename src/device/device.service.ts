import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/datasource/Prisma.Service';
import { UpdateDeviceDto } from './dto/update-device.dto';

@Injectable()
export class DeviceService {
  constructor(private prisma: PrismaService) {}

  async findAll() {
    return this.prisma.device.findMany({
      include: {
        sessions: true,
        telemetry: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async findOne(id: string) {
    const device = await this.prisma.device.findUnique({
      where: { id },
      include: {
        sessions: true,
        telemetry: true,
      },
    });

    if (!device) {
      throw new NotFoundException(`Device with ID ${id} not found`);
    }

    return device;
  }

  async findByUserId(userId: string) {
    const device = await this.prisma.device.findUnique({
      where: { userId },
      include: {
        sessions: true,
        telemetry: true,
      },
    });

    if (!device) {
      throw new NotFoundException(`Device for user ${userId} not found`);
    }

    return device;
  }

  async update(id: string, updateDeviceDto: UpdateDeviceDto) {
    return await this.prisma.device.update({
      where: { id },
      data: updateDeviceDto,
    });
  }

  async remove(id: string) {
    return await this.prisma.device.delete({
      where: { id },
    });
  }
}
