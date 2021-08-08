import { Logger } from "@nestjs/common";

export class SMSService {

    public static sendSMS(phoneNumber: string, message: string) {
        const accountSid = 'AC306cdcd8b576a1c245d2f0463dea7b93'; 
        const authToken = '906b9f41ad8de6cd1d06585be1c81d66'; 
        //const client = require('twilio')(accountSid, authToken); 
         
        // client.messages 
        //       .create({ 
        //          body: message,  
        //          messagingServiceSid: 'MG7e63d55ac2d6ebf739c07f884dd583b4',      
        //          to: phoneNumber 
        //        }) 
        //       .then(message => console.log(message.sid)) 
        //       .done();
        Logger.warn(message);
    }
}