import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/datasource/Prisma.Service';
import { CreateDeviceDto } from './dto/create-device.dto';
import { UpdateDeviceDto } from './dto/update-device.dto';

@Injectable()
export class DeviceService {
  constructor(private prisma: PrismaService) {}

  // Devices are now created automatically during user registration
  // This method is kept for potential future use but should not be called directly
  async create(createDeviceDto: CreateDeviceDto) {
    throw new Error('Devices must be created through user registration');
  }

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
    try {
      return await this.prisma.device.update({
        where: { id },
        data: updateDeviceDto,
      });
    } catch (error) {
      if (error.code === 'P2025') {
        throw new NotFoundException(`Device with ID ${id} not found`);
      }
      throw error;
    }
  }

  async remove(id: string) {
    try {
      return await this.prisma.device.delete({
        where: { id },
      });
    } catch (error) {
      if (error.code === 'P2025') {
        throw new NotFoundException(`Device with ID ${id} not found`);
      }
      throw error;
    }
  }
}
