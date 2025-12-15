import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import helmet from 'helmet';
import { json, urlencoded } from 'express';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { BigIntSerializerInterceptor } from './common/interceptors/bigint-serializer.interceptor';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.use(
    helmet({
      contentSecurityPolicy:
        process.env.NODE_ENV === 'production' ? undefined : false,
    }),
  );
  app.enableCors({
    origin: (process.env.CORS_ORIGIN ?? '')
      .split(',')
      .map((origin) => origin.trim()),
  });

  app.use(
    json({
      limit: '512kb',
      verify: (req: any, _res, buf) => {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        req.rawBody = buf.toString('utf-8') ?? '';
      },
    }),
  );
  app.use(urlencoded({ extended: true, limit: '256kb' }));

  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: false,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  app.useGlobalInterceptors(new BigIntSerializerInterceptor());

  //TODO: Add throttler guard
  // app.useGlobalGuards(
  //   new ThrottlerGuard(
  //     app.get(Reflector),
  //     {},
  //     {
  //       ignoreUserAgents: [/postman/i, /insomnia/i, /swagger/i],
  //     },
  //   ),
  // );

  const config = new DocumentBuilder()
    .setTitle('Mock Fitband API')
    .setDescription(
      'REST API for mock fitness band devices. Handles user authentication and device management. Real-time telemetry streaming via WebSocket bridge.',
    )
    .setVersion('1.0.0')
    .addTag('Authentication', 'User authentication and registration')
    .addTag('Devices', 'Device management endpoints (1 device per user)')
    .addTag('Telemetry', 'Telemetry data storage (optional)')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Enter JWT token',
      },
      'JWT-auth',
    )
    .addApiKey(
      {
        type: 'apiKey',
        in: 'header',
        name: 'X-API-KEY',
        description: 'API Key for the API',
      },
      'ApiKeyAuth',
    )
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document, {
    jsonDocumentUrl: 'swagger-json',
    customSiteTitle: 'Mock Fitband API',
    customJs: [],
    swaggerOptions: {
      persistAuthorization: true,
      // Ensure Swagger uses the same protocol as the request
      urls: [
        {
          url: 'swagger-json',
          name: 'Default',
        },
      ],
    },
  });

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
