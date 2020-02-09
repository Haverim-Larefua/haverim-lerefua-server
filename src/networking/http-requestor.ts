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

        try {
            axios(httpRequestOptions)
                .then((response) => {
                    Logger.debug(`sendHttpRequest:: response.data: ${response.data}`);
                    resolve(response.data);
                }).catch((error) => {
                    reject(error);
                });
        } catch (e) {
            Logger.error('sendHttpRequest:: error: ', e);
        }
    });
};
