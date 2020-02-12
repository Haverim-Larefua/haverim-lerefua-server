CREATE DATABASE  IF NOT EXISTS `refua_delivery`;
USE `refua_delivery`;

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `first_name` varchar(20) DEFAULT NULL,
  `last_name` varchar(30) DEFAULT NULL,
  `delivery_area` varchar(20) DEFAULT NULL,
  `delivery_days` varchar(30) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `notes` varchar(100) DEFAULT NULL,
  `username` varchar(30) DEFAULT NULL,
  `password` varchar(200) DEFAULT NULL,
  `salt` varchar(30) DEFAULT NULL,
  `active` boolean DEFAULT false,
  PRIMARY KEY (`id`),
  UNIQUE(username)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS `admins`;
CREATE TABLE `admins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `first_name` varchar(20) DEFAULT NULL,
  `last_name` varchar(30) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `username` varchar(30) DEFAULT NULL,
  `password` varchar(200) DEFAULT NULL,
  `salt` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE(username)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS `parcel`;
CREATE TABLE `parcel` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identity` int(11) DEFAULT NULL,
  `city` varchar(50) DEFAULT NULL,
  `address` varchar(100) DEFAULT NULL,
  `phone` varchar(100) DEFAULT NULL,
  `customer_name` varchar(45) DEFAULT NULL,
  `currentUserId` int(11) DEFAULT NULL,
  `parcelTrackingStatus` varchar(30) DEFAULT NULL,
  `comments` varchar(100) DEFAULT NULL,
  `lastUpdateDate` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `signature` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `parcel_user_fk_idx` (`currentUserId`),
  CONSTRAINT `parcel_user_fk` FOREIGN KEY (`currentUserId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS `parcel_tracking`;
CREATE TABLE `parcel_tracking` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `status_date` date DEFAULT NULL,
  `status` varchar(30) DEFAULT NULL,
  `user_fk` int(11) DEFAULT NULL,
  `parcel_fk` int(11) DEFAULT NULL,
  `comments` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `parcel_tacking_parcel_idx` (`parcel_fk`),
  CONSTRAINT `parcel_tacking_parcel` FOREIGN KEY (`parcel_fk`) REFERENCES `parcel` (`id`),
  CONSTRAINT `parcel_tacking_user` FOREIGN KEY (`user_fk`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS `push_token`;
CREATE TABLE `push_token` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_fk` int(11) DEFAULT NULL,
  `token` varchar(300) DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `push_token_user` FOREIGN KEY (`user_fk`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `delivery_area`, `delivery_days`, `phone`, `notes`, `username`, `password`, `salt`, `active`) VALUES ('אליהו', 'רוזמן', 'באר שבע', '1,2,5', '052-1234567', 'יכול בשעות הערב בלבד', 'rozman', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f', 1);
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `delivery_area`, `delivery_days`, `phone`, `notes`, `username`, `password`, `salt`, `active`) VALUES ('מירב', 'בנשנישתי', 'תל אביב', '4,5', '05201233445', 'מגיעה במונית', 'meirav', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f', 1);
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `delivery_area`, `delivery_days`, `phone`, `notes`, `username`, `password`, `salt`, `active`) VALUES ('יוכבד', 'הרדוף', 'הרצלייה', '3,4', '050-9235656', 'יכול בערב בלבד', 'harduf', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f', 1);
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `delivery_area`, `delivery_days`, `phone`, `notes`, `username`, `password`, `salt`, `active`) VALUES ('אליהו', 'שלום', 'חיפה', '2,3', '054-1888865', '', 'shalom1', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f', 1);
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `delivery_area`, `delivery_days`, `phone`, `notes`, `username`, `password`, `salt`, `active`) VALUES ('חונדישוואלי', 'שלום', 'עכו', '1,3', '056-1234564', 'יכול בשעות הבוקר בלבד', 'shalom', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f', 0);
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `delivery_area`, `delivery_days`, `phone`, `notes`, `username`, `password`, `salt`, `active`) VALUES ('ציפי', 'מנחם', 'גדרה', '2,4', '055-1244667', 'פוחדת מכלבים', 'zipi', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f', 1);
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `delivery_area`, `delivery_days`, `phone`, `notes`, `username`, `password`, `salt`, `active`) VALUES ('מנחם', 'אליהו', 'חולון', '2,3', '053-8872345', 'בשעות הערב בלבד', 'eliyahoo', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f', 1);

INSERT INTO `refua_delivery`.`admins` (`first_name`, `last_name`, `phone`, `username`, `password`, `salt`) VALUES ('בנימין', 'נתניהו', '052-1234567', 'bibi', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f');
INSERT INTO `refua_delivery`.`admins` (`first_name`, `last_name`, `phone`, `username`, `password`, `salt`) VALUES ('בני', 'גנץ', '05201233445', 'benny', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f');
INSERT INTO `refua_delivery`.`admins` (`first_name`, `last_name`, `phone`, `username`, `password`, `salt`) VALUES ('admin', 'admin', '052-12345678', 'admin', 'cbf691a3146f3b1b5521a8f40e77a9dc164db257476195c1f580428ff4d743bb103317003ea2d3fea1c048d5b82e2305a7b22cec12c9b83014944e943879d118', '0cdbbce7fef922c2');
INSERT INTO `refua_delivery`.`admins` (`first_name`, `last_name`, `phone`, `username`, `password`, `salt`) VALUES ('root', 'root', '052-87654321', 'root', 'ed6ffbb44d26b46df658ed44a1611083bfa7b2e35d4bd95ed5b862581db62aa843673233ae3410a9365ede6c828f56b00e2e5f02fa5e6cd20aaaba327d2b8228', '87b32ce958994e89');

INSERT INTO `refua_delivery`.`parcel` (`identity`, `city`, `phone`, `customer_name`, `address`, `currentUserId`, `parcelTrackingStatus`, `comments`, `lastUpdateDate`, `signature`) VALUES ('055255655', 'תל אביב', '052-8556645', 'דוד ביטון', 'באר שבע, שטרן 20 א', 14, 'delivered', 'אין הערות', '2020-02-01 08:00:00', 'some base 64 signature');
INSERT INTO `refua_delivery`.`parcel` (`identity`, `city`, `phone`, `customer_name`, `address`, `currentUserId`, `parcelTrackingStatus`, `comments`, `lastUpdateDate`, `signature`) VALUES ('022222222', 'באר שבע', '052-1234567', 'שרה נתניהו', 'באר שבע, שיכון ד', 14, 'ready', 'אין הערות', '2020-02-02 08:00:00', 'some base 64 signature');

INSERT INTO `refua_delivery`.`parcel_tracking` (`status_date`, `status`, `user_fk`, `parcel_fk`) VALUES ('2020-02-01 08:00:00', 'delivered', 14, 6);

INSERT INTO `refua_delivery`.`push_token` (`id`, `user_fk`, `token`) VALUES (1, 14, 'some phone token');
INSERT INTO `refua_delivery`.`push_token` (`id`, `user_fk`, `token`) VALUES (2, 15, 'some phone token');
