import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/datasource/Prisma.Service';
import { CreateSessionDto } from './dto/create-session.dto';
import { UpdateSessionDto } from './dto/update-session.dto';

@Injectable()
export class SessionService {
  constructor(private prisma: PrismaService) {}

  async create(createSessionDto: CreateSessionDto) {
    // Verify device exists
    const device = await this.prisma.device.findUnique({
      where: { id: createSessionDto.deviceId },
    });

    if (!device) {
      throw new NotFoundException(`Device with ID ${createSessionDto.deviceId} not found`);
    }

    return this.prisma.session.create({
      data: createSessionDto,
      include: {
        device: true,
        telemetry: true,
      },
    });
  }

  async findAll() {
    return this.prisma.session.findMany({
      include: {
        device: true,
        telemetry: true,
      },
      orderBy: {
        startedAt: 'desc',
      },
    });
  }

  async findOne(id: string) {
    const session = await this.prisma.session.findUnique({
      where: { id },
      include: {
        device: true,
        telemetry: true,
      },
    });

    if (!session) {
      throw new NotFoundException(`Session with ID ${id} not found`);
    }

    return session;
  }

  async findByDevice(deviceId: string) {
    return this.prisma.session.findMany({
      where: { deviceId },
      include: {
        device: true,
        telemetry: true,
      },
      orderBy: {
        startedAt: 'desc',
      },
    });
  }

  async findActiveByDevice(deviceId: string) {
    return this.prisma.session.findFirst({
      where: {
        deviceId,
        endedAt: null,
      },
      include: {
        device: true,
        telemetry: true,
      },
    });
  }

  async update(id: string, updateSessionDto: UpdateSessionDto) {
    try {
      return await this.prisma.session.update({
        where: { id },
        data: updateSessionDto,
        include: {
          device: true,
          telemetry: true,
        },
      });
    } catch (error) {
      if (error.code === 'P2025') {
        throw new NotFoundException(`Session with ID ${id} not found`);
      }
      throw error;
    }
  }

  async endSession(id: string) {
    try {
      return await this.prisma.session.update({
        where: { id },
        data: {
          endedAt: new Date(),
        },
        include: {
          device: true,
          telemetry: true,
        },
      });
    } catch (error) {
      if (error.code === 'P2025') {
        throw new NotFoundException(`Session with ID ${id} not found`);
      }
      throw error;
    }
  }

  async remove(id: string) {
    try {
      return await this.prisma.session.delete({
        where: { id },
      });
    } catch (error) {
      if (error.code === 'P2025') {
        throw new NotFoundException(`Session with ID ${id} not found`);
      }
      throw error;
    }
  }
}
