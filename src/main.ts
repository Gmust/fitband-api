import { NestFactory, Reflector } from '@nestjs/core';
import { AppModule } from './app.module';
import helmet from 'helmet';
import { json, urlencoded } from 'express';
import { ValidationPipe } from '@nestjs/common';
import { ThrottlerGuard } from '@nestjs/throttler';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.use(helmet());
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
    .setDescription('IOT mock fitband API')
    .setVersion('1.0.0')
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
  });

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
