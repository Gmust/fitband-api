import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../common/datasource/Prisma.Service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  async register(registerDto: RegisterDto) {
    const { deviceId, email, password, name } = registerDto;

    // Check if user already exists
    const existingUser = await this.prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      throw new UnauthorizedException('User already exists');
    }

    // Check if device already exists
    const existingDevice = await this.prisma.device.findUnique({
      where: { id: deviceId },
    });

    if (existingDevice) {
      throw new UnauthorizedException('Device already exists');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user and device in a transaction
    const result = await this.prisma.$transaction(async (prisma) => {
      // Create user first
      const user = await prisma.user.create({
        data: {
          email,
          password: hashedPassword,
          name,
          deviceId, // This will be the Device's id
        },
      });

      // Create device with userId
      const device = await prisma.device.create({
        data: {
          id: deviceId,
          name: `${name}'s Device`,
          secret: this.generateSecret(),
          userId: user.id,
        },
      });

      return { user, device };
    });

    // Generate JWT token
    const payload = { email: result.user.email, sub: result.user.id, deviceId: result.user.deviceId };
    const token = this.jwtService.sign(payload);

    return {
      access_token: token,
      user: {
        id: result.user.id,
        email: result.user.email,
        name: result.user.name,
        deviceId: result.user.deviceId,
      },
    };
  }

  async login(loginDto: LoginDto) {
    const { deviceId, name, email, password } = loginDto;

    // Find user by email
    const user = await this.prisma.user.findUnique({
      where: { email },
      include: { device: true },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Validate deviceId and name match
    if (user.deviceId !== deviceId || user.name !== name) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Generate JWT token
    const payload = { email: user.email, sub: user.id, deviceId: user.deviceId };
    const token = this.jwtService.sign(payload);

    return {
      access_token: token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        deviceId: user.deviceId,
      },
    };
  }

  async validateUser(userId: string) {
    return this.prisma.user.findUnique({
      where: { id: userId },
      include: { device: true },
    });
  }

  private generateSecret(): string {
    return require('crypto').randomBytes(32).toString('hex');
  }
}
