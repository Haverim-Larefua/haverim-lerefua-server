import { Logger } from "@nestjs/common";

export class SMSService {

    public static sendSMS(phoneNumber: string, message: string) {
        try {   
            const israelPhoneNumber = "+972" + phoneNumber.substring(1);
            const accountSid = "AC4471cb836a4eeb93cfdd16a745f02d56"
            const authToken = '772186393d5e8d3be91b1624d9a6fb07';
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