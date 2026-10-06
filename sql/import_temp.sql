-------------------------------------------------------------------------------
-- import_temp.sql (version corrigée)
-- 1) Supprimer les tables temporaires
-- 2) Les recréer avec le bon schéma (sans PK/FK)
-- 3) Importer les CSV via COPY en listant les colonnes dans l’ordre exact
-------------------------------------------------------------------------------

-- TEMP TABLE GENRE
DROP TABLE IF EXISTS Temp_Genre CASCADE;
CREATE TABLE Temp_Genre (
    genre_id SERIAL PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);
\COPY Temp_Genre(genre_id, libelle) FROM 'sql/data/Genre.csv' WITH (FORMAT csv, HEADER);

-- TEMP TABLE ORIENTATION
DROP TABLE IF EXISTS Temp_Orientation CASCADE;
CREATE TABLE Temp_Orientation (
    orientation_id SERIAL PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);
\COPY Temp_Orientation(orientation_id, libelle) FROM 'sql/data/Orientation.csv' WITH (FORMAT csv, HEADER);

-- TEMP TABLE UTILISATEURS
DROP TABLE IF EXISTS Temp_Utilisateur CASCADE;
CREATE TABLE Temp_Utilisateur (
    pseudo          VARCHAR(50),
    nom             VARCHAR(50),
    prenom          VARCHAR(50),
    ville           VARCHAR(100),
    pays            VARCHAR(100),
    taille          NUMERIC(5,2),
    poids           NUMERIC(5,2),
    couleur_yeux    VARCHAR(30),
    abonne          BOOLEAN,
    genre_id        INT,
    orientation_id  INT
);
\COPY Temp_Utilisateur(pseudo, nom, prenom, ville, pays, taille, poids, couleur_yeux, abonne, genre_id, orientation_id) FROM 'sql/data/Utilisateur.csv' WITH (FORMAT csv, HEADER);


-- TEMP TABLE LIEU
DROP TABLE IF EXISTS Temp_Lieu CASCADE;
CREATE TABLE Temp_Lieu (
    lieu_id    INT,
    nom        VARCHAR(100),
    adresse    VARCHAR(255),
    type_lieu  VARCHAR(50),
    latitude   DECIMAL(9,6),
    longitude  DECIMAL(9,6)
);
\COPY Temp_Lieu(lieu_id, nom, adresse, type_lieu, latitude, longitude) FROM 'sql/data/Lieu.csv' WITH (FORMAT csv, HEADER);


-- TEMP TABLE EVENEMENT
DROP TABLE IF EXISTS Temp_Evenement CASCADE;
CREATE TABLE Temp_Evenement (
    event_id        INT,
    description     TEXT,
    date_debut      DATE,
    date_fin        DATE,
    prix            NUMERIC(8,2),
    lieu_id         INT,
    organisateur_id VARCHAR(50)
);
\COPY Temp_Evenement(event_id, description, date_debut, date_fin, prix, lieu_id, organisateur_id) FROM 'sql/data/Evenement.csv' WITH (FORMAT csv, HEADER);


-- TEMP TABLE TRACE NUMERIQUE
DROP TABLE IF EXISTS Temp_TraceNumerique CASCADE;
CREATE TABLE Temp_TraceNumerique (
    trace_id        SERIAL PRIMARY KEY,
    source          VARCHAR(30),
    date_activite   DATE,
    type            VARCHAR(50),
    details         TEXT,
    user_id  VARCHAR(50)
);
\COPY Temp_TraceNumerique(trace_id, source, date_activite, type, details, user_id) FROM 'sql/data/TraceNumerique.csv' WITH (FORMAT csv, HEADER);


-- TEMP TABLE CATEGORIETAG
DROP TABLE IF EXISTS Temp_CategorieTag CASCADE;
CREATE TABLE Temp_CategorieTag (
    categorie_id INT,
    libelle      VARCHAR(100),
    parent_id    INT
);
\COPY Temp_CategorieTag(categorie_id, libelle, parent_id) FROM 'sql/data/CategorieTag.csv' WITH (FORMAT csv, HEADER);


-- TEMP TABLE TAGS
DROP TABLE IF EXISTS Temp_Tag CASCADE;
CREATE TABLE Temp_Tag (
    tag_id       INT,
    nom          VARCHAR(100),
    categorie_id INT
);
\COPY Temp_Tag(tag_id, nom, categorie_id) FROM 'sql/data/Tag.csv' WITH (FORMAT csv, HEADER);


-- 5) TEMP TABLE like
DROP TABLE IF EXISTS Temp_like CASCADE;
CREATE TABLE Temp_like (
    user_from VARCHAR(50),
    user_to   VARCHAR(50),
    date      TIMESTAMP,
    type      VARCHAR(10),
    actif     BOOLEAN
);
\COPY Temp_like(user_from, user_to, date, type, actif) FROM 'sql/data/Like.csv' WITH (FORMAT csv, HEADER);


-- TEMP TABLE USERTAG
DROP TABLE IF EXISTS Temp_UserTag CASCADE;
CREATE TABLE Temp_UserTag (
    user_id VARCHAR(50),
    tag_id  INT
);
\COPY Temp_UserTag(user_id, tag_id) FROM 'sql/data/UserTag.csv' WITH (FORMAT csv, HEADER);


-- TEMP TABLE EVENTTAG
DROP TABLE IF EXISTS Temp_EventTag CASCADE;
CREATE TABLE Temp_EventTag (
    event_id INT,
    tag_id   INT
);
\COPY Temp_EventTag(event_id, tag_id) FROM 'sql/data/EventTag.csv' WITH (FORMAT csv, HEADER);


-- TEMP TABLE LIEUTAGg
DROP TABLE IF EXISTS Temp_LieuTag CASCADE;
CREATE TABLE Temp_LieuTag (
    lieu_id INT,
    tag_id  INT
);
\COPY Temp_LieuTag(lieu_id, tag_id) FROM 'sql/data/LieuTag.csv' WITH (FORMAT csv, HEADER);


-- TEMP TABLE participation
DROP TABLE IF EXISTS Temp_participation CASCADE;
CREATE TABLE Temp_participation (
    user_id VARCHAR(50),
    event_id INT,
    statut   VARCHAR(20),
    date     TIMESTAMP
);
\COPY Temp_participation(user_id, event_id, statut, date) FROM 'sql/data/participation.csv' WITH (FORMAT csv, HEADER);


-- TEMP TABLE MATCH
DROP TABLE IF EXISTS Temp_Match CASCADE;
CREATE TABLE Temp_Match (
    user1           VARCHAR(50),
    user2           VARCHAR(50),
    date_match      DATE
);
\COPY Temp_Match(user1, user2, date_match) FROM 'sql/data/Match.csv' WITH (FORMAT csv, HEADER);