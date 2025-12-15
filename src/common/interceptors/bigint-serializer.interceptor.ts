import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { map } from 'rxjs/operators';
import { Observable } from 'rxjs';

function transformBigInt(value: any): any {
  if (typeof value === 'bigint') {
    return value.toString();
  }
  if (Array.isArray(value)) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return
    return value.map((item) => transformBigInt(item));
  }
  if (typeof value === 'object' && value !== null) {
    const transformed: { [key: string]: any } = {};
    for (const key in value) {
      if (Object.prototype.hasOwnProperty.call(value, key)) {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access
        transformed[key] = transformBigInt(value[key]);
      }
    }
    return transformed;
  }
  return value;
}

@Injectable()
export class BigIntSerializerInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(map((data) => transformBigInt(data)));
  }
}
