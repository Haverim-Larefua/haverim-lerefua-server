DROP DATABASE IF EXISTS `refua_delivery`;

CREATE DATABASE IF NOT EXISTS `refua_delivery` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
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
  `refresh_token` varchar(300) DEFAULT NULL,
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
  `city` varchar(50) DEFAULT NULL,
  `address` varchar(100) DEFAULT NULL,
  `phone` varchar(100) DEFAULT NULL,
  `customer_name` varchar(45) DEFAULT NULL,
  `currentUserId` int(11) DEFAULT NULL,
  `parcelTrackingStatus` varchar(30) DEFAULT NULL,
  `comments` varchar(100) DEFAULT NULL,
  `lastUpdateDate` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `signature` text DEFAULT NULL,
  `deleted` boolean DEFAULT false,
  `exception` boolean DEFAULT false,
  PRIMARY KEY (`id`),
  KEY `parcel_user_fk_idx` (`currentUserId`),
  CONSTRAINT `parcel_user_fk` FOREIGN KEY (`currentUserId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS `parcel_tracking`;
CREATE TABLE `parcel_tracking` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `status_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
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

DROP procedure IF EXISTS `calculateExpiredParcelsSP`;
DELIMITER $$
USE `refua_delivery`$$
CREATE PROCEDURE `calculateExpiredParcelsSP` ()
BEGIN
	DROP TABLE IF EXISTS _temp_exception_ids;
	CREATE TEMPORARY TABLE _temp_exception_ids(id int, currentUserId int, parcelTrackingStatus VARCHAR(30));

	INSERT INTO _temp_exception_ids
	SELECT id, currentUserId, parcelTrackingStatus
	FROM refua_delivery.parcel
	WHERE 
	(parcelTrackingStatus = 'ready' AND TIMESTAMPDIFF(HOUR,lastUpdateDate, CURRENT_TIMESTAMP) > 12)
	OR
    (parcelTrackingStatus = 'assigned' AND TIMESTAMPDIFF(HOUR,lastUpdateDate, CURRENT_TIMESTAMP) > 12)
    OR
	(parcelTrackingStatus = 'distribution' AND TIMESTAMPDIFF(HOUR,lastUpdateDate, CURRENT_TIMESTAMP) > 6);

	UPDATE parcel SET lastUpdateDate = CURRENT_TIMESTAMP, exception = 1
	WHERE id IN (SELECT id from _temp_exception_ids);

	INSERT INTO parcel_tracking (status_date, status, user_fk, parcel_fk, comments)
	SELECT CURRENT_TIMESTAMP, parcelTrackingStatus, currentUserId, id, "החבילה בחריגה"
	FROM _temp_exception_ids;

	DROP TABLE _temp_exception_ids;
END$$
DELIMITER ;

DROP EVENT IF EXISTS calculateExpiredParcelsEvent;
CREATE EVENT calculateExpiredParcelsEvent
# Run every 5 minutes
ON SCHEDULE EVERY 5 MINUTE
STARTS (TIMESTAMP(CURRENT_TIME))
DO CALL calculateExpiredParcelsSP;

INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `delivery_area`, `delivery_days`, `phone`, `notes`, `username`, `password`, `salt`, `active`) VALUES ('כהן', 'יוסי', 'באר שבע', '1,2,5', '052-1234567', 'יכול בשעות הערב בלבד', 'rozman', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f', 1);
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `delivery_area`, `delivery_days`, `phone`, `notes`, `username`, `password`, `salt`, `active`) VALUES ('לוי', 'יהודית', 'תל אביב', '4,5', '05201233445', 'מגיעה במונית', 'meirav', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f', 1);
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `delivery_area`, `delivery_days`, `phone`, `notes`, `username`, `password`, `salt`, `active`) VALUES ('כהנוב', 'בת-אל', 'הרצלייה', '3,4', '050-9235656', 'יכול בערב בלבד', 'harduf', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f', 1);
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `delivery_area`, `delivery_days`, `phone`, `notes`, `username`, `password`, `salt`, `active`) VALUES ('יהודה', 'שלום', 'חיפה', '2,3', '054-1888865', '', 'shalom1', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f', 1);
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `delivery_area`, `delivery_days`, `phone`, `notes`, `username`, `password`, `salt`, `active`) VALUES ('עברי', 'אהרון', 'עכו', '1,3', '056-1234564', 'יכול בשעות הבוקר בלבד', 'shalom', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f', 0);
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `delivery_area`, `delivery_days`, `phone`, `notes`, `username`, `password`, `salt`, `active`) VALUES ('ציפי', 'בראל', 'גדרה', '2,4', '055-1244667', 'פוחדת מכלבים', 'zipi', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f', 1);
INSERT INTO `refua_delivery`.`users` (`first_name`, `last_name`, `delivery_area`, `delivery_days`, `phone`, `notes`, `username`, `password`, `salt`, `active`) VALUES ('ישראל', 'דוד', 'חולון', '2,3', '053-8872345', 'בשעות הערב בלבד', 'eliyahoo', 'd129f44c69f2964cb3768f77af4fac2b95c27183ddc0f36bd76db37cb340f337f8879a588141da6cd79176be6c535aedfa48bf809f7c29229c6033d32ddf4d74', 'b64b7196d89c2f8f', 1);

INSERT INTO `refua_delivery`.`admins` (`first_name`, `last_name`, `username`, `password`, `salt`) VALUES ('admin', 'admin', 'admin', 'cb9af5d9bb030cd8dc49726670f42401c5b13f2e89d92ca465634e948bbe3c97fd605fc59d4d8df50a427e35166ad3fea241e6ab7b21ed2347e536b96f9e3148', 'd047a22b76dd833f');


INSERT INTO `refua_delivery`.`parcel` (`city`, `phone`, `customer_name`, `address`, `currentUserId`, `parcelTrackingStatus`, `comments`, `lastUpdateDate`, `signature`, `deleted`) VALUES ('תל אביב', '052-8556645', 'ישראל ישראלי', 'באר שבע, שטרן 20 א', 14, 'delivered', 'אין הערות', '2020-02-01 08:00:00', 'some base 64 signature', 0);
INSERT INTO `refua_delivery`.`parcel` (`city`, `phone`, `customer_name`, `address`, `currentUserId`, `parcelTrackingStatus`, `comments`, `lastUpdateDate`, `signature`, `deleted`) VALUES ('באר שבע', '052-1234567', 'יהודית ירושלמי', 'באר שבע, שיכון ד', 14, 'assigned', 'אין הערות', '2020-02-02 08:00:00', 'some base 64 signature', 0);
INSERT INTO `refua_delivery`.`parcel` (`city`, `phone`, `customer_name`, `address`, `currentUserId`, `parcelTrackingStatus`, `comments`, `lastUpdateDate`, `signature`, `deleted`) VALUES ('באר שבע', '052-1234567', 'ימשה משה', 'באר שבע, שיכון ד', null , 'ready', 'אין הערות', '2020-02-02 08:00:00', 'some base 64 signature', 0);

INSERT INTO `refua_delivery`.`parcel_tracking` (`status_date`, `status`, `user_fk`, `parcel_fk`) VALUES ('2020-02-01 08:00:00', 'delivered', 14, 1);
INSERT INTO `refua_delivery`.`parcel_tracking` (`status_date`, `status`, `user_fk`, `parcel_fk`) VALUES ('2020-02-01 08:00:00', 'assigned', 14, 2);

INSERT INTO `refua_delivery`.`push_token` (`id`, `user_fk`, `token`) VALUES (1, 14, 'some phone token');
INSERT INTO `refua_delivery`.`push_token` (`id`, `user_fk`, `token`) VALUES (2, 15, 'some phone token');


ALTER TABLE `refua_delivery`.`parcel` 
ADD COLUMN `start_date` date NULL DEFAULT NULL AFTER `comments`,
ADD COLUMN `start_time` time NULL DEFAULT NULL AFTER `start_date`;


ALTER TABLE `refua_delivery`.`parcel` 
ADD COLUMN `customer_id` VARCHAR(9) NULL DEFAULT NULL AFTER `customer_name`;

ALTER TABLE `refua_delivery`.`users` 
ADD FULLTEXT INDEX `search_fulltext` (`first_name`, `last_name`, `phone`) WITH PARSER ngram VISIBLE;
;

ALTER TABLE `refua_delivery`.`parcel` 
ADD FULLTEXT INDEX `search_fulltext` (`phone`, `customer_name`, `customer_id`) WITH PARSER ngram VISIBLE;
;
