-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
-- -----------------------------------------------------
-- Schema refua_delivery
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema refua_delivery
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `refua_delivery` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci ;
USE `refua_delivery` ;

-- -----------------------------------------------------
-- Table `refua_delivery`.`delivery_days`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `refua_delivery`.`delivery_days` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `description` VARCHAR(45) NULL DEFAULT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB
AUTO_INCREMENT = 6
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `refua_delivery`.`roles`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `refua_delivery`.`roles` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `description` VARCHAR(20) NULL DEFAULT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `refua_delivery`.`users`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `refua_delivery`.`users` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `first_name` VARCHAR(20) NULL DEFAULT NULL,
  `last_name` VARCHAR(30) NULL DEFAULT NULL,
  `address` VARCHAR(100) NULL DEFAULT NULL,
  `delivery_area` VARCHAR(10) NULL DEFAULT NULL,
  `deliveryDaysId` INT(11) NULL DEFAULT NULL,
  `phone` VARCHAR(20) NULL DEFAULT NULL,
  `role_fk` INT(11) NULL DEFAULT NULL,
  `notes` VARCHAR(100) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `user_role_fk_idx` (`role_fk` ASC) VISIBLE,
  INDEX `user_delivery_days_fk_idx` (`deliveryDaysId` ASC) VISIBLE,
  CONSTRAINT `user_delivery_days_fk`
    FOREIGN KEY (`deliveryDaysId`)
    REFERENCES `refua_delivery`.`delivery_days` (`id`),
  CONSTRAINT `user_role_fk`
    FOREIGN KEY (`role_fk`)
    REFERENCES `refua_delivery`.`roles` (`id`))
ENGINE = InnoDB
AUTO_INCREMENT = 13
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `refua_delivery`.`parcel`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `refua_delivery`.`parcel` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `no` INT(11) NULL DEFAULT NULL,
  `destination` VARCHAR(50) NULL DEFAULT NULL,
  `destination_address` VARCHAR(50) NULL DEFAULT NULL,
  `destination_phone` VARCHAR(100) NULL DEFAULT NULL,
  `address` VARCHAR(100) NULL DEFAULT NULL,
  `userId` INT(11) NULL DEFAULT NULL,
  `comments` VARCHAR(100) NULL DEFAULT NULL,
  `update_date` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `parcel_user_fk_idx` (`userId` ASC) VISIBLE,
  CONSTRAINT `parcel_user_fk`
    FOREIGN KEY (`userId`)
    REFERENCES `refua_delivery`.`users` (`id`))
ENGINE = InnoDB
AUTO_INCREMENT = 6
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `refua_delivery`.`parcel_tracking`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `refua_delivery`.`parcel_tracking` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `no` INT(11) NULL DEFAULT NULL,
  `status_date` DATE NULL DEFAULT NULL,
  `destination_address` VARCHAR(50) NULL DEFAULT NULL,
  `destination_phone` VARCHAR(100) NULL DEFAULT NULL,
  `address` VARCHAR(100) NULL DEFAULT NULL,
  `delivery_person` VARCHAR(100) NULL DEFAULT NULL,
  `delivery_person_phone` VARCHAR(100) NULL DEFAULT NULL,
  `comments` VARCHAR(100) NULL DEFAULT NULL,
  `parcel_fk` INT(11) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `parcel_tacking_parcel_idx` (`parcel_fk` ASC) VISIBLE,
  CONSTRAINT `parcel_tacking_parcel`
    FOREIGN KEY (`parcel_fk`)
    REFERENCES `refua_delivery`.`parcel` (`id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- -----------------------------------------------------
-- Table `refua_delivery`.`regions`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `refua_delivery`.`regions` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `description` VARCHAR(20) NULL DEFAULT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
