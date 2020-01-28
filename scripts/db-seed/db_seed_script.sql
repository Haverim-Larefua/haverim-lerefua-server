create schema refua_delivery;
use  refua_delivery;

CREATE TABLE delivery_days (
  id int(11) NOT NULL AUTO_INCREMENT,
  description varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;


CREATE TABLE roles (
   id int(11) NOT NULL AUTO_INCREMENT,
   description varchar(20) DEFAULT NULL,
   PRIMARY KEY (id)
) ENGINE=InnoDB;


CREATE TABLE users (
  id int(11) NOT NULL AUTO_INCREMENT,
  first_name varchar(20) DEFAULT NULL,
  last_name varchar(30) DEFAULT NULL,
  address varchar(100) DEFAULT NULL,
  delivery_area varchar(10) DEFAULT NULL,
  delivery_days_fk int(11) DEFAULT NULL,
  phone varchar(20) DEFAULT NULL,
  role_fk int(11) DEFAULT NULL,
  PRIMARY KEY (id),
  KEY user_role_fk_idx (role_fk),
  KEY user_delivery_days_fk_idx (delivery_days_fk),
  CONSTRAINT user_delivery_days_fk FOREIGN KEY (delivery_days_fk) REFERENCES delivery_days (id),
  CONSTRAINT user_role_fk FOREIGN KEY (role_fk) REFERENCES roles (id)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE parcel (
  id int(11) NOT NULL AUTO_INCREMENT,
  no int(11) DEFAULT NULL,
  destination varchar(50) DEFAULT NULL,
  destination_address varchar(50) DEFAULT NULL,
  destination_phone varchar(100) DEFAULT NULL,
  address varchar(100) DEFAULT NULL,
  userId int(11) DEFAULT NULL,
  comments varchar(100) DEFAULT NULL,
  update_date timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY parcel_user_fk_idx (userId),
  CONSTRAINT parcel_user_fk FOREIGN KEY (userId) REFERENCES users (id)
) ENGINE=InnoDB;

CREATE TABLE parcel_tracking (
  id int(11) NOT NULL AUTO_INCREMENT,
  no int(11) DEFAULT NULL,
  status_date date DEFAULT NULL,
  destination_address varchar(50) DEFAULT NULL,
  destination_phone varchar(100) DEFAULT NULL,
  address varchar(100) DEFAULT NULL,
  delivery_person varchar(100) DEFAULT NULL,
  delivery_person_phone varchar(100) DEFAULT NULL,
  comments varchar(100) DEFAULT NULL,
  parcel_fk int(11) DEFAULT NULL,
  PRIMARY KEY (id),
  KEY parcel_tacking_parcel_idx (parcel_fk),
  CONSTRAINT parcel_tacking_parcel FOREIGN KEY (parcel_fk) REFERENCES parcel (id)
) ENGINE=InnoDB;

CREATE TABLE regions (
   id int(11) NOT NULL AUTO_INCREMENT,
   description varchar(20) DEFAULT NULL,
   PRIMARY KEY (id)
) ENGINE=InnoDB;






