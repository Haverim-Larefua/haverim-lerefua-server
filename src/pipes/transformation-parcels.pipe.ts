import { PipeTransform, Injectable, ArgumentMetadata } from '@nestjs/common';

@Injectable()
export class TrasformationPipeParcel implements PipeTransform {
  transform(value: any, metadata: ArgumentMetadata) {
    const ret = { ...value };
    delete ret.identity;
    return ret;
  }
}
