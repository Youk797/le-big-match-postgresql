-- insert_data.sql 
-- S'assurer d'avoir exécuté create.sql et import_temp.sql avant.

-- 1) Import statique des gens de référence
-- On importe directement les genres et orientations depuis leurs CSV respectifs
\COPY Genre(genre_id, libelle) FROM 'sql/data/Genre.csv' CSV HEADER;
\COPY Orientation(orientation_id, libelle) FROM 'sql/data/Orientation.csv' CSV HEADER;

-- 2) Insertion des Utilisateurs
INSERT INTO Utilisateur(
  pseudo,
  ville,
  pays,
  taille,
  poids,
  couleur_yeux,
  abonne,
  genre_id,
  orientation_id
)
SELECT
  t.pseudo,
  t.ville,
  t.pays,
  t.taille,
  t.poids,
  t.couleur_yeux,
  t.abonne,
  t.genre_id,
  t.orientation_id
FROM Temp_Utilisateur t;

-- 3) Insertion des Lieux
INSERT INTO Lieu(
  lieu_id,
  nom,
  adresse,
  type_lieu,
  latitude,
  longitude
)
SELECT
  l.lieu_id,
  l.nom,
  l.adresse,
  l.type_lieu,
  l.latitude,
  l.longitude
FROM Temp_Lieu l;

-- 4) Insertion des Événements
INSERT INTO Evenement(
  event_id,
  description,
  date_debut,
  date_fin,
  prix,
  lieu_id,
  organisateur_id
)
SELECT
  e.event_id,
  e.description,
  e.date_debut,
  e.date_fin,
  e.prix,
  e.lieu_id,
  e.organisateur_id
FROM Temp_Evenement e;

-- 5) Insertion des Catégories de Tags 
INSERT INTO CategorieTag(categorie_id, libelle, parent_id)
SELECT
  t.categorie_id,
  t.libelle,
  t.parent_id
FROM Temp_CategorieTag t;

-- 6) Insertion des Tags
INSERT INTO Tag(tag_id, nom, categorie_id)
SELECT
  t.tag_id,
  t.nom,
  t.categorie_id
FROM Temp_Tag t
WHERE EXISTS (
  SELECT 1 FROM CategorieTag c WHERE c.categorie_id = t.categorie_id
);

-- 7) Insertion des participations (seulement les statuts autorisés)
INSERT INTO participation (user_id, event_id, statut, date)
SELECT  p.user_id,
        p.event_id,
        CASE
            WHEN lower(p.statut) = 'confirmed' THEN 'confirmé'
            WHEN lower(p.statut) = 'pending'   THEN 'en attente'
            WHEN lower(p.statut) = 'declined'  THEN 'annulé'
        END                                        AS statut,
        p.date
FROM   Temp_participation p
-- sécurise les clés étrangères
JOIN   Utilisateur u ON u.pseudo   = p.user_id
JOIN   Evenement   e ON e.event_id = p.event_id;




-- 8) Insertion des UserTag (seulement si l'utilisateur existe)
INSERT INTO UserTag (
  user_id,
  tag_id
)
SELECT DISTINCT
  ut.user_id,
  ut.tag_id
FROM Temp_UserTag ut
JOIN Utilisateur u
  ON u.pseudo = ut.user_id
ON CONFLICT (user_id, tag_id) DO NOTHING;


-- 9) Insertion des EventTag (seulement si l'événement existe)
INSERT INTO EventTag (
  event_id,
  tag_id
)
SELECT DISTINCT
  et.event_id,
  et.tag_id
FROM Temp_EventTag et
JOIN Evenement ev
  ON ev.event_id = et.event_id
ON CONFLICT (event_id, tag_id) DO NOTHING;


INSERT INTO LieuTag (lieu_id, tag_id)
SELECT DISTINCT                -- élimine les doublons éventuels dans Temp_LieuTag
       lt.lieu_id,
       lt.tag_id
FROM   Temp_LieuTag lt
JOIN   Lieu l ON l.lieu_id = lt.lieu_id   -- ne garde que les lieux existants
ON CONFLICT (lieu_id, tag_id) DO NOTHING; -- ignore la ligne si la clé existe déjà


-- 10) Insertion des Likes (types valides + doublons ignorés)
INSERT INTO "Like" (
    user_from,
    user_to,
    date,
    type,
    actif
)
SELECT
    l.user_from,
    l.user_to,
    l.date,
    l.type,
    l.actif
FROM Temp_Like l
WHERE l.type IN ('like','nope')
ON CONFLICT (user_from, user_to) DO NOTHING;   -- ← empêche l’erreur de clé dupliquée


-- 11) Insertion des Matches (réciproque, normalisation de l'ordre)
-- Nettoyage Temp_Match ----------------------------------------

-- 1) Afficher les doublons (paires non ordonnées + date)
SELECT
  LEAST(user1, user2) AS user_a,
  GREATEST(user1, user2) AS user_b,
  date_match,
  COUNT(*) AS nb_occurrences
FROM Temp_Match
GROUP BY user_a, user_b, date_match
HAVING COUNT(*) > 1;

-- 2) Supprimer les doublons en ne gardant qu'une seule ligne par groupe
WITH ranked AS (
  SELECT
    ctid,
    ROW_NUMBER() OVER (
      PARTITION BY
        LEAST(user1, user2),
        GREATEST(user1, user2),
        date_match
      ORDER BY
        user1, user2, date_match
    ) AS rn
  FROM Temp_Match
)
DELETE FROM Temp_Match
WHERE ctid IN (
  SELECT ctid
  FROM ranked
  WHERE rn > 1
);

-- 3) (Optionnel) Vérifier qu'il ne reste plus de doublons
SELECT
  LEAST(user1, user2) AS user_a,
  GREATEST(user1, user2) AS user_b,
  date_match,
  COUNT(*) AS nb_occurrences
FROM Temp_Match
GROUP BY user_a, user_b, date_match
HAVING COUNT(*) > 1;


INSERT INTO TraceNumerique(
  trace_id,
  source,
  date_activite,
  type,
  details,
  user_id
)
SELECT
  p.trace_id,
  p.source,
  p.date_activite,
  p.type,
  p.details,
  p.user_id
FROM Temp_TraceNumerique p;