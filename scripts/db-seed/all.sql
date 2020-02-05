CREATE DATABASE  IF NOT EXISTS `refua_delivery`;
USE `refua_delivery`;

DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `description` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `first_name` varchar(20) DEFAULT NULL,
  `last_name` varchar(30) DEFAULT NULL,
  `address` varchar(100) DEFAULT NULL,
  `delivery_area` varchar(20) DEFAULT NULL,
  `delivery_days` varchar(30) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `role_fk` int(11) DEFAULT NULL,
  `notes` varchar(100) DEFAULT NULL,
  `username` varchar(30) DEFAULT NULL,
  `password` varchar(200) DEFAULT NULL,
  `salt` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE(username),
  KEY `user_role_fk_idx` (`role_fk`),
  CONSTRAINT `user_role_fk` FOREIGN KEY (`role_fk`) REFERENCES `roles` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS `parcel`;
CREATE TABLE `parcel` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `no` int(11) DEFAULT NULL,
  `city` varchar(50) DEFAULT NULL,
  `phone` varchar(100) DEFAULT NULL,
  `customer_name` varchar(45) DEFAULT NULL,
  `address` varchar(100) DEFAULT NULL,
  `userId` int(11) DEFAULT NULL,
  `comments` varchar(100) DEFAULT NULL,
  `update_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `signature` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `parcel_user_fk_idx` (`userId`),
  CONSTRAINT `parcel_user_fk` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS `parcel_statuses`;
CREATE TABLE `parcel_statuses` (
  `id` int(2) NOT NULL,
  `status` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS `parcel_tracking`;
CREATE TABLE `parcel_tracking` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `status_date` date DEFAULT NULL,
  `comments` varchar(100) DEFAULT NULL,
  `status_fk` int(11) DEFAULT NULL,
  `parcel_fk` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `pracel_tk_status_idx` (`status_fk`),
  KEY `parcel_tacking_parcel_idx` (`parcel_fk`),
  CONSTRAINT `parcel_tacking_status` FOREIGN KEY (`status_fk`) REFERENCES `parcel_statuses` (`id`),
  CONSTRAINT `parcel_tacking_parcel` FOREIGN KEY (`parcel_fk`) REFERENCES `parcel` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS `push_token`;
CREATE TABLE `push_token` (
  `id` int(2) NOT NULL,
  `userId` int(11) DEFAULT NULL,
  `token` varchar(300) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

LOCK TABLES `parcel_tracking` WRITE;
UNLOCK TABLES;

LOCK TABLES `roles` WRITE;
UNLOCK TABLES;

LOCK TABLES `users` WRITE;
UNLOCK TABLES;

INSERT INTO `refua_delivery`.`roles` (`id`, `description`) VALUES (1, 'שליח בכיר');
INSERT INTO `refua_delivery`.`roles` (`id`, `description`) VALUES (2, 'שליח');

INSERT INTO `refua_delivery`.`parcel_statuses` (`id`, `status`) VALUES (1, 'מוכנה לחלוקה');
INSERT INTO `refua_delivery`.`parcel_statuses` (`id`, `status`) VALUES (2, 'בחלוקה');
INSERT INTO `refua_delivery`.`parcel_statuses` (`id`, `status`) VALUES (3, 'נמסרה');
INSERT INTO `refua_delivery`.`parcel_statuses` (`id`, `status`) VALUES (4, 'בחריגה');

INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `address`, `delivery_area`, `delivery_days`, `phone`, `role_fk`, `notes`, `username`, `password`, `salt`) VALUES ('אליהו', 'רוזמן', 'באר שבע', 'באר שבע', '1,2,5', '052-1234567', 1, 'יכול בשעות הערב בלבד', 'rozman', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f');
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `address`, `delivery_area`, `delivery_days`, `phone`, `role_fk`, `notes`, `username`, `password`, `salt`) VALUES ('מירב', 'בנשנישתי', 'תל אביב', 'תל אביב', '4,5', '05201233445', 2, 'מגיעה במונית', 'meirav', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f');
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `address`, `delivery_area`, `delivery_days`, `phone`, `role_fk`, `notes`, `username`, `password`, `salt`) VALUES ('יוכבד', 'הרדוף', 'הרצלייה', 'הרצלייה', '3,4', '050-9235656', 1, 'יכול בערב בלבד', 'harduf', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f');
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `address`, `delivery_area`, `delivery_days`, `phone`, `role_fk`, `notes`, `username`, `password`, `salt`) VALUES ('אליהו', 'שלום', 'חיפה', 'חיפה', '2,3', '054-1888865', 2, '', 'shalom1', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f');
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `address`, `delivery_area`, `delivery_days`, `phone`, `role_fk`, `notes`, `username`, `password`, `salt`) VALUES ('חונדישוואלי', 'שלום', 'עכו', 'עכו', '1,3', '056-1234564', 1, 'יכול בשעות הבוקר בלבד', 'shalom', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f');
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `address`, `delivery_area`, `delivery_days`, `phone`, `role_fk`, `notes`, `username`, `password`, `salt`) VALUES ('ציפי', 'מנחם', 'גדרה', 'גדרה', '2,4', '055-1244667', 1, 'פוחדת מכלבים', 'zipi', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f');
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `address`, `delivery_area`, `delivery_days`, `phone`, `role_fk`, `notes`, `username`, `password`, `salt`) VALUES ('מנחם', 'אליהו', 'חולון', 'חולון', '2,3', '053-8872345', 2, 'בשעות הערב בלבד', 'eliyahoo', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f');

INSERT INTO `refua_delivery`.`parcel` (`no`, `city`, `phone`, `customer_name`, `address`, `userId`, `comments`, `update_date`, `signature`) VALUES ('055255655', 'תל אביב', '052-8556645', 'דוד ביטון', 'באר שבע, שטרן 20 א', 14, 'אין הערות', '2020-02-01 08:00:00', 'some base 64 signature');
INSERT INTO `refua_delivery`.`parcel` (`no`, `city`, `phone`, `customer_name`, `address`, `userId`, `comments`, `update_date`, `signature`) VALUES ('022222222', 'באר שבע', '052-1234567', 'שרה נתניהו', 'באר שבע, שיכון ד', 14, 'אין הערות', '2020-02-02 08:00:00', 'some base 64 signature');

INSERT INTO `refua_delivery`.`parcel_tracking` (`status_date`, `status_fk`, `parcel_fk`) VALUES ('2020-02-01 08:00:00', 1, 6);

INSERT INTO `refua_delivery`.`push_token` (`id`, `userId`, `token`) VALUES (1, 14, 'some phone token');
INSERT INTO `refua_delivery`.`push_token` (`id`, `userId`, `token`) VALUES (2, 23, 'some phone token');
