import axios, { AxiosRequestConfig } from 'axios';
import {Logger} from '@nestjs/common';

export enum HttpMethod {
    POST = 'post',
    GET = 'get',
    DELETE = 'delete',
    PUT = 'put',
}

export const sendHttpRequest = <ResponseDataType>(url: string, method: HttpMethod, headers?: any, data?: any): Promise<ResponseDataType> => {
    return new Promise<ResponseDataType>((resolve, reject) => {

        const httpRequestOptions = {
            method,
            headers,
            url,
            data,
            responseType: 'json',
        } as AxiosRequestConfig;

        Logger.debug(`[http-requester] [sendHttpRequest] ${method.toUpperCase()}: ${url}, headers: ${JSON.stringify(headers)}, data: ${JSON.stringify(data)}`);

        axios(httpRequestOptions)
            .then((response) => {
                Logger.debug(`sendHttpRequest:: response.data: ${JSON.stringify(response.data)}`);
                resolve(response.data);
            }).catch((error) => {
                reject(error);
            });

    });
};
