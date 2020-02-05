import * as crypto from 'crypto';

export interface IPassword {
    hash: string;
    salt: string;
}

/**
 * generates random string of characters i.e salt
 * @function
 * @param {number} length - Length of the random string.
 */
const genRandomString = (length: number): string => {
    return crypto.randomBytes(Math.ceil(length / 2))
        .toString('hex') /** convert to hexadecimal format */
        .slice(0, length);   /** return required number of characters */
};

/**
 * hash password with sha512.
 * @function
 * @param {string} password - List of required fields.
 * @param {string} salt - Data to be validated.
 */
export const sha512 = (password: string, salt: string): IPassword => {
    const hash = crypto.createHmac('sha512', salt); /** Hashing algorithm sha512 */
    hash.update(password);
    const value = hash.digest('hex');
    return {
        salt,
        hash: value,
    };
};

export const saltHashPassword = (userPassword: string): IPassword => {
    const salt = genRandomString(16); /** Gives us salt of length 16 */
    const passwordData = sha512(userPassword, salt);
    return {
        salt: passwordData.salt,
        hash: passwordData.hash,
    };
};
