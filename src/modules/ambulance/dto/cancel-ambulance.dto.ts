import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class CancelAmbulanceDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  reasonCode: string;

  @ApiProperty({ required: false })
  @IsString()
  reasonText?: string;
}
