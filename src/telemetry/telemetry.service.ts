import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/datasource/Prisma.Service';
import { CreateTelemetryDto } from './dto/create-telemetry.dto';
import { UpdateTelemetryDto } from './dto/update-telemetry.dto';

@Injectable()
export class TelemetryService {
  constructor(private prisma: PrismaService) {}

  async create(createTelemetryDto: CreateTelemetryDto) {
    // Verify device exists
    const device = await this.prisma.device.findUnique({
      where: { id: createTelemetryDto.deviceId },
    });

    if (!device) {
      throw new NotFoundException(`Device with ID ${createTelemetryDto.deviceId} not found`);
    }

    // If sessionId is provided, verify session exists and belongs to the device
    if (createTelemetryDto.sessionId) {
      const session = await this.prisma.session.findUnique({
        where: { id: createTelemetryDto.sessionId },
      });

      if (!session) {
        throw new NotFoundException(`Session with ID ${createTelemetryDto.sessionId} not found`);
      }

      if (session.deviceId !== createTelemetryDto.deviceId) {
        throw new NotFoundException(`Session ${createTelemetryDto.sessionId} does not belong to device ${createTelemetryDto.deviceId}`);
      }
    }

    // Check for idempotency if messageId is provided
    if (createTelemetryDto.messageId) {
      const existing = await this.prisma.telemetry.findUnique({
        where: {
          deviceId_messageId: {
            deviceId: createTelemetryDto.deviceId,
            messageId: createTelemetryDto.messageId,
          },
        },
      });

      if (existing) {
        return existing;
      }
    }

    return this.prisma.telemetry.create({
      data: {
        deviceId: createTelemetryDto.deviceId,
        sessionId: createTelemetryDto.sessionId,
        tsDevice: new Date(createTelemetryDto.tsDevice),
        heartRate: createTelemetryDto.heartRate,
        stepsDelta: createTelemetryDto.stepsDelta,
        caloriesDelta: createTelemetryDto.caloriesDelta,
        battery: createTelemetryDto.battery,
        ax: createTelemetryDto.ax,
        ay: createTelemetryDto.ay,
        az: createTelemetryDto.az,
        messageId: createTelemetryDto.messageId,
      },
      include: {
        device: true,
        session: true,
      },
    });
  }

  async findAll(limit?: number, offset?: number) {
    return this.prisma.telemetry.findMany({
      include: {
        device: true,
        session: true,
      },
      orderBy: {
        tsServer: 'desc',
      },
      take: limit,
      skip: offset,
    });
  }

  async findOne(id: number) {
    const telemetry = await this.prisma.telemetry.findUnique({
      where: { id },
      include: {
        device: true,
        session: true,
      },
    });

    if (!telemetry) {
      throw new NotFoundException(`Telemetry with ID ${id} not found`);
    }

    return telemetry;
  }

  async findByDevice(deviceId: string, limit?: number, offset?: number) {
    return this.prisma.telemetry.findMany({
      where: { deviceId },
      include: {
        device: true,
        session: true,
      },
      orderBy: {
        tsServer: 'desc',
      },
      take: limit,
      skip: offset,
    });
  }

  async findBySession(sessionId: string, limit?: number, offset?: number) {
    return this.prisma.telemetry.findMany({
      where: { sessionId },
      include: {
        device: true,
        session: true,
      },
      orderBy: {
        tsServer: 'desc',
      },
      take: limit,
      skip: offset,
    });
  }

  async update(id: number, updateTelemetryDto: UpdateTelemetryDto) {
    try {
      return await this.prisma.telemetry.update({
        where: { id },
        data: updateTelemetryDto,
        include: {
          device: true,
          session: true,
        },
      });
    } catch (error) {
      if (error.code === 'P2025') {
        throw new NotFoundException(`Telemetry with ID ${id} not found`);
      }
      throw error;
    }
  }

  async remove(id: number) {
    try {
      return await this.prisma.telemetry.delete({
        where: { id },
      });
    } catch (error) {
      if (error.code === 'P2025') {
        throw new NotFoundException(`Telemetry with ID ${id} not found`);
      }
      throw error;
    }
  }

  async getLatestByDevice(deviceId: string) {
    return this.prisma.telemetry.findFirst({
      where: { deviceId },
      include: {
        device: true,
        session: true,
      },
      orderBy: {
        tsServer: 'desc',
      },
    });
  }
}
