-- Nettoyage Temp_Utilisateur
SELECT pseudo, COUNT(*)
FROM Temp_Utilisateur
 GROUP BY pseudo
HAVING COUNT(*) > 1;
DELETE FROM Temp_Utilisateur
 WHERE pseudo IN (
   SELECT pseudo
     FROM Temp_Utilisateur
    GROUP BY pseudo
   HAVING COUNT(*) > 1
 )
   AND ctid NOT IN (
     SELECT MIN(ctid)
       FROM Temp_Utilisateur
      GROUP BY pseudo
   );
-- Vérifier les tailles/poids
SELECT * FROM Temp_Utilisateur WHERE taille <= 0 OR poids <= 0;
-- Pays manquants
UPDATE Temp_Utilisateur
   SET pays = 'France'
 WHERE pays IS NULL;

-- Nettoyage Temp_Lieu
SELECT nom, COUNT(*)
  FROM Temp_Lieu
 GROUP BY nom
HAVING COUNT(*) > 1;

-- Nettoyage Temp_Evenement
SELECT date_debut, COUNT(*)
  FROM Temp_Evenement
 GROUP BY date_debut
HAVING COUNT(*) > 1;
SELECT * FROM Temp_Evenement WHERE prix < 0;

-- Nettoyage Temp_like
SELECT user_from, user_to, COUNT(*)
  FROM Temp_like
 GROUP BY user_from, user_to
HAVING COUNT(*) > 1;
-- like sur soi-même
SELECT *
  FROM Temp_like
 WHERE user_from = user_to;

 -- Supprimer les doublons exacts dans Temp_like
DELETE FROM Temp_like t
 WHERE (t.user_from, t.user_to) IN (
   SELECT user_from, user_to
     FROM Temp_like
    GROUP BY user_from, user_to
   HAVING COUNT(*) > 1
 )
   AND t.ctid NOT IN (
     SELECT MIN(ctid)
       FROM Temp_like
      GROUP BY user_from, user_to
   );

-- Supprimer doublons
DELETE FROM Temp_CategorieTag t
 WHERE (t.categorie_id, t.libelle) IN (
   SELECT categorie_id, libelle
     FROM Temp_CategorieTag
    GROUP BY categorie_id, libelle
   HAVING COUNT(*) > 1
 )
 AND ctid NOT IN (
   SELECT MIN(ctid)
     FROM Temp_CategorieTag
    GROUP BY categorie_id, libelle
 );

-- Parent_id invalide : mettre NULL si non numérique ou absent
UPDATE Temp_CategorieTag
   SET parent_id = NULL
 WHERE parent_id IS NOT NULL
   AND NOT EXISTS (
     SELECT 1 FROM Temp_CategorieTag x
      WHERE x.categorie_id = Temp_CategorieTag.parent_id
   );

-- Nettoyage Temp_UserTag
DELETE FROM Temp_UserTag
 WHERE (user_id, tag_id) IN (
   SELECT user_id, tag_id
     FROM Temp_UserTag
    GROUP BY user_id, tag_id
   HAVING COUNT(*) > 1
 )
   AND ctid NOT IN (
     SELECT MIN(ctid)
       FROM Temp_UserTag
      GROUP BY user_id, tag_id
   );

-- Nettoyage Temp_EventTag
DELETE FROM Temp_EventTag
 WHERE (event_id, tag_id) IN (
   SELECT event_id, tag_id
     FROM Temp_EventTag
    GROUP BY event_id, tag_id
   HAVING COUNT(*) > 1
 )
   AND ctid NOT IN (
     SELECT MIN(ctid)
       FROM Temp_EventTag
      GROUP BY event_id, tag_id
   );

-- Nettoyage Temp_participation
DELETE FROM Temp_participation
 WHERE (user_id, event_id) IN (
   SELECT user_id, event_id
     FROM Temp_participation
    GROUP BY user_id, event_id
   HAVING COUNT(*) > 1
 )
   AND ctid NOT IN (
     SELECT MIN(ctid)
       FROM Temp_participation
      GROUP BY user_id, event_id
   );