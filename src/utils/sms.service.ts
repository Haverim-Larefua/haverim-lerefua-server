import { Logger } from "@nestjs/common";

export class SMSService {

    private static readonly TWILLO_PHONE_NUMBER = '+14133596949';

    public static sendSMS(phoneNumber: string, message: string) {
        try {   
            const israelPhoneNumber = "+972" + phoneNumber.substring(1);
            const accountSid = process.env.TWILIO_ACCOUNT_SID;
            const authToken = process.env.TWILIO_AUTH_TOKEN;
            const client = require('twilio')(accountSid, authToken);


            client.messages
                .create({
                    body: message,
                    from: SMSService.TWILLO_PHONE_NUMBER,
                    to: israelPhoneNumber
                })
                .then(message => console.log(message.sid))
                .done();

            Logger.warn(message);
        } catch (ex) {
            Logger.warn(`error send SMS to ${phoneNumber}, error:${ex.message}`)
        }
    }
}