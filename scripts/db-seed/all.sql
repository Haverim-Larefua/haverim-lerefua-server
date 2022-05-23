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
	`need_delivery` boolean DEFAULT false,
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
	(parcelTrackingStatus = 'ready' AND TIMESTAMPDIFF(HOUR,lastUpdateDate, CURRENT_TIMESTAMP) > 48)
	OR
    (parcelTrackingStatus = 'assigned' AND TIMESTAMPDIFF(HOUR,lastUpdateDate, CURRENT_TIMESTAMP) > 48)
    OR
	(parcelTrackingStatus = 'distribution' AND TIMESTAMPDIFF(HOUR,lastUpdateDate, CURRENT_TIMESTAMP) > 48)
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

INSERT INTO `refua_delivery`.`admins` (`first_name`, `last_name`, `username`, `password`, `salt`) VALUES (N'admin', 'admin', 'admin', 'cb9af5d9bb030cd8dc49726670f42401c5b13f2e89d92ca465634e948bbe3c97fd605fc59d4d8df50a427e35166ad3fea241e6ab7b21ed2347e536b96f9e3148', 'd047a22b76dd833f');

ALTER TABLE `refua_delivery`.`users` 
ADD FULLTEXT INDEX `search_fulltext` (`first_name`, `last_name`, `phone`) WITH PARSER ngram;

ALTER TABLE `refua_delivery`.`parcel` 
ADD FULLTEXT INDEX `search_fulltext` (`phone`, `customer_name`, `customer_id`) WITH PARSER ngram;

INSERT INTO `refua_delivery`.`district` (`id`, `name`) VALUES ('1', N'ירושלים');
INSERT INTO `refua_delivery`.`district` (`id`, `name`) VALUES ('2', N'הצפון');
INSERT INTO `refua_delivery`.`district` (`id`, `name`) VALUES ('3', N'חיפה');
INSERT INTO `refua_delivery`.`district` (`id`, `name`) VALUES ('4', N'המרכז');
INSERT INTO `refua_delivery`.`district` (`id`, `name`) VALUES ('5', N'תל אביב');
INSERT INTO `refua_delivery`.`district` (`id`, `name`) VALUES ('6', N'הדרום');
INSERT INTO `refua_delivery`.`district` (`id`, `name`) VALUES ('7', N'אזור יהודה והשומרון');

INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('11', N'ירושלים');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('21', N'צפת');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('22', N'כנרת');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('23', N'עפולה');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('24', N'עכו');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('25', N'נצרת');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('29', N'גולן');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('31', N'חיפה');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('32', N'חדרה');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('41', N'השרון');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('42', N'פתח תקווה');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('43', N'רמלה');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('44', N'רחובות');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('51', N'תל אביב');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('52', N'רמת גן');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('53', N'חולון');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('61', N'אשקלון');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('62', N'באר שבע');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('71', N"ג'נין");
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('72', N'שכם');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('73', N'טול כרם');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('74', N'ראמאללה');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('75', N'ירדן (יריחו)');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('76', N'בית לחם');
INSERT INTO `refua_delivery`.`subdistrict` (`id`, `name`) VALUES ('77', N'חברון');




INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"אבו ג'ווייעד (שבט)",'6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבו גוש','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבו סנאן','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבו סריחאן (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבו עבדון (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבו עמאר (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבו עמרה (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבו קורינאת (יישוב)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבו קורינאת (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבו רובייעה (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבו רוקייק (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבו תלול','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבטין','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבטליון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אביאל','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אביבים','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אביגדור','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אביחיל','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אביטל','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אביעזר','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבירים','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבן יהודה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבן מנחם','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבן ספיר','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבן שמואל','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבני איתן','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבני חפץ','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבנת','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אבשלום','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אדורה','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אדירים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אדמית','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אדרת','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אודים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אודם','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אוהד','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אום אל-פחם','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אום אל-קוטוף','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אום בטין','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אומן','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אומץ','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אופקים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אור הגנוז','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אור הנר','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אור יהודה','5','52');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אור עקיבא','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אורה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אורון','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אורות','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אורטל','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אורים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אורנים','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אורנית','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אושה','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור','5','53');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור אילון מ"א 4','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור אילון מ"א 52','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור אילון של"ש','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור אשדוד מ"א 29','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור אשדוד מ"א 33','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור אשדוד של"ש','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור אשקלון מ"א 36','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור אשקלון מ"א 37','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור באר שבע מ"א 41','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור באר שבע מ"א 51','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור באר שבע של"ש','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור בשור מ"א 38','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור בשור מ"א 39','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור בשור מ"א 42','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור גלילות מ"א 19','5','51');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור גרר מ"א 39','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור גרר מ"א 41','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור גרר מ"א 42','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור זכרון יעקב מ"א 15','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור זכרון יעקב של"ש','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור חדרה מ"א 14','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור חדרה מ"א 15','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור חדרה מ"א 45','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור חדרה של"ש','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור חולון של"ש','5','53');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור חיפה מ"א 12','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור חיפה של"ש','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור חצור מ"א 1','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור חצור מ"א 55','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור חצור של"ש','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור יחיעם מ"א 2','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור יחיעם מ"א 4','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור יחיעם מ"א 52','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור יחיעם מ"א 56','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור יחיעם של"ש','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור ים המלח מ"א 51','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור יקנעם מ"א 13','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור יקנעם מ"א 9','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור כינרות מ"א 3','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור כנרות מ"א 1','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור כנרות מ"א 6','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור כנרות של"ש','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור כרמיאל מ"א 2','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור כרמיאל מ"א 56','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור כרמיאל של"ש','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור לכיש מ"א 34','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור לכיש מ"א 35','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור לכיש מ"א 41','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור לכיש מ"א 50','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור מודיעין מ"א 25','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור מודיעין מ"א 30','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור מודיעין של"ש','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור מלאכי מ"א 33','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור מלאכי מ"א 34','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור מלאכי מ"א 35','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור מלאכי מ"א 50','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור נהרייה מ"א 4','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור נהרייה של"ש','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור עכו מ"א 4','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור עכו מ"א 56','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור עכו של"ש','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור פתח תקווה מ"א 20','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור פתח תקווה מ"א 25','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור פתח תקווה של"ש','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור ראשל"צ מ"א 27','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור ראשל"צ של"ש','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור רחובות מ"א 28','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור רחובות מ"א 29','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור רחובות מ"א 30','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור רחובות מ"א 31','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור רחובות מ"א 32','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור רחובות של"ש','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור רמלה מ"א 25','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור רמלה מ"א 30','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור רמלה מ"א 40','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור רמלה של"ש','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור רמת גן של"ש','5','52');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור שפרעם מ"א 56','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור שפרעם מ"א 9','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור שפרעם של"ש','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור תל אביב של"ש','5','51');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור תעסוקה משגב(תרדיון)','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור תעשיה אכסאל מ"א 9','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור תעשייה אכזיב (מילואות)','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אזור תעשייה נעמן (מילואות)','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אחווה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אחוזם','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אחוזת ברק','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אחיהוד','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אחיטוב','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אחיסמך','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אחיעזר','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אטרש (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'איבים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אייל','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'איילת השחר','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אילון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אילון תבור*','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אילות','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אילנייה','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אילת','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אירוס','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'איתמר','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'איתן','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'איתנים','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אכסאל','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אל -עזי','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אל -עריאן','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אל -רום','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אל סייד','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלומה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלומות','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלון הגליל','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלון מורה','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלון שבות','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלוני אבא','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלוני הבשן','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלוני יצחק','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלונים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלי-עד','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אליאב','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אליכין','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אליפז','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אליפלט','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אליקים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלישיב','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלישמע','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלמגור','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלמוג','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלעד','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלעזר','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלפי מנשה','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלקוש','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אלקנה','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אמונים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אמירים','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אמנון','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אמציה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אניעם','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אסד (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אספר','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אעבלין','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אעצם (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אפיניש (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אפיק','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אפיקים','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אפק','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אפרת','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ארבל','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ארגמן','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ארז','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אריאל','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ארסוף','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אשבול','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אשבל','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אשדוד','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אשדות יעקב (איחוד)','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אשדות יעקב (מאוחד)','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אשחר','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אשכולות','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אשל הנשיא','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אשלים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אשקלון','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אשרת','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'אשתאול','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'באקה אל-גרביה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'באר אורה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'באר גנים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'באר טוביה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'באר יעקב','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'באר מילכה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'באר שבע','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בארות יצחק','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בארותיים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בארי','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בוסתן הגליל','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"בועיינה-נוג'ידאת",'2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בוקעאתא','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בורגתה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בחן','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בטחה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בי"ס אזורי מקיף (אשר)','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ביצרון','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ביר אל-מכסור','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"ביר הדאג'",'6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בירייה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית אורן','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית אל','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית אלעזרי','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית אלפא','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית אריה-עופרים','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית ברל','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"בית ג'ן",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית גוברין','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית גמליאל','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית דגן','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית הגדי','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית הלוי','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית הלל','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית העמק','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית הערבה','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית השיטה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית זיד','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית זית','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית זרע','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית חולים פוריה','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית חורון','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית חירות','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית חלקיה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית חנן','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית חנניה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית חשמונאי','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית יהושע','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית יוסף','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית ינאי','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית יצחק-שער חפר','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית לחם הגלילית','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית מאיר','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית נחמיה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית ניר','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית נקופה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית עובד','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית עוזיאל','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית עזרא','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית עריף','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית צבי','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית קמה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית קשת','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית רבן','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית רימון','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית שאן','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית שמש','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית שערים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בית שקמה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ביתן אהרן','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ביתר עילית','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בלפוריה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בן זכאי','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בן עמי','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בן שמן (כפר נוער)','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בן שמן (מושב)','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בני ברק','5','52');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בני דקלים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בני דרום','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בני דרור','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בני יהודה','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בני נצרים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בני עטרות','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בני עי"ש','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בני ציון','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בני ראם','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בניה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בנימינה-גבעת עדה*','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בסמ"ה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בסמת טבעון','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בענה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בצרה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בצת','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בקוע','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בקעות','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בקעת נטופה מ"א 56','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בקעת תירען מ"א 3','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בר-לב','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בר גיורא','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בר יוחאי','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ברוכין','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ברור חיל','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ברוש','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ברכה','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ברכיה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ברעם','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ברק','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ברקאי','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ברקן','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ברקת','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בת הדר','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בת חן','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בת חפר','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בת ים','5','53');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בת עין','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בת שלמה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'בתי זיקוק - קישון','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"ג'דיידה-מכר",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"ג'ולס",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"ג'לג'וליה",'4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"ג'נאביב (שבט)",'6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"ג'סר א-זרקא",'3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"ג'ש (גוש חלב)",'2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"ג'ת",'3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גאולי תימן','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גאולים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גאון הירדן מ"א 3','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גאליה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבולות','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבע','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבע בנימין','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבע כרמל','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעולים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעון החדשה','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעות בר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת אבני','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת אלה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת ברנר','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת השלושה','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת זאב','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת ח"ן','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת חביבה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת חיים (איחוד)','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת חיים (מאוחד)','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת יואב','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת יערים','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת ישעיהו','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת כ"ח','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת ניל"י','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת עוז','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת שמואל','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת שמש','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעת שפירא','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעתי','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבעתיים','5','52');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גברעם','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גבת','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גדות','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גדיש','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גדעונה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גדרה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גולן דרומי מ"א 71','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גולן צפוני מ"א 71','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גולן תיכון מ"א 71','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גונן','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גורן','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גורנות הגליל','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גזית','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גזר','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גיאה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גיבתון','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גיזו','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גילון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גילת','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גינוסר','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גיניגר','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גינתון','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גיתה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גיתית','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גלאון','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גלגל','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גליל ים','5','51');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גליל עליון מז מ"א 1','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גליל עליון מז מ"א 2','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גליל עליון מז מ"א 55','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גליל עליון מז של"ש','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גליל תחתון מז מ"א 2','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גליל תחתון מז מ"א 3','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גליל תחתון מז מ"א 6','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גליל תחתון מז של"ש','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גלעד (אבן יצחק)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גמ"ל מחוז דרום','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גמזו','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גן הדרום','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גן השומרון','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גן חיים','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גן יאשיה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גן יבנה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גן נר','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גן שורק','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גן שלמה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גן שמואל','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גנות','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גנות הדר','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גני הדר','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גני טל','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גני יוחנן','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גני מודיעין','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גני עם','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גני תקווה','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'געש','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'געתון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גפן','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גרופית','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גשור','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גשר','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גשר הזיו','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גת (קיבוץ)','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'גת רימון','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דאלית אל-כרמל','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דבורה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דבורייה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דבירה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דברת','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"דגניה א'",'2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"דגניה ב'",'2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דוב"ב','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דולב','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דור','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דורות','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דחי','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דייר אל-אסד','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דייר חנא','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דייר ראפאת','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דימונה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דישון','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דלייה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דלתון','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דלתון','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דמיידה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דן','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דפנה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דקל','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דרום השרון מ"א 18','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דרום השרון מ"א 20','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דרום השרון של"ש','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'דרום יהודה','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"דריג'את",'6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'האון','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הבונים','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הגושרים','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הדר עם','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הוד השרון','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הודיות','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הודייה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הוואשלה (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הוזייל (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הושעיה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הזורע','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הזורעים','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'החותרים','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'היוגב','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הילה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'המעפיל','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'המרכז למחקר-נחל שורק','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הסוללים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'העוגן','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הערבה מ"א 51','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הערבה מ"א 53','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הערבה מ"א 54','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הר אדר','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הר אלכסנדר מ"א 14','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הר אלכסנדר מ"א 45','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הר אלכסנדר של"ש','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הר גילה','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הר הנגב הדרומי מ"א 48','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הר הנגב הדרומי מ"א 53','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הר הנגב הדרומי מ"א 54','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הר הנגב הצפוני מ"א 48','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הר הנגב הצפוני מ"א 51','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הר הנגב הצפוני מ"א 53','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הר הנגב הצפוני מ"א 54','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הר עמשא','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הראל','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הרדוף','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הרי יהודה מ"א 26','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הרי יהודה של"ש','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הרי נצרת-תירען','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הרי נצרת-תירען מ"א 9','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הרצלייה','5','51');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'הררית','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'השומרון','7','71');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ורד יריחו','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ורדון','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'זבארגה (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'זבדיאל','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'זוהר','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'זיקים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'זיתן','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'זכרון יעקב','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'זכריה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'זמר','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'זמרת','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'זנוח','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'זרועה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'זרזיר','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'זרחיה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"ח'ואלד",'3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"ח'ואלד (שבט)",'2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חבצלת השרון','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חבר','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חגור','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חגי','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חגלה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חד-נס','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חדיד','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חדרה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"חוג'ייראת (ד'הרה) (שבט)",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חולדה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חולון','5','53');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חולית','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חולתה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חוסן','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חוסנייה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חוף הכרמל מ"א 15','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חופית','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חוקוק','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חורה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חורפיש','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חורשים','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חזון','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חיבת ציון','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חיננית','7','71');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חיפה','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חירות','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חלוץ','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חלץ','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חמ"ד','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חמאם','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חמדיה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חמדת','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חמרה','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חניאל','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חניתה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חנתון','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חספין','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חפץ חיים','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חפצי-בה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חצב','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חצבה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חצור-אשדוד','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חצור הגלילית','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חצרים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חרב לאת','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חרוצים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חריש','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חרמון מ"א 71','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חרמש','7','71');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חרשים','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'חשמונאים','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'טבריה','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'טובא-זנגרייה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'טורעאן','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'טייבה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'טייבה (בעמק)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'טירה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'טירת יהודה','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'טירת כרמל','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'טירת צבי','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'טל-אל','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'טל שחר','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'טללים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'טלמון','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'טמרה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'טמרה (יזרעאל)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'טנא','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'טפחות','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"יאנוח-ג'ת",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יבול','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יבנאל','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יבנה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יגור','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יגל','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יד בנימין','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יד השמונה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יד חנה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יד מרדכי','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יד נתן','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יד רמב"ם','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ידידה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יהוד','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יהל','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יובל','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יובלים','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יודפת','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יונתן','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יושיביה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יזרעאל','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יחיעם','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יטבתה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ייט"ב','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יכיני','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ים המלח - בתי מלון','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ינוב','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ינון','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יסוד המעלה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יסודות','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יסעור','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יעד','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יעל','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יעף','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יערה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יערות גבעת המורה מ"א 9','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יפיע','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יפית','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יפעת','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יפתח','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יצהר','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יציץ','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יקום','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יקיר','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יקנעם (מושבה)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יקנעם עילית','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יראון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ירדנה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ירוחם','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ירושלים','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ירחיב','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ירכא','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ירקונה','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ישע','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ישעי','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ישרש','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'יתד','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כאבול','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"כאוכב אבו אל-היג'א",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כברי','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כדורי','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כדיתה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כוכב השחר','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כוכב יאיר','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כוכב יעקב','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כוכב מיכאל','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כורזים','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כחל','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כחלה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כיסופים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כישור','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כליל','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כלנית','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כמאנה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כמהין','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כמון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כנות','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כנף','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כנרת (מושבה)','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כנרת (קבוצה)','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כסיפה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כסלון','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כסרא-סמיע','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"כעביה-טבאש-חג'אג'רה",'2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר אביב','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר אדומים','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר אוריה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר אחים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר ביאליק','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר ביל"ו','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר בלום','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר בן נון','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר ברא','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר ברוך','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר גדעון','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר גלים','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר גליקסון','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר גלעדי','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר דניאל','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר האורנים','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר החורש','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר המכבי','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר הנגיד','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר הנוער הדתי','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר הנשיא','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר הס','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר הרא"ה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר הרי"ף','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר ויתקין','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר ורבורג','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר ורדים','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר זוהרים','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר זיתים','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר חב"ד','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר חושן','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר חיטים','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר חיים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר חנניה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"כפר חסידים א'",'3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"כפר חסידים ב'",'3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר חרוב','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר טרומן','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר יאסיף','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר ידידיה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר יהושע','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר יונה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר יחזקאל','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר יעבץ','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר כמא','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר כנא','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר מונש','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר מימון','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר מל"ל','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר מנדא','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר מנחם','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר מסריק','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר מצר','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר מרדכי','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר נטר','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר סאלד','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר סבא','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר סילבר','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר סירקין','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר עבודה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר עזה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר עציון','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר פינס','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר קאסם','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר קיש','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר קרע','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר ראש הנקרה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר רוזנואלד (זרעית)','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר רופין','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר רות','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר שמאי','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר שמואל','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר שמריהו','5','51');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר תבור','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כפר תפוח','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כרכום','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כרם בן זמרה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כרם בן שמן','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כרם יבנה (ישיבה)','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כרם מהר"ל','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כרם שלום','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כרמי יוסף','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כרמי צור','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כרמי קטיף','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כרמיאל','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כרמייה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כרמים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'כרמל','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'לבון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'לביא','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'לבנים','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'להב','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'להבות הבשן','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'להבות חביבה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'להבים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'לוד','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'לוזית','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'לוחמי הגיטאות','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'לוטם','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'לוטן','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'לימן','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'לכיש','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'לפיד','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'לפידות','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'לקיה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מאור','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מאיר שפיה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מבוא ביתר','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מבוא דותן','7','71');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מבוא חורון','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מבוא חמה','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מבוא מודיעים','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מבואות ים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מבואות יריחו','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מבועים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מבטחים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מבקיעים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מבשרת ציון','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"מג'ד אל-כרום",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"מג'דל שמס",'2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מגאר','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מגדים','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מגדל','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מגדל העמק','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מגדל עוז','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מגדל תפן','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מגדלים','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מגידו','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מגל','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מגן','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מגן שאול','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מגשימים','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מדרך עוז','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מדרשת בן גוריון','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מדרשת רופין','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מודיעין-מכבים-רעות*','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מודיעין עילית','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מולדת','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מוצא עילית','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מוקייבלה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מורן','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מורשת','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מזור','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מזכרת בתיה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מזרח השרון מ"א 16','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מזרח השרון מ"א 18','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מזרע','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מזרעה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מחולה','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מחנה הילה*','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מחנה טלי*','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מחנה יהודית*','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מחנה יוכבד*','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מחנה יפה*','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מחנה יתיר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מחנה מרים*','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מחנה תל נוף*','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מחניים','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מחסיה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מטולה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מטע','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מי עמי','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מיטב','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מייסר','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מיצר','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מירב','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מירון','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מישר','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מיתר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מכורה','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מכחול','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מכמורת','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מכמנים','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מלאה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מלילות','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מלכייה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מלכישוע','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מנוחה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מנוף','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מנות','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מנחמיה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מנרה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מנשית זבדה','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מסד','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מסדה','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מסילות','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מסילת ציון','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מסלול','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מסעדה','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מסעודין אל-עזאזמה (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעברות','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעגלים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעגן','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעגן מיכאל','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעוז חיים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעון','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעונה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעיין ברוך','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעיין צבי','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעיליא','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעלה אדומים','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעלה אפרים','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעלה גלבוע','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעלה גמלא','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעלה החמישה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעלה לבונה','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעלה מכמש','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעלה עירון','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעלה עמוס','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעלה שומרון','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעלות-תרשיחא','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מענית','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מערב השרון מ"א 16','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מערב השרון מ"א 18','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מערב השרון מ"א 19','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מעש','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מפלסים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מפעלי אבשלו"ם','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מפעלי ברקן','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מפעלי גליל עליון','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מפעלי גרנות','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מפעלי העמק (יזרעאל)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מפעלי חבל מודיעים','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מפעלי חפר','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מפעלי ים המלח(סדום)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מפעלי כנות','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מפעלי מישור רותם','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מפעלי מעון','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מפעלי נחם הרטוב','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מפעלי צומת מלאכי','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מפעלי צין - ערבה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מפעלי צמח','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מפעלי שאן','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מצדות יהודה','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מצובה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מצליח','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מצפה','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מצפה אבי"ב','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מצפה אילן','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מצפה יריחו','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מצפה נטופה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מצפה רמון','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מצפה שלם','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מצר','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מקווה ישראל','5','53');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מרגליות','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מרום גולן','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מרחב עם','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מרחביה (מושב)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מרחביה (קיבוץ)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מרכז אזורי כדורי','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מרכז אזורי מרום הגליל','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מרכז אזורי משגב','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מרכז אזורי שוהם','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מרכז כ"ח','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מרכז מיר"ב*','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מרכז שפירא','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'משאבי שדה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'משגב דב','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'משגב עם','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'משהד','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'משואה','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'משואות יצחק','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'משכיות','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'משמר איילון','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'משמר דוד','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'משמר הירדן','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'משמר הנגב','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'משמר העמק','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'משמר השבעה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'משמר השרון','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'משמרות','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'משמרת','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'משען','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מתן','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מתת','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'מתתיהו','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נאות גולן','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נאות הכיכר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נאות חובב','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נאות מרדכי','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נאות סמדר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נאעורה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נבטים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נגבה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נגוהות','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נהורה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נהלל','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נהרייה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נוב','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נוגה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה אבות','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה אור','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה אטי"ב','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה אילן','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה אילן*','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה איתן','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה דניאל','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה זוהר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה זיו','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה חריף','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה ים','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה ימין','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה ירק','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה מבטח','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה מיכאל','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה צוף','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נווה שלום','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נועם','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נוף איילון','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נוף הגליל','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נופים','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נופית','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נופך','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נוקדים','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נורדייה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נורית','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נחושה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נחל יפתחאל מ"א 3','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נחל עוז','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נחל תבור מ"א 8','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נחלה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נחליאל','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נחלים','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נחם','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נחף','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נחשולים','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נחשון','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נחשונים','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נטועה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נטור','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נטע','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נטעים','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נטף','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניין','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניל"י','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניצן','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"ניצן ב'",'6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניצנה (קהילת חינוך)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניצני סיני','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניצני עוז','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניצנים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניר אליהו','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניר בנים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניר גלים','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניר דוד (תל עמל)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניר ח"ן','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניר יפה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניר יצחק','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניר ישראל','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניר משה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניר עוז','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניר עם','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניר עציון','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניר עקיבא','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ניר צבי','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נירים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נירית','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נמל תעופה בן-גוריון','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נמרוד','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נס הרים','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נס עמים','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נס ציונה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נעורים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נעלה','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נעמ"ה','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נען','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נערן','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נפת בית לחם','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נפת בית לחם מ"א 76','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"נפת ג'נין",'7','71');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נפת חברון','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נפת חברון מ"א 78','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נפת טול כרם','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נפת טול כרם  מ"א 72','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נפת ירדן','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נפת ירדן מ"א 74','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נפת ירדן מ"א 75','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נפת ראמאללה ','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נפת ראמאללה מ"א  73','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נפת שכם','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נפת שכם מ"א 72','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נצאצרה (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נצר חזני','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נצר סרני','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נצרת','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נשר','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נתיב הגדוד','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נתיב הל"ה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נתיב העשרה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נתיב השיירה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נתיבות','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'נתניה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"סאג'ור",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'סאסא','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'סביון','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'סגולה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'סואעד (חמרייה)','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'סואעד (כמאנה) (שבט)','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'סולם','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'סוסיה','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'סופה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"סח'נין",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'סייד (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'סלמה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'סלעית','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'סמר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'סנסנה','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'סעד','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'סעוה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'סער','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ספיר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'סתרייה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"ע'ג'ר",'2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עבדון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עברון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עגור','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עד הלום','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עדי','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עדנים','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עוזה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עוזייר','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עולש','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עומר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עופר','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עוצם','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עוקבי (בנו עוקבה) (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עזוז','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עזר','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עזריאל','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עזריה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עזריקם','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עטאוונה (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עטרת','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עידן','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עידן הנגב','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עיילבון','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עיינות','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עילוט','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין איילה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין אל-אסד','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין גב','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין גדי','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין דור','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין הבשור','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין הוד','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין החורש','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין המפרץ','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין הנצי"ב','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין העמק','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין השופט','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין השלושה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין ורד','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין זיוון','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין חוד','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין חצבה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין חרוד (איחוד)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין חרוד (מאוחד)','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין יהב','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין יעקב','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין כרם-בי"ס חקלאי','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין כרמל','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין מאהל','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין נקובא','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין עירון','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין צורים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין קנייא','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין ראפה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין שמר','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין שריד','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עין תמר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עינת','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עיר אובות','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עכו','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עלומים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עלי','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עלי זהב','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עלמה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עלמון','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמוקה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמיחי','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמינדב','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמיעד','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמיעוז','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמיקם','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמיר','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמנואל','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמק בית שאן מ"א 7','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמק בית שאן של"ש','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמק חולה מ"א 1','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמק חולה מ"א 55','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמק חולה של"ש','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמק חפר מזרח מ"א 16','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמק חרוד מ"א 8','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמק חרוד של"ש','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמק יזרעאל מ"א 13','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמק יזרעאל מ"א 8','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמק יזרעאל מ"א 9','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עמקה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ענב','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עספיא','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עפולה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עפרה','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עץ אפרים','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עצמון שגב','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עראבה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עראמשה*','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ערב אל נעים','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ערד','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ערוגות','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ערערה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ערערה-בנגב','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עשרת','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עתלית','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'עתניאל','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פארן','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פארק הירדן מ"א 6','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פארק תעשיות ספירים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פדואל','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פדויים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פדיה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פוריידיס','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פורייה - כפר עבודה','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פורייה - נווה עובד','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פורייה עילית','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פורת','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פטיש','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פלך','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פלמחים','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פני חבר','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פסגות','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פסוטה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פעמי תש"ז','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פצאל','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פקיעין (בוקייעה)','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פקיעין חדשה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פרדס חנה-כרכור','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פרדסייה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פרוד','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פרזון','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פרי גן','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פתח תקווה','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'פתחיה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צאלים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צביה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צבעון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צובה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צוחר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צופייה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צופים','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צופית','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צופר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צוקי ים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צוקים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צור הדסה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צור יצחק','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צור משה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צור נתן','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צוריאל','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צורית','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ציפורי','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צלפון','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צנדלה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צפרייה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צפרירים','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צפת','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צרופה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'צרעה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קבועה (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קבוצת יבנה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קדומים','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קדימה-צורן','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קדמה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קדמת צבי','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קדר','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קדרון','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קדרים','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קודייראת א-צאנע (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קוואעין (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קוממיות','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קורנית','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קטורה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קיסריה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קלחים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קליה','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קלנסווה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קלע','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קציר','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קצר א-סר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קצרין','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קריית אונו','5','52');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קריית ארבע','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קריית אתא','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קריית ביאליק','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קריית גת','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קריית חינוך מרחבים*','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קריית טבעון','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קריית ים','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קריית יערים','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קריית יערים (מוסד)','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קריית מוצקין','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קריית מלאכי','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קריית נטפים','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קריית ענבים','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קריית עקרון','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קריית שלמה','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קריית שמונה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קרית חינוך עזתה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קרית תעופה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קרני שומרון','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'קשת','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ראמה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ראס אל-עין','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ראס עלי','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ראש העין','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ראש פינה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ראש צורים','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ראשון לציון','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רבבה','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רבדים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רביבים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רביד','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רגבה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רגבים','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רהט','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רווחה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רוויה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רוח מדבר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רוחמה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רומאנה','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רומת הייב','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רועי','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רותם','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רחוב','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רחובות','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רחלים','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ריחאנייה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ריחן','7','71');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'ריינה','2','25');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רימונים','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רינתיה','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רכסים','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רם-און','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמות','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמות השבים','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמות מאיר','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמות מנשה','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמות נפתלי','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמלה','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמת גן','5','52');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמת דוד','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמת הכובש','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמת השופט','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמת השרון','5','51');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמת יוחנן','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמת ישי','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמת כוכב מ"א 7','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמת כוכב מ"א 8','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמת כוכב מ"א 9','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמת כוכב של"ש','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמת מגשימים','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמת מנשה מ"א 13','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמת מנשה של"ש','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמת צבי','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמת רזיאל','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רמת רחל','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רנן','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רעים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רעננה','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רקפת','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רשפון','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רשפים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'רתמים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שאר ישוב','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שבי דרום','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שבי ציון','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שבי שומרון','7','72');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שבלי - אום אל-גנם','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שגב-שלום','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדה אילן','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדה אליהו','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדה אליעזר','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדה בוקר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדה דוד','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדה ורבורג','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדה יואב','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדה יעקב','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדה יצחק','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדה משה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדה נחום','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדה נחמיה','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדה ניצן','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדה עוזיהו','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדה צבי','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדות ים','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדות מיכה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדי אברהם','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדי חמד','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדי תרומות','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדמה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדמות דבורה','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדמות מחולה','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שדרות','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שואבה','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שובה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שובל','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שוהם','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שומרה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שומרייה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שוקדה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שורש','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שורשים','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שושנת העמקים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שזור','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שחר','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שחרות','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שיבולים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שיטים','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N"שייח' דנון",'2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שילה','7','74');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שילת','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שכניה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שלווה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שלווה במדבר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שלוחות','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שלומי','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שלומית','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שלומציון','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שמיר','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שמעה','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שמרת','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שמשית','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שני','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שניר','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שעב','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שעל','2','29');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שעלבים','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שער אפרים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שער הגולן','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שער העמקים','3','31');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שער מנשה','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שערי תקווה','7','73');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שפיים','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שפיר','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שפלת יהודה מ"א 26','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שפלת יהודה של"ש','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שפר','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שפרעם','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שקד','7','71');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שקף','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שרונה','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שריגים (לי-און)','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שריד','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שרשרת','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שתולה','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'שתולים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תאשור','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תדהר','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תובל','2','24');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תומר','7','75');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תושייה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תימורים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תירוש','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תל אביב -יפו','5','51');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תל חי (מכללה)','2','21');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תל יוסף','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תל יצחק','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תל מונד','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תל עדשים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תל קציר','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תל שבע','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תל תאומים','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תלם','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תלמי אליהו','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תלמי אלעזר','3','32');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תלמי ביל"ו','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תלמי יוסף','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תלמי יחיאל','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תלמי יפה','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תלמים','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תמרת','2','23');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תנובות','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תעוז','1','11');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תעשיון בינימין*','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תעשיון השרון','4','41');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תעשיון חבל יבנה','4','44');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תעשיון חצב*','4','42');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תעשיון מבצע*','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תעשיון מיתרים','7','77');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תעשיון צריפין','4','43');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תעשיון ראם*','6','61');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תעשיון שח"ק','7','71');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תעשיות גליל תחתון','2','22');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תפרח','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תקומה','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תקוע','7','76');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תראבין א-צאנע (שבט)','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תרבין א-צאנע (יישוב)*','6','62');
INSERT INTO `refua_delivery`.`cities` (`name`,  `district_fk`,  `subdistrict_fk`) VALUES (N'תרום','1','11');


CREATE TABLE `refua_delivery`.`user2city` (
  `id` INT NOT NULL,
  `user_id` INT NOT NULL,
  `city_id` INT NOT NULL,
  PRIMARY KEY (`id`));

ALTER TABLE `refua_delivery`.`user2city` 
ADD INDEX `user_id_idx` (`user_id` ASC),
ADD INDEX `fk_city_id_idx` (`city_id` ASC);
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
ADD INDEX `parcel_city_fk_idx` (`city` ASC);
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

ALTER TABLE `refua_delivery`.`users`
ADD COLUMN `new` TINYINT(1) NULL DEFAULT 1 AFTER `active`;


ALTER TABLE `refua_delivery`.`parcel` 
ADD COLUMN `tree` VARCHAR(100) NULL DEFAULT NULL AFTER `need_delivery`;

ALTER TABLE `refua_delivery`.`parcel` 
DROP INDEX `search_fulltext` ,
ADD FULLTEXT INDEX `search_fulltext` (`phone`, `customer_name`, `customer_id`, `tree`) WITH PARSER `ngram`;






