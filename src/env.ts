export const environment = {
    SERVER: {
        PROTOCOL: process.env.SERVER_PROTOCOL || 'http',
        PORT: process.env.SERVER_PORT || 3001,
    },
    DB: {
        HOST: process.env.DB_HOST || 'localhost',
        PORT: Number(process.env.DB_PORT) || 3306,
        NAME: process.env.DB_NAME || 'refua_delivery',
        USERNAME: process.env.DB_USERNAME || 'root',
        PASSWORD: process.env.DB_PASSWORD || 'Snoopy2292',
        SYNCHRONIZE: Boolean(process.env.DB_SYNCHRONIZE) || false,
    },
    JWT_SECRET: process.env.JWT_SECRET || 'jwtsecret',
};
