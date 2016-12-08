START TRANSACTION;
-- Create the database --
CREATE DATABASE IF NOT EXISTS `bio466`;

-- Use bio466 db --
USE `bio466`;

-- Drop any old tables --
DROP TABLE IF EXISTS `genes`;
DROP TABLE IF EXISTS `rna`;
DROP TABLE IF EXISTS `transcripts`;
DROP TABLE IF EXISTS `genome`;

-- Create tables --
CREATE TABLE `genome` (
	`filename` varchar(128) primary key not null,
	`file_type` varchar(16) not null,
	`genome_build` varchar(64) not null,
	`accession` varchar(64) not null,
	`url` varchar(128)
) ENGINE=InnoDB;

CREATE TABLE `genes` (
	`filename` varchar(128) not null,
	`id` varchar(32) not null,
	`name` varchar(64) not null,
	`type` varchar(32) not null,
	`start` int not null,
	`end` int not null,
	`strand` char(1) not null,
	`desc` varchar(250),
	PRIMARY KEY (`filename`, `id`),
	FOREIGN KEY fk_genes_filename (`filename`) REFERENCES genome (`filename`)
	ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE INDEX `genes_name` ON `genes` (`name`);
CREATE INDEX `genes_type` ON `genes` (`type`);
CREATE INDEX `genes_strand` ON `genes` (`strand`);

CREATE TABLE `rna` (
	`filename` varchar(128) not null,
	`id` varchar(32) not null,
	`type` varchar(8) not null,
	`parent` varchar(32),
	`start` int not null,
	`end` int not null,
	`evidence` varchar(250),
	`product` varchar(250),
	PRIMARY KEY (`filename`, `id`),
	FOREIGN KEY fk_rna_filename (`filename`) REFERENCES genome (`filename`)
	ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE INDEX `rna_type` ON `rna` (`type`);
CREATE INDEX `rna_parent` ON `rna` (`parent`);

CREATE TABLE `transcripts` (
	`filename` varchar(128) not null,
	`id` varchar(32) not null,
	`parent` varchar(32) not null,
	`start` int not null,
	`end` int not null,
	`evidence` varchar(250),
	`product` varchar(250),
	PRIMARY KEY (`filename`, `id`),
	FOREIGN KEY fk_transcripts_filename (`filename`) REFERENCES genome (`filename`)
	ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE INDEX `transcripts_parent` ON `transcripts` (`parent`);

COMMIT;