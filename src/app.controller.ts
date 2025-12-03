import { ApiResponse } from '@nestjs/swagger';
import { Controller, Get, Post, Body } from '@nestjs/common';
import { AppService } from './app.service';
import { PrismaService } from './common/datasource/Prisma.Service';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly prisma: PrismaService,
  ) {}

  @Get()
  @ApiResponse({ status: 200, description: 'Hello message' })
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('health')
  @ApiResponse({ status: 200, description: 'Health check status' })
  async getHealth() {
    let dbStatus = 'unknown';
    let dbLatency: number | null = null;

    try {
      const startTime = Date.now();
      await this.prisma.$queryRaw`SELECT 1`;
      dbLatency = Date.now() - startTime;
      dbStatus = 'connected';
    } catch {
      dbStatus = 'disconnected';
    }

    return {
      status: dbStatus === 'connected' ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'development',
      version: process.env.npm_package_version || '1.0.0',
      database: {
        status: dbStatus,
        latency: dbLatency,
      },
    };
  }

  @Get('test/db')
  async testDbRead() {
    try {
      const startTime = Date.now();

      // Test reading devices from database
      const devices = await this.prisma.device.findMany({
        take: 10,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          name: true,
          createdAt: true,
          _count: {
            select: {
              telemetry: true,
              sessions: true,
            },
          },
        },
      });

      const latency = Date.now() - startTime;

      return {
        success: true,
        message: 'Database read test successful',
        latency: `${latency}ms`,
        timestamp: new Date().toISOString(),
        data: {
          deviceCount: devices.length,
          devices: devices,
        },
      };
    } catch (error) {
      return {
        success: false,
        message: 'Database read test failed',
        error: error instanceof Error ? error.message : 'Unknown error',
        timestamp: new Date().toISOString(),
      };
    }
  }

  @Post('test/db')
  async testDbWrite(@Body() body?: { name?: string; secret?: string }) {
    try {
      const startTime = Date.now();

      // Test writing a device to database
      const testDevice = await this.prisma.device.create({
        data: {
          name: body?.name || `Test Device ${Date.now()}`,
          secret:
            body?.secret ||
            `test-secret-${Math.random().toString(36).substring(7)}`,
        },
        select: {
          id: true,
          name: true,
          createdAt: true,
        },
      });

      const latency = Date.now() - startTime;

      return {
        success: true,
        message: 'Database write test successful',
        latency: `${latency}ms`,
        timestamp: new Date().toISOString(),
        data: {
          device: testDevice,
        },
      };
    } catch (error) {
      return {
        success: false,
        message: 'Database write test failed',
        error: error instanceof Error ? error.message : 'Unknown error',
        timestamp: new Date().toISOString(),
      };
    }
  }
}
