import { Controller, Post, Res, HttpStatus, Body } from '@nestjs/common';
import { Response } from 'express';
import { PushService } from './push.service';

export interface SubsciprtionData {
  id: number;
  subscription: PushSubscription;
  fingerprint: number;
}

@Controller('push')
export class PushController {
  constructor(private readonly pushService: PushService) {}

  private isValidSubscriptionRequest(
    subscriptionData: SubsciprtionData,
  ): boolean {
    // Check the request body has at least an endpoint
    return (
      subscriptionData.subscription &&
      subscriptionData.subscription.endpoint !== '' &&
      subscriptionData.subscription.endpoint !== null &&
      subscriptionData.subscription.endpoint !== undefined
    );
  }

  @Post('/notify')
  Notify(@Body() subscriptionData: SubsciprtionData, @Res() res: Response) {
    console.log(subscriptionData);
    if (this.isValidSubscriptionRequest(subscriptionData)) {
      try {
        this.pushService.sendNotification(
          subscriptionData.id,
          subscriptionData.subscription,
          subscriptionData.fingerprint,
        );
        res.status(HttpStatus.OK).send();
      } catch (error) {
        res.status(HttpStatus.INTERNAL_SERVER_ERROR);
        res.setHeader('Content-Type', 'application/json');
        res.send(
          JSON.stringify({
            error: {
              id: 'unable-to-notify',
              message:
                'The notification request was received but we were unable to execute.',
            },
          }),
        );
      }
    } else {
      res.status(400);
      res.setHeader('Content-Type', 'application/json');
      res.send(
        JSON.stringify({
          error: {
            id: 'no-endpoint',
            message: 'Subscription must have an endpoint.',
          },
        }),
      );
    }
  }

  // the browser will send an HTTP request to this endpoint
  @Post('subscribe')
  Subscribe(@Body() subscriptionData: SubsciprtionData, @Res() res: Response) {
    console.log(subscriptionData);
    if (this.isValidSubscriptionRequest(subscriptionData)) {
      try {
        this.pushService.subscribe(
          subscriptionData.id,
          subscriptionData.subscription,
          subscriptionData.fingerprint,
        );
        res.status(HttpStatus.CREATED).send();
      } catch (error) {
        res.status(HttpStatus.INTERNAL_SERVER_ERROR);
        res.setHeader('Content-Type', 'application/json');
        res.send(
          JSON.stringify({
            error: {
              id: 'unable-to-save-subscription',
              message:
                'The subscription was received but we were unable to save it to our database.',
            },
          }),
        );
      }
    } else {
      res.status(400);
      res.setHeader('Content-Type', 'application/json');
      res.send(
        JSON.stringify({
          error: {
            id: 'no-endpoint',
            message: 'Subscription must have an endpoint.',
          },
        }),
      );
    }
  }
}
