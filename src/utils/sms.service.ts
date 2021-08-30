import { Logger } from "@nestjs/common";

export class SMSService {

    public static sendSMS(phoneNumber: string, message: string) {
        try {   
            const israelPhoneNumber = "+972" + phoneNumber.substring(1);
            const accountSid = process.env.TWILIO_ACCOUNT_SID;
            const authToken = process.env.TWILIO_AUTH_TOKEN;
            const client = require('twilio')(accountSid, authToken);


            client.messages
                .create({
                    body: message,
                    from: '+13522616895',
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