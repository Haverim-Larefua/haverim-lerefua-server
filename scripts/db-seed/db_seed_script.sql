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
  `deleted` boolean DEFAULT false,
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
