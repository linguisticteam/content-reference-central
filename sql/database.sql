START TRANSACTION;

DROP DATABASE IF EXISTS `content_reference_central`;
CREATE DATABASE `content_reference_central`
DEFAULT CHARACTER SET 'utf8'
DEFAULT COLLATE 'utf8_unicode_ci';

USE `content_reference_central`;

/*--------------------------------*/
/*----   TABLES AND INSERTS   ----*/
/*--------------------------------*/

CREATE TABLE `resource` (
	`id` INT AUTO_INCREMENT,
	`resource_type_id` INT REFERENCES `resource_type` (`id`),
	`title` TEXT,
	`description` TEXT,
	PRIMARY KEY (id)
);

CREATE TABLE `element` (
	`id` INT AUTO_INCREMENT,
	`resource_id` INT REFERENCES `resource` (`id`),
	`element_type_id` INT REFERENCES `element_type` (`id`),
	`title` TEXT,
	`index` INT,
	`url` TEXT,
	PRIMARY KEY (id)
);

CREATE TABLE `keyword_xref` (
	`id` INT AUTO_INCREMENT,
	`resource_id` INT REFERENCES `resource` (`id`),
	`keyword_id` INT REFERENCES `keyword` (`id`),
	PRIMARY KEY(id)
);

CREATE TABLE `keyword` (
	`id` INT AUTO_INCREMENT,
	`name` TINYTEXT,
	PRIMARY KEY(id)
);

CREATE TABLE `entity` (
	`id` INT AUTO_INCREMENT,
	`resource_id` INT REFERENCES `resource` (`id`),
	`entity_type_id` INT REFERENCES `entity_type` (`id`),
	`full_name` TEXT,
	PRIMARY KEY (id)
);

CREATE TABLE `entity_type` (
	`id` INT AUTO_INCREMENT,
	`name` TINYTEXT,
	PRIMARY KEY (id)
);

INSERT INTO `entity_type` (name) VALUES
	('PERSON'),
	('ORGANIZATION')
;

CREATE TABLE `resource_type` (
	`id` INT AUTO_INCREMENT,
	`name` TINYTEXT,
	PRIMARY KEY (id)
);

INSERT INTO `resource_type` (name) VALUES
	('TUTORIAL'),
	('DOCUMENTATION')
;

CREATE TABLE `element_type` (
	`id` INT AUTO_INCREMENT,
	`name` TINYTEXT,
	PRIMARY KEY (id)
);

INSERT INTO `element_type` (name) VALUES
	('PRIMARY'),
	('PART'),
	('LESSON'),
	('CHAPTER')
;

/*-------------------*/
/*----   VIEWS   ----*/
/*-------------------*/

/*-------------------*/
/*---  FUNCTIONS  ---*/
/*-------------------*/

/* Function which splits a string based on a supplied delimiter and string position */

CREATE FUNCTION SPLIT_STR(
  string TEXT,
  delim VARCHAR(12),
  string_position INT
)
RETURNS VARCHAR(255)
RETURN REPLACE(SUBSTRING(SUBSTRING_INDEX(string, delim, string_position),
       LENGTH(SUBSTRING_INDEX(string, delim, string_position -1)) + 1),
       delim, '');


/*-------------------------------*/
/*----   STORED PROCEDURES   ----*/
/*-------------------------------*/

DELIMITER $$



/* Stored procedure to insert an single-element resource */
CREATE PROCEDURE insert_resource (IN param_title TEXT, IN param_resource_type TEXT, IN param_url TEXT, IN param_description TEXT)
BEGIN
                INSERT INTO `resource` (
                    `resource_type_id`,
                    `title`,
                    `description`
                )
                VALUES (
                    (SELECT `id` FROM `resource_type` WHERE `name` = param_resource_type),
                    param_title,
                    param_description
                );

                INSERT INTO `element` (
                    `resource_id`,
                    `url`
                )
                VALUES (
                    (SELECT `id` FROM `resource` WHERE `title` = param_title),
                    param_url
                );
END $$

/* Procedure to insert new keywords and keyword-resource relationships */
CREATE PROCEDURE insert_keywords (IN param_keywords TINYTEXT, IN param_resource_title TEXT)
BEGIN
        DECLARE string_position INT;
        DECLARE single_keyword VARCHAR(255);

        SET string_position = 1;
        
        keywords_loop: LOOP

            /* Split the keywords string on commas */
            SET single_keyword = SPLIT_STR(param_keywords, ',', string_position);
            
            IF single_keyword = ''
                THEN LEAVE keywords_loop;
            ELSE

                /* Check if the keyword is a new one and insert it if so */
                IF
                    (SELECT COUNT(`name`) FROM `keyword` WHERE `name` = single_keyword) = 0
                THEN
                    INSERT INTO `keyword` (`name`) VALUES (single_keyword);
                END IF;

                    /* Insert the keyword-resource relationship */
                    INSERT INTO `keyword_xref` (
                        `resource_id`,
                        `keyword_id`)
                    VALUES (
                        (SELECT `id` FROM `resource` WHERE `title` = param_resource_title),
                        (SELECT `id` FROM `keyword` WHERE `name` = single_keyword)
                    );

                    /* Increment the string position for SPLIT_STR() */
                    SET string_position = string_position + 1;
            END IF;

        END LOOP keywords_loop;
END $$

/* Stored procedure to insert authors */
CREATE PROCEDURE insert_authors(IN param_authors VARCHAR(255), IN param_resource_title TEXT)
BEGIN
    DECLARE string_position INT;
    DECLARE author_array VARCHAR(255);
    DECLARE resource_author VARCHAR(255);
    DECLARE author_type VARCHAR(255);

    SET string_position = 1;

    author_loop: LOOP
            /* Divide the author_array in sections,
            where each section is a Resource Author-Author Type couple
            Note: SPLIT_STR() is a user defined function which splits
            a string on a supplied delimiter and position */
            SET author_array = SPLIT_STR(param_authors, '|', string_position);

            IF author_array = ''
                    THEN LEAVE author_loop;
            ELSE
                    /* Separate the Resource Author-Author Type couple */
                    SET resource_author = SPLIT_STR(author_array, ',', 1);
                    SET author_type = SPLIT_STR(author_array, ',', 2);

                    /* Insert the separated values in the table */
                    INSERT INTO `entity`(
                            `resource_id`,
                            `entity_type_id`,
                            `full_name`
                    )
                    VALUES (
                            (SELECT `id` FROM `resource` WHERE `title` = param_resource_title),
                            (SELECT `id` FROM `entity_type` WHERE `name` = author_type),
                            resource_author
                    );

                    SET string_position = string_position + 1;
            END IF;
    END LOOP author_loop;
END $$

DELIMITER ;

COMMIT
