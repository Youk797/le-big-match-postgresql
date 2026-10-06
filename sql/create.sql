    -- 1) Nettoyage préalable : on supprime les tables dans le bon ordre pour éviter les problèmes de clé étrangère
    DROP TABLE IF EXISTS LieuTag CASCADE;
    DROP TABLE IF EXISTS EventTag CASCADE;
    DROP TABLE IF EXISTS UserTag CASCADE;
    DROP TABLE IF EXISTS "like" CASCADE;
    DROP TABLE IF EXISTS "Match" CASCADE;
    DROP TABLE IF EXISTS participation CASCADE;
    DROP TABLE IF EXISTS Tag CASCADE;
    DROP TABLE IF EXISTS Evenement CASCADE;
    DROP TABLE IF EXISTS Lieu CASCADE;
    DROP TABLE IF EXISTS Utilisateur CASCADE;
    DROP TABLE IF EXISTS Genre CASCADE;
    DROP TABLE IF EXISTS Orientation CASCADE;
    DROP TABLE IF EXISTS TraceNumerique CASCADE;
    DROP TABLE IF EXISTS CategorieTag CASCADE;


    -- 2) Création des tables "simples" (entités principales)

    -- GENRE
    CREATE TABLE Genre (
        genre_id SERIAL PRIMARY KEY,
        libelle VARCHAR(100) NOT NULL
    );

    -- ORIENTATION
    CREATE TABLE Orientation (
        orientation_id SERIAL PRIMARY KEY,
        libelle VARCHAR(100) NOT NULL
    );

    -- UTILISATEUR
    CREATE TABLE Utilisateur (
        pseudo      VARCHAR(50) PRIMARY KEY,
        ville       VARCHAR(100),
        pays        VARCHAR(100),
        taille      NUMERIC(5,2)  CHECK (taille > 0),
        poids       NUMERIC(5,2)  CHECK (poids > 0),
        couleur_yeux VARCHAR(30),
        abonne      BOOLEAN NOT NULL DEFAULT FALSE,
        genre_id       INT  REFERENCES Genre(genre_id),
        orientation_id INT  REFERENCES Orientation(orientation_id)
    );

    -- LIEU
    CREATE TABLE Lieu (
        lieu_id    SERIAL PRIMARY KEY,
        nom        VARCHAR(100) NOT NULL,
        adresse    VARCHAR(255),
        type_lieu  VARCHAR(50),
        latitude   DECIMAL(9,6),
        longitude  DECIMAL(9,6)
    );

    -- EVENEMENT
    CREATE TABLE Evenement (
        event_id SERIAL PRIMARY KEY,
        description TEXT,
        date_debut DATE NOT NULL,
        date_fin DATE,
        prix NUMERIC(8, 2) CHECK (prix >= 0),
        lieu_id INT REFERENCES Lieu(lieu_id),
        organisateur_id VARCHAR(50) REFERENCES Utilisateur(pseudo)
    );

    -- TRACE NUMERIQUE
    CREATE TABLE TraceNumerique (
        trace_id      SERIAL PRIMARY KEY,
        source        VARCHAR(30),
        date_activite DATE,
        type          VARCHAR(50),
        details       TEXT,
        user_id       VARCHAR(50) REFERENCES Utilisateur(pseudo)
    );

    -- CATEGORIE TAG
    CREATE TABLE CategorieTag (
        categorie_id SERIAL PRIMARY KEY,
        libelle      VARCHAR(100) NOT NULL,
        parent_id    INT REFERENCES CategorieTag(categorie_id)
    );

    -- TAG 
    CREATE TABLE Tag (
        tag_id       SERIAL PRIMARY KEY,
        nom          VARCHAR(100) NOT NULL,
        categorie_id INT REFERENCES CategorieTag(categorie_id)
    );


    -- 3) Tables d'associations

    -- Table "participation" (association entre Utilisateur et Evenement)
    CREATE TABLE participation (
        user_id VARCHAR(50) REFERENCES Utilisateur(pseudo),
        event_id INT REFERENCES Evenement(event_id),
        statut VARCHAR(20) CHECK (statut IN ('annulé', 'confirmé', 'en attente')),
        date TIMESTAMP, 
        PRIMARY KEY (user_id, event_id)
    );

    -- TABLE "USERTAG" (association entre Utilisateur et Tag)
    CREATE TABLE UserTag (
        user_id VARCHAR(50) REFERENCES Utilisateur(pseudo),
        tag_id  INT REFERENCES Tag(tag_id),
        PRIMARY KEY (user_id,tag_id)
    );

    -- TABLE "EVENTTAG" (association entre Evenement et Tag)
    CREATE TABLE EventTag (
        event_id INT REFERENCES Evenement(event_id),
        tag_id   INT REFERENCES Tag(tag_id),
        PRIMARY KEY (event_id,tag_id)
    );

    -- TABLE "LIEUTAG" (association entre Lieu et Tag)
    CREATE TABLE LieuTag (
        lieu_id  INT REFERENCES Lieu(lieu_id),
        tag_id   INT REFERENCES Tag(tag_id),
        PRIMARY KEY (lieu_id,tag_id)
    );

    -- TABLE "like"
    CREATE TABLE "like" (
        user_from VARCHAR(50) REFERENCES Utilisateur(pseudo),
        user_to   VARCHAR(50) REFERENCES Utilisateur(pseudo),
        date      TIMESTAMP,
        type      VARCHAR(10) CHECK (type IN ('like','nope')),
        actif     BOOLEAN DEFAULT TRUE,
        PRIMARY KEY (user_from,user_to)
    );

    -- TABLE "MATCH"
    CREATE TABLE "Match" (
        user1      VARCHAR(50) REFERENCES Utilisateur(pseudo),
        user2      VARCHAR(50) REFERENCES Utilisateur(pseudo),
        date_match DATE,
        PRIMARY KEY (user1,user2)
    );

    -- 4) Fin de la création, le schéma de base est en place, on peut insérer les données