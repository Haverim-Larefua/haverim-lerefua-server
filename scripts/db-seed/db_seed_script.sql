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
  `id` int(11) NOT NULL AUTO_INCREMENT,
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
