import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

const webpush = require('web-push');

@Injectable()
export class PushService {
  private vapidDetails;

  constructor(private readonly configService: ConfigService) {
    const publicVapidKey = "BJthRQ5myDgc7OSXzPCMftGw-n16F7zQBEN7EUD6XxcfTTvrLGWSIG7y_JxiWtVlCFua0S8MTB5rPziBqNx1qIo";
    const privateVapidKey = "3KzvKasA2SoCxsp0iIG_o9B0Ozvl1XDwI63JRKNIWBM";

    const myPubKey = "BIi1dlfrHoeGTnz8dwtp7UoVKJWNZ4oaymf3ssukatxrL_Tx5h1lOmqM3W9bueFqsYj0kmIiW6Y0-5opsoRIt3k";
    const myPrivKey ="RbHUlJubWXi9rEnU9NpzXyZ86vP0OcHB1OHzCEUy3lc";
  
    this.vapidDetails = {
      subject:
        this.configService.get<string>('SUBJECT_MAIL') ||
        'mailto:as167f@intl.att.com',
      publicKey:
        this.configService.get<string>('PUBLIC_VAPID_KEY') || myPubKey,
      privateKey:
        this.configService.get<string>('PRIVATE_VAPID_KEY') || myPrivKey,
    };
    this.init();
  }

  private init() {
    console.log('[init] PushService', this.vapidDetails);
    
    // the below should be called only once !!! - already done with web-push CLI
    // const vapidKeys = webpush.generateVAPIDKeys(); 
    
    webpush.setVapidDetails(
      this.vapidDetails.subject,
      this.vapidDetails.publicKey,
      this.vapidDetails.privateKey,
    );
  }

  public sendNotification(id: number, subscription: PushSubscription, clientFingerprint: number) {
    console.log('[sendNotification] with subscription: ', subscription);

    const payload = JSON.stringify({ title: 'Push Test' });
    webpush.sendNotification(subscription, payload)
      .then((status) => {
        console.log('[sendNotification] returned with status: ', status);
      })
      .catch(error => {
        console.error('[sendNotification] returned with error:', error.stack);
      });
  }

  subscribe(id: number, subscription: PushSubscription, clientFingerprint: number) {
    //TODO: saveSubscriptionToDatabase(id, subscription, clientFingerprint);
    console.log('[subscribe] with id: ', id, '  subscription: ', subscription, '  clientDingerprint: ', clientFingerprint);
  }
  
}
