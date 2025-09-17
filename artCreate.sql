-- =========================================================
-- Art Collection Database (MySQL 8.0+)
-- =========================================================


 CREATE DATABASE IF NOT EXISTS art_collection
   DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
USE art_collection;

-- ---------------------------------------------------------
-- Safety: drop tables in FK-safe order
-- ---------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS exhibition_artworks;
DROP TABLE IF EXISTS collection_items;
DROP TABLE IF EXISTS media_files;
DROP TABLE IF EXISTS restorations;
DROP TABLE IF EXISTS ownership;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS exhibitions;
DROP TABLE IF EXISTS collections;
DROP TABLE IF EXISTS artworks;
DROP TABLE IF EXISTS locations;
DROP TABLE IF EXISTS owners;
DROP TABLE IF EXISTS artists;
DROP TABLE IF EXISTS ownership;

SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------
-- Core reference tables
-- ---------------------------------------------------------

CREATE TABLE artists (
  artist_id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  full_name           VARCHAR(255) NOT NULL,
  nationality         VARCHAR(120),
  birth_date          DATE,
  death_date          DATE,
  biography           TEXT,
  PRIMARY KEY (artist_id),
  KEY idx_artists_full_name (full_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE owners (
  owner_id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name                VARCHAR(255) NOT NULL,
  owner_type          ENUM('Person','Institution') NOT NULL DEFAULT 'Person',
  contact_email       VARCHAR(255),
  phone               VARCHAR(50),
  address             TEXT,
  PRIMARY KEY (owner_id),
  KEY idx_owners_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE locations (
  location_id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name                VARCHAR(255) NOT NULL,
  address             TEXT,
  room                VARCHAR(100),
  shelf               VARCHAR(100),
  PRIMARY KEY (location_id),
  KEY idx_locations_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- Artworks and groupings
-- ---------------------------------------------------------

CREATE TABLE artworks (
  artwork_id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  title               VARCHAR(255) NOT NULL,
  medium              VARCHAR(150),
  year_created        INT,
  dimensions          VARCHAR(150),
  primary_artist_id   INT UNSIGNED,
  current_location_id INT UNSIGNED,
  current_owner_id    INT UNSIGNED,
  notes               TEXT,
  PRIMARY KEY (artwork_id),
  KEY idx_artworks_title (title),
  KEY idx_artworks_primary_artist (primary_artist_id),
  KEY idx_artworks_current_location (current_location_id),
  KEY idx_artworks_current_owner (current_owner_id),
  CONSTRAINT fk_artworks_artist
    FOREIGN KEY (primary_artist_id)
    REFERENCES artists(artist_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT fk_artworks_location
    FOREIGN KEY (current_location_id)
    REFERENCES locations(location_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT fk_artworks_owner
    FOREIGN KEY (current_owner_id)
    REFERENCES owners(owner_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE collections (
  collection_id       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name                VARCHAR(255) NOT NULL,
  description         TEXT,
  owner_id            INT UNSIGNED,
  PRIMARY KEY (collection_id),
  KEY idx_collections_name (name),
  KEY idx_collections_owner (owner_id),
  CONSTRAINT fk_collections_owner
    FOREIGN KEY (owner_id)
    REFERENCES owners(owner_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Junction: which artwork is in which collection
CREATE TABLE collection_items (
  collection_id       INT UNSIGNED NOT NULL,
  artwork_id          INT UNSIGNED NOT NULL,
  date_added          DATE,
  item_notes          TEXT,
  PRIMARY KEY (collection_id, artwork_id),
  KEY idx_ci_artwork (artwork_id),
  CONSTRAINT fk_ci_collection
    FOREIGN KEY (collection_id)
    REFERENCES collections(collection_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_ci_artwork
    FOREIGN KEY (artwork_id)
    REFERENCES artworks(artwork_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- Exhibitions and displayed works
-- ---------------------------------------------------------

CREATE TABLE exhibitions (
  exhibition_id       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name                VARCHAR(255) NOT NULL,
  start_date          DATE,
  end_date            DATE,
  location_id         INT UNSIGNED,
  description         TEXT,
  PRIMARY KEY (exhibition_id),
  KEY idx_exhibitions_name (name),
  KEY idx_exhibitions_dates (start_date, end_date),
  KEY idx_exhibitions_location (location_id),
  CONSTRAINT fk_exhibitions_location
    FOREIGN KEY (location_id)
    REFERENCES locations(location_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Junction: which artworks were shown at which exhibition
CREATE TABLE exhibition_artworks (
  exhibition_id       INT UNSIGNED NOT NULL,
  artwork_id          INT UNSIGNED NOT NULL,
  display_label       VARCHAR(255),
  notes               TEXT,
  PRIMARY KEY (exhibition_id, artwork_id),
  KEY idx_ea_artwork (artwork_id),
  CONSTRAINT fk_ea_exhibition
    FOREIGN KEY (exhibition_id)
    REFERENCES exhibitions(exhibition_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_ea_artwork
    FOREIGN KEY (artwork_id)
    REFERENCES artworks(artwork_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- Ownership, transactions, ownership
-- ---------------------------------------------------------

CREATE TABLE transactions (
  transaction_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  artwork_id          INT UNSIGNED NOT NULL,
  txn_date            DATE NOT NULL,
  txn_type            ENUM('Purchase','Sale','LoanIn','LoanOut','Transfer') NOT NULL,
  from_owner_id       INT UNSIGNED NULL,
  to_owner_id         INT UNSIGNED NULL,
  price               DECIMAL(12,2) NULL,
  currency            CHAR(3) NULL, -- ISO 4217, e.g., 'USD', 'EUR'
  notes               TEXT,
  PRIMARY KEY (transaction_id),
  KEY idx_txn_artwork (artwork_id),
  KEY idx_txn_date (txn_date),
  KEY idx_txn_from_owner (from_owner_id),
  KEY idx_txn_to_owner (to_owner_id),
  CONSTRAINT fk_txn_artwork
    FOREIGN KEY (artwork_id)
    REFERENCES artworks(artwork_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_txn_from_owner
    FOREIGN KEY (from_owner_id)
    REFERENCES owners(owner_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT fk_txn_to_owner
    FOREIGN KEY (to_owner_id)
    REFERENCES owners(owner_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT chk_txn_price_positive CHECK (price IS NULL OR price >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE ownership (
  ownership_id       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  artwork_id          INT UNSIGNED NOT NULL,
  owner_id            INT UNSIGNED NOT NULL,
  acquired_date       DATE,
  relinquished_date   DATE,
  source_document     VARCHAR(255),
  notes               TEXT,
  PRIMARY KEY (ownership_id),
  KEY idx_prov_artwork (artwork_id),
  KEY idx_prov_owner (owner_id),
  CONSTRAINT fk_prov_artwork
    FOREIGN KEY (artwork_id)
    REFERENCES artworks(artwork_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_prov_owner
    FOREIGN KEY (owner_id)
    REFERENCES owners(owner_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT chk_prov_dates CHECK (
    relinquished_date IS NULL OR acquired_date IS NULL OR relinquished_date >= acquired_date
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- Conservation & media
-- ---------------------------------------------------------

CREATE TABLE restorations (
  restoration_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  artwork_id          INT UNSIGNED NOT NULL,
  restoration_date    DATE,
  conservator         VARCHAR(255),
  restoration_type    VARCHAR(150),
  details             TEXT,
  condition_before    VARCHAR(255),
  condition_after     VARCHAR(255),
  cost                DECIMAL(12,2),
  currency            CHAR(3),
  PRIMARY KEY (restoration_id),
  KEY idx_restorations_artwork (artwork_id),
  CONSTRAINT fk_restorations_artwork
    FOREIGN KEY (artwork_id)
    REFERENCES artworks(artwork_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT chk_restoration_cost CHECK (cost IS NULL OR cost >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE media_files (
  media_id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  artwork_id          INT UNSIGNED NULL,
  artist_id           INT UNSIGNED NULL,
  media_type          ENUM('Image','Video','Doc') NOT NULL DEFAULT 'Image',
  title               VARCHAR(255),
  file_url            VARCHAR(768) NOT NULL,
  captured_date       DATE,
  copyright_holder    VARCHAR(255),
  notes               TEXT,
  PRIMARY KEY (media_id),
  KEY idx_media_artwork (artwork_id),
  KEY idx_media_artist (artist_id),
  KEY idx_media_type (media_type),
  UNIQUE KEY uq_media_file_url (file_url),
  CONSTRAINT fk_media_artwork
    FOREIGN KEY (artwork_id)
    REFERENCES artworks(artwork_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT fk_media_artist
    FOREIGN KEY (artist_id)
    REFERENCES artists(artist_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;