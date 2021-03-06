﻿DROP DATABASE IF EXISTS `refua_delivery`;

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
  `phone2` varchar(100) DEFAULT NULL,
  `customer_name` varchar(45) DEFAULT NULL,
  `customer_id` VARCHAR(9) NULL DEFAULT NULL,
  `currentUserId` int(11) DEFAULT NULL,
  `parcelTrackingStatus` varchar(30) DEFAULT NULL,
  `comments` varchar(500) DEFAULT NULL,
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

DROP TABLE IF EXISTS `district`;
CREATE TABLE `district` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS `subdistrict`;
CREATE TABLE `subdistrict` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS `cities`;
CREATE TABLE `cities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) DEFAULT NULL,
  `district_fk` int(11) DEFAULT NULL,
  `subdistrict_fk` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `district_fk_idx` (`district_fk`),
  CONSTRAINT `district_fk` FOREIGN KEY (`district_fk`) REFERENCES `district` (`id`),
  KEY `subdistrict_fk_idx` (`subdistrict_fk`),
  CONSTRAINT `subdistrict_fk` FOREIGN KEY (`subdistrict_fk`) REFERENCES `subdistrict` (`id`)
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

INSERT INTO `refua_delivery`.`district` (`id`, `name`) VALUES ('1', 'ירושלים');
INSERT INTO `refua_delivery`.`district` (`id`, `name`) VALUES ('2', 'הצפון');
INSERT INTO `refua_delivery`.`district` (`id`, `name`) VALUES ('3', 'חיפה');
INSERT INTO `refua_delivery`.`district` (`id`, `name`) VALUES ('4', 'המרכז');
INSERT INTO `refua_delivery`.`district` (`id`, `name`) VALUES ('5', 'תל אביב');
INSERT INTO `refua_delivery`.`district` (`id`, `name`) VALUES ('6', 'הדרום');
INSERT INTO `refua_delivery`.`district` (`id`, `name`) VALUES ('7', 'אזור יהודה והשומרון');

INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('11', 'ירושלים');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('21', 'צפת');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('22', 'כנרת');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('23', 'עפולה');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('24', 'עכו');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('25', 'נצרת');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('29', 'גולן');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('31', 'חיפה');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('32', 'חדרה');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('41', 'השרון');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('42', 'פתח תקווה');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('43', 'רמלה');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('44', 'רחובות');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('51', 'תל אביב');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('52', 'רמת גן');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('53', 'חולון');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('61', 'אשקלון');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('62', 'באר שבע');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('71', "ג'נין");
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('72', 'שכם');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('73', 'טול כרם');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('74', 'ראמאללה');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('75', 'ירדן (יריחו)');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('76', 'בית לחם');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('77', 'חברון');




INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("אבו ג'ווייעד (שבט)",'6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבו גוש','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבו סנאן','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבו סריחאן (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבו עבדון (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבו עמאר (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבו עמרה (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבו קורינאת (יישוב)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבו קורינאת (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבו רובייעה (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבו רוקייק (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבו תלול','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבטין','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבטליון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אביאל','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אביבים','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אביגדור','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אביחיל','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אביטל','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אביעזר','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבירים','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבן יהודה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבן מנחם','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבן ספיר','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבן שמואל','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבני איתן','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבני חפץ','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבנת','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אבשלום','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אדורה','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אדירים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אדמית','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אדרת','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אודים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אודם','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אוהד','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אום אל-פחם','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אום אל-קוטוף','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אום בטין','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אומן','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אומץ','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אופקים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אור הגנוז','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אור הנר','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אור יהודה','5','52');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אור עקיבא','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אורה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אורון','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אורות','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אורטל','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אורים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אורנים','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אורנית','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אושה','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור','5','53');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור אילון מ"א 4','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור אילון מ"א 52','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור אילון של"ש','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור אשדוד מ"א 29','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור אשדוד מ"א 33','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור אשדוד של"ש','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור אשקלון מ"א 36','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור אשקלון מ"א 37','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור באר שבע מ"א 41','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור באר שבע מ"א 51','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור באר שבע של"ש','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור בשור מ"א 38','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור בשור מ"א 39','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור בשור מ"א 42','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור גלילות מ"א 19','5','51');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור גרר מ"א 39','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור גרר מ"א 41','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור גרר מ"א 42','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור זכרון יעקב מ"א 15','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור זכרון יעקב של"ש','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור חדרה מ"א 14','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור חדרה מ"א 15','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור חדרה מ"א 45','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור חדרה של"ש','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור חולון של"ש','5','53');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור חיפה מ"א 12','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור חיפה של"ש','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור חצור מ"א 1','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור חצור מ"א 55','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור חצור של"ש','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור יחיעם מ"א 2','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור יחיעם מ"א 4','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור יחיעם מ"א 52','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור יחיעם מ"א 56','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור יחיעם של"ש','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור ים המלח מ"א 51','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור יקנעם מ"א 13','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור יקנעם מ"א 9','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור כינרות מ"א 3','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור כנרות מ"א 1','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור כנרות מ"א 6','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור כנרות של"ש','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור כרמיאל מ"א 2','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור כרמיאל מ"א 56','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור כרמיאל של"ש','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור לכיש מ"א 34','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור לכיש מ"א 35','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור לכיש מ"א 41','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור לכיש מ"א 50','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור מודיעין מ"א 25','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור מודיעין מ"א 30','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור מודיעין של"ש','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור מלאכי מ"א 33','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור מלאכי מ"א 34','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור מלאכי מ"א 35','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור מלאכי מ"א 50','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור נהרייה מ"א 4','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור נהרייה של"ש','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור עכו מ"א 4','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור עכו מ"א 56','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור עכו של"ש','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור פתח תקווה מ"א 20','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור פתח תקווה מ"א 25','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור פתח תקווה של"ש','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור ראשל"צ מ"א 27','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור ראשל"צ של"ש','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור רחובות מ"א 28','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור רחובות מ"א 29','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור רחובות מ"א 30','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור רחובות מ"א 31','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור רחובות מ"א 32','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור רחובות של"ש','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור רמלה מ"א 25','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור רמלה מ"א 30','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור רמלה מ"א 40','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור רמלה של"ש','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור רמת גן של"ש','5','52');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור שפרעם מ"א 56','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור שפרעם מ"א 9','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור שפרעם של"ש','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור תל אביב של"ש','5','51');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור תעסוקה משגב(תרדיון)','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור תעשיה אכסאל מ"א 9','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור תעשייה אכזיב (מילואות)','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אזור תעשייה נעמן (מילואות)','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אחווה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אחוזם','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אחוזת ברק','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אחיהוד','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אחיטוב','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אחיסמך','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אחיעזר','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אטרש (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('איבים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אייל','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('איילת השחר','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אילון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אילון תבור*','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אילות','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אילנייה','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אילת','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אירוס','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('איתמר','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('איתן','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('איתנים','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אכסאל','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אל -עזי','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אל -עריאן','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אל -רום','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אל סייד','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלומה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלומות','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלון הגליל','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלון מורה','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלון שבות','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלוני אבא','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלוני הבשן','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלוני יצחק','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלונים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלי-עד','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אליאב','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אליכין','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אליפז','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אליפלט','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אליקים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלישיב','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלישמע','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלמגור','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלמוג','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלעד','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלעזר','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלפי מנשה','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלקוש','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אלקנה','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אמונים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אמירים','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אמנון','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אמציה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אניעם','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אסד (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אספר','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אעבלין','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אעצם (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אפיניש (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אפיק','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אפיקים','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אפק','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אפרת','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ארבל','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ארגמן','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ארז','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אריאל','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ארסוף','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אשבול','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אשבל','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אשדוד','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אשדות יעקב (איחוד)','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אשדות יעקב (מאוחד)','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אשחר','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אשכולות','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אשל הנשיא','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אשלים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אשקלון','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אשרת','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('אשתאול','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('באקה אל-גרביה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('באר אורה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('באר גנים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('באר טוביה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('באר יעקב','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('באר מילכה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('באר שבע','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בארות יצחק','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בארותיים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בארי','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בוסתן הגליל','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("בועיינה-נוג'ידאת",'2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בוקעאתא','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בורגתה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בחן','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בטחה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בי"ס אזורי מקיף (אשר)','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ביצרון','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ביר אל-מכסור','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("ביר הדאג'",'6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בירייה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית אורן','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית אל','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית אלעזרי','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית אלפא','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית אריה-עופרים','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית ברל','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("בית ג'ן",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית גוברין','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית גמליאל','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית דגן','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית הגדי','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית הלוי','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית הלל','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית העמק','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית הערבה','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית השיטה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית זיד','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית זית','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית זרע','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית חולים פוריה','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית חורון','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית חירות','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית חלקיה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית חנן','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית חנניה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית חשמונאי','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית יהושע','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית יוסף','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית ינאי','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית יצחק-שער חפר','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית לחם הגלילית','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית מאיר','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית נחמיה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית ניר','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית נקופה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית עובד','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית עוזיאל','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית עזרא','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית עריף','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית צבי','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית קמה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית קשת','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית רבן','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית רימון','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית שאן','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית שמש','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית שערים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בית שקמה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ביתן אהרן','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ביתר עילית','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בלפוריה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בן זכאי','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בן עמי','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בן שמן (כפר נוער)','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בן שמן (מושב)','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בני ברק','5','52');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בני דקלים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בני דרום','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בני דרור','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בני יהודה','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בני נצרים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בני עטרות','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בני עי"ש','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בני ציון','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בני ראם','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בניה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בנימינה-גבעת עדה*','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בסמ"ה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בסמת טבעון','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בענה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בצרה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בצת','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בקוע','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בקעות','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בקעת נטופה מ"א 56','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בקעת תירען מ"א 3','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בר-לב','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בר גיורא','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בר יוחאי','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ברוכין','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ברור חיל','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ברוש','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ברכה','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ברכיה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ברעם','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ברק','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ברקאי','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ברקן','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ברקת','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בת הדר','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בת חן','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בת חפר','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בת ים','5','53');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בת עין','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בת שלמה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('בתי זיקוק - קישון','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("ג'דיידה-מכר",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("ג'ולס",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("ג'לג'וליה",'4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("ג'נאביב (שבט)",'6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("ג'סר א-זרקא",'3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("ג'ש (גוש חלב)",'2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("ג'ת",'3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גאולי תימן','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גאולים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גאון הירדן מ"א 3','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גאליה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבולות','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבע','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבע בנימין','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבע כרמל','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעולים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעון החדשה','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעות בר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת אבני','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת אלה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת ברנר','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת השלושה','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת זאב','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת ח"ן','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת חביבה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת חיים (איחוד)','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת חיים (מאוחד)','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת יואב','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת יערים','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת ישעיהו','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת כ"ח','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת ניל"י','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת עוז','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת שמואל','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת שמש','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעת שפירא','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעתי','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבעתיים','5','52');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גברעם','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גבת','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גדות','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גדיש','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גדעונה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גדרה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גולן דרומי מ"א 71','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גולן צפוני מ"א 71','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גולן תיכון מ"א 71','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גונן','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גורן','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גורנות הגליל','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גזית','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גזר','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גיאה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גיבתון','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גיזו','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גילון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גילת','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גינוסר','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גיניגר','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גינתון','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גיתה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גיתית','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גלאון','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גלגל','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גליל ים','5','51');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גליל עליון מז מ"א 1','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גליל עליון מז מ"א 2','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גליל עליון מז מ"א 55','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גליל עליון מז של"ש','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גליל תחתון מז מ"א 2','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גליל תחתון מז מ"א 3','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גליל תחתון מז מ"א 6','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גליל תחתון מז של"ש','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גלעד (אבן יצחק)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גמ"ל מחוז דרום','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גמזו','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גן הדרום','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גן השומרון','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גן חיים','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גן יאשיה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גן יבנה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גן נר','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גן שורק','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גן שלמה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גן שמואל','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גנות','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גנות הדר','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גני הדר','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גני טל','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גני יוחנן','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גני מודיעין','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גני עם','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גני תקווה','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('געש','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('געתון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גפן','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גרופית','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גשור','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גשר','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גשר הזיו','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גת (קיבוץ)','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('גת רימון','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דאלית אל-כרמל','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דבורה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דבורייה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דבירה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דברת','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("דגניה א'",'2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("דגניה ב'",'2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דוב"ב','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דולב','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דור','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דורות','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דחי','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דייר אל-אסד','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דייר חנא','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דייר ראפאת','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דימונה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דישון','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דלייה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דלתון','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דלתון','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דמיידה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דן','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דפנה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דקל','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דרום השרון מ"א 18','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דרום השרון מ"א 20','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דרום השרון של"ש','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('דרום יהודה','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("דריג'את",'6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('האון','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הבונים','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הגושרים','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הדר עם','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הוד השרון','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הודיות','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הודייה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הוואשלה (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הוזייל (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הושעיה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הזורע','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הזורעים','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('החותרים','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('היוגב','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הילה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('המעפיל','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('המרכז למחקר-נחל שורק','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הסוללים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('העוגן','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הערבה מ"א 51','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הערבה מ"א 53','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הערבה מ"א 54','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הר אדר','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הר אלכסנדר מ"א 14','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הר אלכסנדר מ"א 45','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הר אלכסנדר של"ש','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הר גילה','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הר הנגב הדרומי מ"א 48','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הר הנגב הדרומי מ"א 53','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הר הנגב הדרומי מ"א 54','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הר הנגב הצפוני מ"א 48','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הר הנגב הצפוני מ"א 51','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הר הנגב הצפוני מ"א 53','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הר הנגב הצפוני מ"א 54','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הר עמשא','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הראל','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הרדוף','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הרי יהודה מ"א 26','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הרי יהודה של"ש','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הרי נצרת-תירען','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הרי נצרת-תירען מ"א 9','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הרצלייה','5','51');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('הררית','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('השומרון','7','71');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ורד יריחו','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ורדון','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('זבארגה (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('זבדיאל','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('זוהר','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('זיקים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('זיתן','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('זכרון יעקב','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('זכריה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('זמר','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('זמרת','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('זנוח','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('זרועה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('זרזיר','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('זרחיה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("ח'ואלד",'3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("ח'ואלד (שבט)",'2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חבצלת השרון','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חבר','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חגור','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חגי','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חגלה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חד-נס','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חדיד','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חדרה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("חוג'ייראת (ד'הרה) (שבט)",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חולדה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חולון','5','53');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חולית','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חולתה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חוסן','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חוסנייה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חוף הכרמל מ"א 15','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חופית','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חוקוק','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חורה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חורפיש','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חורשים','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חזון','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חיבת ציון','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חיננית','7','71');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חיפה','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חירות','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חלוץ','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חלץ','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חמ"ד','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חמאם','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חמדיה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חמדת','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חמרה','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חניאל','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חניתה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חנתון','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חספין','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חפץ חיים','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חפצי-בה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חצב','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חצבה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חצור-אשדוד','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חצור הגלילית','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חצרים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חרב לאת','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חרוצים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חריש','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חרמון מ"א 71','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חרמש','7','71');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חרשים','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('חשמונאים','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('טבריה','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('טובא-זנגרייה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('טורעאן','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('טייבה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('טייבה (בעמק)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('טירה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('טירת יהודה','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('טירת כרמל','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('טירת צבי','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('טל-אל','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('טל שחר','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('טללים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('טלמון','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('טמרה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('טמרה (יזרעאל)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('טנא','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('טפחות','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("יאנוח-ג'ת",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יבול','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יבנאל','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יבנה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יגור','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יגל','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יד בנימין','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יד השמונה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יד חנה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יד מרדכי','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יד נתן','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יד רמב"ם','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ידידה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יהוד','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יהל','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יובל','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יובלים','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יודפת','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יונתן','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יושיביה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יזרעאל','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יחיעם','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יטבתה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ייט"ב','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יכיני','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ים המלח - בתי מלון','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ינוב','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ינון','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יסוד המעלה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יסודות','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יסעור','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יעד','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יעל','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יעף','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יערה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יערות גבעת המורה מ"א 9','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יפיע','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יפית','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יפעת','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יפתח','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יצהר','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יציץ','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יקום','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יקיר','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יקנעם (מושבה)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יקנעם עילית','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יראון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ירדנה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ירוחם','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ירושלים','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ירחיב','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ירכא','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ירקונה','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ישע','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ישעי','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ישרש','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('יתד','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כאבול','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("כאוכב אבו אל-היג'א",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כברי','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כדורי','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כדיתה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כוכב השחר','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כוכב יאיר','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כוכב יעקב','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כוכב מיכאל','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כורזים','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כחל','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כחלה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כיסופים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כישור','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כליל','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כלנית','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כמאנה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כמהין','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כמון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כנות','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כנף','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כנרת (מושבה)','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כנרת (קבוצה)','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כסיפה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כסלון','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כסרא-סמיע','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("כעביה-טבאש-חג'אג'רה",'2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר אביב','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר אדומים','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר אוריה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר אחים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר ביאליק','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר ביל"ו','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר בלום','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר בן נון','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר ברא','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר ברוך','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר גדעון','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר גלים','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר גליקסון','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר גלעדי','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר דניאל','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר האורנים','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר החורש','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר המכבי','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר הנגיד','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר הנוער הדתי','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר הנשיא','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר הס','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר הרא"ה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר הרי"ף','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר ויתקין','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר ורבורג','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר ורדים','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר זוהרים','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר זיתים','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר חב"ד','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר חושן','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר חיטים','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר חיים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר חנניה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("כפר חסידים א'",'3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("כפר חסידים ב'",'3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר חרוב','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר טרומן','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר יאסיף','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר ידידיה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר יהושע','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר יונה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר יחזקאל','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר יעבץ','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר כמא','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר כנא','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר מונש','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר מימון','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר מל"ל','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר מנדא','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר מנחם','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר מסריק','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר מצר','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר מרדכי','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר נטר','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר סאלד','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר סבא','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר סילבר','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר סירקין','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר עבודה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר עזה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר עציון','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר פינס','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר קאסם','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר קיש','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר קרע','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר ראש הנקרה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר רוזנואלד (זרעית)','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר רופין','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר רות','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר שמאי','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר שמואל','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר שמריהו','5','51');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר תבור','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כפר תפוח','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כרכום','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כרם בן זמרה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כרם בן שמן','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כרם יבנה (ישיבה)','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כרם מהר"ל','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כרם שלום','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כרמי יוסף','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כרמי צור','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כרמי קטיף','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כרמיאל','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כרמייה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כרמים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('כרמל','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('לבון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('לביא','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('לבנים','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('להב','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('להבות הבשן','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('להבות חביבה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('להבים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('לוד','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('לוזית','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('לוחמי הגיטאות','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('לוטם','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('לוטן','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('לימן','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('לכיש','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('לפיד','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('לפידות','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('לקיה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מאור','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מאיר שפיה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מבוא ביתר','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מבוא דותן','7','71');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מבוא חורון','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מבוא חמה','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מבוא מודיעים','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מבואות ים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מבואות יריחו','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מבועים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מבטחים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מבקיעים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מבשרת ציון','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("מג'ד אל-כרום",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("מג'דל שמס",'2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מגאר','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מגדים','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מגדל','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מגדל העמק','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מגדל עוז','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מגדל תפן','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מגדלים','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מגידו','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מגל','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מגן','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מגן שאול','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מגשימים','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מדרך עוז','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מדרשת בן גוריון','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מדרשת רופין','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מודיעין-מכבים-רעות*','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מודיעין עילית','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מולדת','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מוצא עילית','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מוקייבלה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מורן','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מורשת','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מזור','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מזכרת בתיה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מזרח השרון מ"א 16','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מזרח השרון מ"א 18','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מזרע','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מזרעה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מחולה','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מחנה הילה*','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מחנה טלי*','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מחנה יהודית*','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מחנה יוכבד*','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מחנה יפה*','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מחנה יתיר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מחנה מרים*','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מחנה תל נוף*','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מחניים','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מחסיה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מטולה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מטע','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מי עמי','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מיטב','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מייסר','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מיצר','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מירב','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מירון','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מישר','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מיתר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מכורה','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מכחול','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מכמורת','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מכמנים','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מלאה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מלילות','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מלכייה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מלכישוע','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מנוחה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מנוף','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מנות','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מנחמיה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מנרה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מנשית זבדה','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מסד','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מסדה','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מסילות','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מסילת ציון','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מסלול','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מסעדה','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מסעודין אל-עזאזמה (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעברות','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעגלים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעגן','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעגן מיכאל','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעוז חיים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעון','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעונה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעיין ברוך','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעיין צבי','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעיליא','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעלה אדומים','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעלה אפרים','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעלה גלבוע','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעלה גמלא','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעלה החמישה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעלה לבונה','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעלה מכמש','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעלה עירון','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעלה עמוס','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעלה שומרון','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעלות-תרשיחא','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מענית','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מערב השרון מ"א 16','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מערב השרון מ"א 18','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מערב השרון מ"א 19','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מעש','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מפלסים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מפעלי אבשלו"ם','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מפעלי ברקן','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מפעלי גליל עליון','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מפעלי גרנות','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מפעלי העמק (יזרעאל)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מפעלי חבל מודיעים','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מפעלי חפר','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מפעלי ים המלח(סדום)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מפעלי כנות','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מפעלי מישור רותם','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מפעלי מעון','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מפעלי נחם הרטוב','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מפעלי צומת מלאכי','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מפעלי צין - ערבה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מפעלי צמח','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מפעלי שאן','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מצדות יהודה','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מצובה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מצליח','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מצפה','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מצפה אבי"ב','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מצפה אילן','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מצפה יריחו','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מצפה נטופה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מצפה רמון','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מצפה שלם','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מצר','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מקווה ישראל','5','53');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מרגליות','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מרום גולן','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מרחב עם','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מרחביה (מושב)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מרחביה (קיבוץ)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מרכז אזורי כדורי','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מרכז אזורי מרום הגליל','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מרכז אזורי משגב','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מרכז אזורי שוהם','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מרכז כ"ח','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מרכז מיר"ב*','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מרכז שפירא','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('משאבי שדה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('משגב דב','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('משגב עם','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('משהד','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('משואה','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('משואות יצחק','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('משכיות','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('משמר איילון','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('משמר דוד','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('משמר הירדן','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('משמר הנגב','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('משמר העמק','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('משמר השבעה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('משמר השרון','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('משמרות','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('משמרת','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('משען','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מתן','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מתת','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('מתתיהו','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נאות גולן','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נאות הכיכר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נאות חובב','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נאות מרדכי','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נאות סמדר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נאעורה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נבטים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נגבה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נגוהות','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נהורה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נהלל','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נהרייה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נוב','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נוגה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה אבות','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה אור','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה אטי"ב','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה אילן','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה אילן*','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה איתן','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה דניאל','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה זוהר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה זיו','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה חריף','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה ים','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה ימין','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה ירק','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה מבטח','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה מיכאל','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה צוף','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נווה שלום','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נועם','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נוף איילון','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נוף הגליל','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נופים','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נופית','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נופך','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נוקדים','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נורדייה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נורית','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נחושה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נחל יפתחאל מ"א 3','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נחל עוז','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נחל תבור מ"א 8','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נחלה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נחליאל','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נחלים','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נחם','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נחף','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נחשולים','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נחשון','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נחשונים','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נטועה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נטור','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נטע','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נטעים','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נטף','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניין','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניל"י','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניצן','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("ניצן ב'",'6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניצנה (קהילת חינוך)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניצני סיני','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניצני עוז','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניצנים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניר אליהו','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניר בנים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניר גלים','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניר דוד (תל עמל)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניר ח"ן','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניר יפה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניר יצחק','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניר ישראל','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניר משה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניר עוז','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניר עם','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניר עציון','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניר עקיבא','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ניר צבי','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נירים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נירית','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נמל תעופה בן-גוריון','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נמרוד','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נס הרים','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נס עמים','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נס ציונה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נעורים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נעלה','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נעמ"ה','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נען','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נערן','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נפת בית לחם','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נפת בית לחם מ"א 76','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("נפת ג'נין",'7','71');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נפת חברון','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נפת חברון מ"א 78','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נפת טול כרם','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נפת טול כרם  מ"א 72','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נפת ירדן','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נפת ירדן מ"א 74','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נפת ירדן מ"א 75','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נפת ראמאללה ','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נפת ראמאללה מ"א  73','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נפת שכם','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נפת שכם מ"א 72','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נצאצרה (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נצר חזני','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נצר סרני','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נצרת','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נשר','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נתיב הגדוד','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נתיב הל"ה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נתיב העשרה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נתיב השיירה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נתיבות','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('נתניה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("סאג'ור",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('סאסא','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('סביון','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('סגולה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('סואעד (חמרייה)','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('סואעד (כמאנה) (שבט)','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('סולם','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('סוסיה','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('סופה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("סח'נין",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('סייד (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('סלמה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('סלעית','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('סמר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('סנסנה','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('סעד','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('סעוה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('סער','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ספיר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('סתרייה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("ע'ג'ר",'2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עבדון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עברון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עגור','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עד הלום','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עדי','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עדנים','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עוזה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עוזייר','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עולש','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עומר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עופר','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עוצם','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עוקבי (בנו עוקבה) (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עזוז','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עזר','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עזריאל','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עזריה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עזריקם','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עטאוונה (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עטרת','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עידן','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עידן הנגב','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עיילבון','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עיינות','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עילוט','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין איילה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין אל-אסד','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין גב','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין גדי','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין דור','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין הבשור','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין הוד','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין החורש','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין המפרץ','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין הנצי"ב','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין העמק','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין השופט','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין השלושה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין ורד','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין זיוון','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין חוד','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין חצבה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין חרוד (איחוד)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין חרוד (מאוחד)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין יהב','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין יעקב','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין כרם-בי"ס חקלאי','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין כרמל','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין מאהל','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין נקובא','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין עירון','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין צורים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין קנייא','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין ראפה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין שמר','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין שריד','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עין תמר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עינת','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עיר אובות','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עכו','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עלומים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עלי','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עלי זהב','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עלמה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עלמון','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמוקה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמיחי','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמינדב','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמיעד','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמיעוז','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמיקם','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמיר','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמנואל','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמק בית שאן מ"א 7','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמק בית שאן של"ש','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמק חולה מ"א 1','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמק חולה מ"א 55','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמק חולה של"ש','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמק חפר מזרח מ"א 16','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמק חרוד מ"א 8','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמק חרוד של"ש','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמק יזרעאל מ"א 13','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמק יזרעאל מ"א 8','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמק יזרעאל מ"א 9','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עמקה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ענב','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עספיא','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עפולה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עפרה','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עץ אפרים','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עצמון שגב','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עראבה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עראמשה*','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ערב אל נעים','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ערד','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ערוגות','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ערערה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ערערה-בנגב','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עשרת','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עתלית','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('עתניאל','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פארן','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פארק הירדן מ"א 6','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פארק תעשיות ספירים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פדואל','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פדויים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פדיה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פוריידיס','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פורייה - כפר עבודה','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פורייה - נווה עובד','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פורייה עילית','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פורת','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פטיש','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פלך','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פלמחים','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פני חבר','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פסגות','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פסוטה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פעמי תש"ז','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פצאל','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פקיעין (בוקייעה)','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פקיעין חדשה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פרדס חנה-כרכור','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פרדסייה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פרוד','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פרזון','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פרי גן','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פתח תקווה','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('פתחיה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צאלים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צביה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צבעון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צובה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צוחר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צופייה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צופים','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צופית','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צופר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צוקי ים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צוקים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צור הדסה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צור יצחק','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צור משה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צור נתן','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צוריאל','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צורית','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ציפורי','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צלפון','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צנדלה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צפרייה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צפרירים','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צפת','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צרופה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('צרעה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קבועה (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קבוצת יבנה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קדומים','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קדימה-צורן','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קדמה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קדמת צבי','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קדר','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קדרון','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קדרים','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קודייראת א-צאנע (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קוואעין (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קוממיות','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קורנית','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קטורה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קיסריה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קלחים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קליה','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קלנסווה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קלע','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קציר','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קצר א-סר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קצרין','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קריית אונו','5','52');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קריית ארבע','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קריית אתא','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קריית ביאליק','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קריית גת','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קריית חינוך מרחבים*','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קריית טבעון','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קריית ים','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קריית יערים','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קריית יערים (מוסד)','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קריית מוצקין','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קריית מלאכי','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קריית נטפים','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קריית ענבים','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קריית עקרון','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קריית שלמה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קריית שמונה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קרית חינוך עזתה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קרית תעופה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קרני שומרון','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('קשת','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ראמה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ראס אל-עין','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ראס עלי','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ראש העין','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ראש פינה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ראש צורים','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ראשון לציון','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רבבה','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רבדים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רביבים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רביד','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רגבה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רגבים','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רהט','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רווחה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רוויה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רוח מדבר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רוחמה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רומאנה','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רומת הייב','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רועי','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רותם','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רחוב','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רחובות','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רחלים','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ריחאנייה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ריחן','7','71');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('ריינה','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רימונים','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רינתיה','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רכסים','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רם-און','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמות','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמות השבים','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמות מאיר','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמות מנשה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמות נפתלי','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמלה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמת גן','5','52');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמת דוד','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמת הכובש','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמת השופט','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמת השרון','5','51');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמת יוחנן','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמת ישי','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמת כוכב מ"א 7','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמת כוכב מ"א 8','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמת כוכב מ"א 9','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמת כוכב של"ש','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמת מגשימים','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמת מנשה מ"א 13','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמת מנשה של"ש','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמת צבי','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמת רזיאל','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רמת רחל','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רנן','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רעים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רעננה','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רקפת','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רשפון','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רשפים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('רתמים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שאר ישוב','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שבי דרום','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שבי ציון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שבי שומרון','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שבלי - אום אל-גנם','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שגב-שלום','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדה אילן','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדה אליהו','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדה אליעזר','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדה בוקר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדה דוד','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדה ורבורג','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדה יואב','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדה יעקב','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדה יצחק','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדה משה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדה נחום','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדה נחמיה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדה ניצן','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדה עוזיהו','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדה צבי','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדות ים','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדות מיכה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדי אברהם','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדי חמד','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדי תרומות','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדמה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדמות דבורה','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדמות מחולה','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שדרות','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שואבה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שובה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שובל','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שוהם','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שומרה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שומרייה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שוקדה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שורש','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שורשים','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שושנת העמקים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שזור','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שחר','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שחרות','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שיבולים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שיטים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ("שייח' דנון",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שילה','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שילת','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שכניה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שלווה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שלווה במדבר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שלוחות','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שלומי','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שלומית','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שלומציון','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שמיר','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שמעה','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שמרת','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שמשית','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שני','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שניר','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שעב','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שעל','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שעלבים','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שער אפרים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שער הגולן','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שער העמקים','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שער מנשה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שערי תקווה','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שפיים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שפיר','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שפלת יהודה מ"א 26','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שפלת יהודה של"ש','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שפר','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שפרעם','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שקד','7','71');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שקף','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שרונה','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שריגים (לי-און)','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שריד','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שרשרת','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שתולה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('שתולים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תאשור','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תדהר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תובל','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תומר','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תושייה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תימורים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תירוש','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תל אביב -יפו','5','51');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תל חי (מכללה)','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תל יוסף','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תל יצחק','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תל מונד','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תל עדשים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תל קציר','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תל שבע','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תל תאומים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תלם','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תלמי אליהו','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תלמי אלעזר','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תלמי ביל"ו','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תלמי יוסף','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תלמי יחיאל','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תלמי יפה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תלמים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תמרת','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תנובות','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תעוז','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תעשיון בינימין*','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תעשיון השרון','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תעשיון חבל יבנה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תעשיון חצב*','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תעשיון מבצע*','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תעשיון מיתרים','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תעשיון צריפין','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תעשיון ראם*','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תעשיון שח"ק','7','71');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תעשיות גליל תחתון','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תפרח','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תקומה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תקוע','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תראבין א-צאנע (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תרבין א-צאנע (יישוב)*','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES ('תרום','1','11');


CREATE TABLE `refua_delivery`.`user2city` (
  `id` INT NOT NULL,
  `user_id` INT NOT NULL,
  `city_id` INT NOT NULL,
  PRIMARY KEY (`id`));

ALTER TABLE `refua_delivery`.`user2city` 
ADD INDEX `user_id_idx` (`user_id` ASC) VISIBLE,
ADD INDEX `fk_city_id_idx` (`city_id` ASC) VISIBLE;
;

ALTER TABLE `refua_delivery`.`user2city` 
CHANGE COLUMN `id` `id` INT NOT NULL AUTO_INCREMENT ;

ALTER TABLE `refua_delivery`.`user2city` 
ADD CONSTRAINT `fk_user_id`
  FOREIGN KEY (`user_id`)
  REFERENCES `refua_delivery`.`users` (`id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION,
ADD CONSTRAINT `fk_city_id`
  FOREIGN KEY (`city_id`)
  REFERENCES `refua_delivery`.`cities` (`id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE `refua_delivery`.`parcel` 
CHANGE COLUMN `city` `city_old` VARCHAR(50) NULL DEFAULT NULL ;


ALTER TABLE `refua_delivery`.`parcel` 
ADD COLUMN `city` INT(11) NULL AFTER `id`,
ADD INDEX `parcel_city_fk_idx` (`city` ASC) VISIBLE;
;
ALTER TABLE `refua_delivery`.`parcel` 
ADD CONSTRAINT `parcel_city_fk`
  FOREIGN KEY (`city`)
  REFERENCES `refua_delivery`.`cities` (`id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE `refua_delivery`.`district` 
RENAME TO  `refua_delivery`.`districts` ;

ALTER TABLE `refua_delivery`.`subdistrict` 
RENAME TO  `refua_delivery`.`subdistricts` ;


UPDATE refua_delivery.cities  SET name = REPLACE(name, '*', '')
where name like '%*%' and id > 0;

update refua_delivery.cities  set name = 'כפר חסידים' where name like '%כפר חסידים א%' and id > 0;

delete from refua_delivery.cities  where name like '%חסידים ב%' and id > 0;




