const ONE_HOUR = 3600;

export const environment = {
    VERSION: 'v1',
    SERVER: {
        PROTOCOL: process.env.SERVER_PROTOCOL || 'http',
        PORT: process.env.SERVER_PORT || 3001,
    },
    DB: {
        HOST: process.env.DB_HOST || 'localhost',
        PORT: Number(process.env.DB_PORT) || 3306,
        NAME: process.env.DB_NAME || 'refua_delivery',
        USERNAME: process.env.DB_USERNAME || 'root',
        PASSWORD: process.env.DB_PASSWORD || 'root',
        SYNCHRONIZE: Boolean(process.env.DB_SYNCHRONIZE) || false,
    },
    URLS: {
        PUSH_MOBILE: 'https://fcm.googleapis.com/fcm/send',
    },
    FIREBASE_API_KEY: 'AIzaSyA279IQxpFTysJAwr8rz0_KfgopeZDSjQY',
    JWT_TOKEN_SECRET: process.env.JWT_TOKEN_SECRET || 'jwtSecret',
    JWT_TOKEN_LIFE: process.env.JWT_TOKEN_LIFE || ONE_HOUR / 4,
    REFRESH_TOKEN_LIFE: process.env.REFRESH_TOKEN_LIFE || ONE_HOUR * 24 * 30,
    SWAGGER_UP: true,
};
