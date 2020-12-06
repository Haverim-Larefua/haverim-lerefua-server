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
  `customer_id` VARCHAR(9) NULL DEFAULT NULL,
  `currentUserId` int(11) DEFAULT NULL,
  `parcelTrackingStatus` varchar(30) DEFAULT NULL,
  `comments` varchar(100) DEFAULT NULL,
  `start_date` date NULL DEFAULT NULL,
  `start_time` time NULL DEFAULT NULL,
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
	CREATE TEMPORARY TABLE _temp_exception_ids(id int, currentUserId int, parcelTrackingStatus VARCHAR(30)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

	INSERT INTO _temp_exception_ids
	SELECT id, currentUserId, parcelTrackingStatus
	FROM refua_delivery.parcel
	WHERE 
  exception = 0
  AND
  (
	(parcelTrackingStatus = 'ready' AND TIMESTAMPDIFF(HOUR,lastUpdateDate, CURRENT_TIMESTAMP) > 12)
	OR
    (parcelTrackingStatus = 'assigned' AND TIMESTAMPDIFF(HOUR,lastUpdateDate, CURRENT_TIMESTAMP) > 12)
    OR
	(parcelTrackingStatus = 'distribution' AND TIMESTAMPDIFF(HOUR,lastUpdateDate, CURRENT_TIMESTAMP) > 6)
  );
	UPDATE parcel SET lastUpdateDate = CURRENT_TIMESTAMP, exception = 1
	WHERE id IN (SELECT id from _temp_exception_ids);

	INSERT INTO parcel_tracking (status_date, status, user_fk, parcel_fk, comments)
	SELECT CURRENT_TIMESTAMP, parcelTrackingStatus, currentUserId, id, 'החבילה בחריגה'
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

INSERT INTO `refua_delivery`.`admins` (`first_name`, `last_name`, `username`, `password`, `salt`) VALUES ('admin', 'admin', 'admin', 'cb9af5d9bb030cd8dc49726670f42401c5b13f2e89d92ca465634e948bbe3c97fd605fc59d4d8df50a427e35166ad3fea241e6ab7b21ed2347e536b96f9e3148', 'd047a22b76dd833f');

ALTER TABLE `refua_delivery`.`users` 
ADD FULLTEXT INDEX `search_fulltext` (`first_name`, `last_name`, `phone`) WITH PARSER ngram VISIBLE;

ALTER TABLE `refua_delivery`.`parcel` 
ADD FULLTEXT INDEX `search_fulltext` (`phone`, `customer_name`, `customer_id`) WITH PARSER ngram VISIBLE;
