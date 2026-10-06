-- requetes.sql

-- 1) Requete sur au moins 3 tables: Identifier les personnes qui organisent le plus d'evenement, pour chaque organisateur :
--   • nb_evenements   = nombre total d'événements créés
--   • nb_participants  = total des participations à ses événements
--   • nb_tags_distinct = nombre de tags différents utilisés dans ses événements
SELECT
    u.pseudo               AS organisateur,
    COUNT(DISTINCT e.event_id)    AS nb_evenements,
    COUNT(p.user_id)              AS nb_participants,
    COUNT(DISTINCT et.tag_id)     AS nb_tags_distinct
FROM
    Evenement e
    INNER JOIN Utilisateur u
        ON e.organisateur_id = u.pseudo
    LEFT JOIN participation p
        ON e.event_id = p.event_id
    LEFT JOIN EventTag et
        ON e.event_id = et.event_id
GROUP BY
    u.pseudo
ORDER BY
    nb_evenements   DESC,
    nb_participants  DESC;


-- 2) Jointure reflexive : Identifier les paires d’utilisateurs partageant au moins 7 centres d’intérêt
SELECT
    u1.pseudo                                AS user1,
    u2.pseudo                                AS user2,
    COUNT(*)                                 AS nb_centres_interet_communs
FROM
    UserTag ut1
    JOIN UserTag ut2
        ON ut1.tag_id = ut2.tag_id
        AND ut1.user_id < ut2.user_id       
    JOIN Utilisateur u1
        ON ut1.user_id = u1.pseudo
    JOIN Utilisateur u2
        ON ut2.user_id = u2.pseudo
GROUP BY
    u1.pseudo,
    u2.pseudo
HAVING
    COUNT(*) >= 7                         
ORDER BY
    nb_centres_interet_communs DESC;


--3)Auto_jointure Suggestion de “rencontres” basée sur la co-participation à des événements
-- On identifie les paires d’utilisateurs ayant confirmé leur présence
-- à au moins 2 mêmes événements (auto-jointure sur participation)
SELECT
    u1.pseudo                               AS user1,
    u2.pseudo                               AS user2,
    COUNT(DISTINCT p1.event_id)             AS nb_events_communs
FROM
    participation p1
    INNER JOIN participation p2
        ON p1.event_id = p2.event_id
       AND p1.user_id < p2.user_id      
    INNER JOIN Utilisateur u1
        ON p1.user_id = u1.pseudo
    INNER JOIN Utilisateur u2
        ON p2.user_id = u2.pseudo
WHERE
    p1.statut = 'confirmé'
    AND p2.statut = 'confirmé'
GROUP BY
    u1.pseudo,
    u2.pseudo
HAVING
    COUNT(DISTINCT p1.event_id) >= 2     
ORDER BY
    nb_events_communs DESC;


-- 4) sous-requete dans le WHERE Événements « premium » par organisateur:
--elle identifie, pour chaque organisateur, les événements dont le prix dépasse de 20 % la moyenne de ses propres événements.
SELECT
    e.event_id,
    e.description,
    e.organisateur_id,
    e.prix
FROM
    Evenement AS e
WHERE
    e.prix > (
        -- sous-requête  : moyenne des prix par même organisateur
        SELECT
            AVG(e2.prix) * 1.2
        FROM
            Evenement AS e2
        WHERE
            e2.organisateur_id = e.organisateur_id
    )
ORDER BY
    e.organisateur_id,
    e.prix DESC;


-- 5)ne sous-requête dans le FROM  recherche les 10 profils ayant le plus de centres d’intérêt en commun avec l’utilisateur
SELECT 
    u.pseudo,
    u.ville,
    u.pays,
    t.common_tags
FROM Utilisateur u
JOIN (
    -- Sous-requête qui compte, pour chaque utilisateur ≠ 'llefebvre13', 
    -- le nombre de tags en commun avec 'llefebvre13'
    SELECT 
        ut2.user_id AS pseudo,
        COUNT(*)     AS common_tags
    FROM UserTag ut1
    JOIN UserTag ut2
      ON ut1.tag_id = ut2.tag_id
    WHERE ut1.user_id = 'llefebvre13'
      AND ut2.user_id <> 'llefebvre13'
    GROUP BY ut2.user_id
) AS t
  ON u.pseudo = t.pseudo
-- exclure ceux qu’'llefebvre13' a déjà likés ou avec qui elle est matchée
LEFT JOIN "like" l
  ON l.user_from = 'llefebvre13'
 AND l.user_to   = u.pseudo
LEFT JOIN "Match" m
  ON (m.user1 = 'llefebvre13' AND m.user2 = u.pseudo)
  OR (m.user2 = 'llefebvre13' AND m.user1 = u.pseudo)
WHERE l.user_to IS NULL      -- pas encore likés
  AND m.user1   IS NULL      -- pas encore matchés
ORDER BY t.common_tags DESC  -- du plus de tags communs au moins
LIMIT 10;


-- 6) Agregat avec group by utilisateurs les plus likés superieur à 35 like
SELECT
  l.user_to    AS pseudo,
  COUNT(*)     AS nb_likes_recus
FROM "like" l
WHERE l.actif = TRUE
  AND l.type = 'like'
GROUP BY l.user_to
HAVING COUNT(*) > 35;


-- 7) Agregat avec Having evenements les plus populaire superieur à 45
SELECT
  e.event_id,
  e.description,
  COUNT(*) AS nb_confirmes
FROM participation p
JOIN Evenement e
  ON p.event_id = e.event_id
WHERE p.statut = 'confirmé'
GROUP BY e.event_id, e.description
HAVING COUNT(*) >= 45;

-- 8)Une requête impliquant le calcul de deux agrégats, on détermine pour chaque utilisateur son mois record de likes, 
--puis on compare ces records entre eux en affichant aussi la moyenne des records de tous.
WITH user_max AS (
  -- max de likes mensuels par utilisateur
  SELECT
    user_from,
    MAX(nb_likes) AS max_likes
  FROM (
    SELECT
      l.user_from,
      DATE_TRUNC('month', l.date) AS mois,
      COUNT(*)                 AS nb_likes
    FROM "Like" l
    WHERE l.type = 'like'
      AND l.actif = TRUE
    GROUP BY l.user_from, DATE_TRUNC('month', l.date)
  ) AS monthly
  GROUP BY user_from
)
SELECT
  um.user_from AS pseudo,
  um.max_likes AS max_likes_mensuels,
  ROUND(
    (
      SELECT AVG(max_likes) 
      FROM user_max
    )::numeric,
    2
  ) AS moyenne_des_max_likes
FROM user_max um
ORDER BY um.max_likes DESC;


-- 9) jointure externe LEFT JOIN une requête qui liste tous les lieux et le nombre d’événements organisés dans chacun, y compris ceux qui n’en ont jamais accueilli
SELECT
  L.lieu_id,
  L.nom,
  COUNT(E.event_id) AS nb_evenements
FROM Lieu L
LEFT JOIN Evenement E
  ON L.lieu_id = E.lieu_id
GROUP BY
  L.lieu_id,
  L.nom
ORDER BY
  nb_evenements ASC;

--10) Sous-requêtes corrélées certains organisateurs ne facturent jamais (prix = 0) leurs événements.
SELECT u.pseudo AS organisateur
FROM Utilisateur u
WHERE EXISTS (
    -- il a au moins un événement
    SELECT 1
    FROM Evenement e1
    WHERE e1.organisateur_id = u.pseudo
)
AND NOT EXISTS (
    -- il n’existe aucun de ses événements
    -- dont le prix est strictement positif
    SELECT 1
    FROM Evenement e2
    WHERE e2.organisateur_id = u.pseudo
      AND e2.prix > 0
);

--11) Agrégation certains organisateurs ne facturent jamais (prix = 0) leurs événements.
SELECT e.organisateur_id AS organisateur
FROM Evenement e
GROUP BY e.organisateur_id
HAVING COUNT(*) > 0
   -- et le prix maximum parmi ses événements est 0
   AND MAX(e.prix) = 0;

--12)compte le nombre d'activité par personnes et les tri par ordre décroissant determinant les personnes les plus actifs
--  compte uniquement les lignes dont source n’est pas NULL
SELECT
    user_id,
    COUNT(source) AS nb_activites
FROM
    TraceNumerique
GROUP BY
    user_id
ORDER BY
    nb_activites DESC;
--  compte toutes les lignes, NULLs inclus
SELECT
    user_id,
    COUNT(*) AS nb_activites
FROM
    TraceNumerique
GROUP BY
    user_id
ORDER BY
    nb_activites DESC;

--13)compte le nombre d'activité par personnes et les tri par ordre décroissant determinant les personnes les plus actifs
 -- on exclut explicitement les lignes sans source
SELECT
    user_id,
    COUNT(*) AS nb_activites
FROM
    TraceNumerique
WHERE
    source IS NOT NULL   
GROUP BY
    user_id
ORDER BY
    nb_activites DESC;
--utiliser un filtre d’agrégation 
SELECT
    user_id,
    COUNT(*) FILTER (WHERE source IS NOT NULL) AS nb_activites
FROM
    TraceNumerique
GROUP BY
    user_id
ORDER BY
    nb_activites DESC;


-- 14)une requête récursive: Ppour chacun des lieux “très demandés” (ici définis comme ayant déjà plus de 3 événements passés), 
--génère jour par jour à partir d’aujourd’hui et s’arrête dès qu’elle trouve un jour libre.
WITH RECURSIVE
  popular_lieux AS (
    SELECT lieu_id
    FROM Evenement
    GROUP BY lieu_id
    HAVING COUNT(*) > 3
  ),

  next_free AS (
    SELECT pl.lieu_id,
           CURRENT_DATE AS jour     
    FROM popular_lieux pl

    UNION ALL

    SELECT nf.lieu_id,
           (nf.jour + INTERVAL '1 day')::date AS jour  
    FROM next_free nf
    JOIN Evenement e
      ON e.lieu_id = nf.lieu_id
     AND nf.jour BETWEEN e.date_debut
                    AND COALESCE(e.date_fin, e.date_debut)
  )

SELECT
  nf.lieu_id,
  MIN(nf.jour) AS prochaine_date_disponible
FROM next_free nf
LEFT JOIN Evenement e
  ON e.lieu_id = nf.lieu_id
 AND nf.jour BETWEEN e.date_debut
                AND COALESCE(e.date_fin, e.date_debut)
WHERE e.event_id IS NULL
GROUP BY nf.lieu_id;

-- 15)(Une requête utilisant du fenêtrage)  Calcule pour chaque mois de 2024 et chaque utilisateur le nombre de “nope” qu’il a reçus.
-- Numérote ces utilisateurs par mois selon ce nombre (fenêtrage).
-- Ne conserve que les 10 premiers de chaque mois.
-- Récupère enfin, pour chacun, la liste de ses mots-clés 
WITH monthly_nopes AS (
  --  Nombre de “nope” reçus par utilisateur et par mois
  SELECT
    date_trunc('month', l.date) AS mois,
    l.user_to                  AS pseudo,
    COUNT(*)                   AS nb_nopes
  FROM "Like" l
  WHERE l.type = 'nope'
    AND l.date >= '2024-01-01'
    AND l.date <  '2025-01-01'
  GROUP BY 1, 2
),
ranked AS (
  -- On classe dans chaque mois par nombre décroissant de “nope”
  SELECT
    mois,
    pseudo,
    nb_nopes,
    ROW_NUMBER() OVER (
      PARTITION BY mois
      ORDER BY nb_nopes DESC
    ) AS rang
  FROM monthly_nopes
)
-- On ne garde que les top-10 de chaque mois, et on agrége leurs tags
SELECT
  to_char(r.mois, 'YYYY-MM') AS mois,
  r.pseudo,
  r.nb_nopes,
  COALESCE(string_agg(t.nom, ', ' ORDER BY t.nom), '') AS mots_cles
FROM ranked r
LEFT JOIN UserTag ut
  ON ut.user_id = r.pseudo
LEFT JOIN Tag t
  ON t.tag_id = ut.tag_id
WHERE r.rang <= 10
GROUP BY r.mois, r.pseudo, r.nb_nopes
ORDER BY r.mois, r.nb_nopes DESC;


--16) auto jointure :Cette requête récupère, pour chaque centre d’intérêt d’un utilisateur, 
--la catégorie générale correspondante afin d’afficher clairement la hiérarchie des intérêts dans son profil.
SELECT 
  c.categorie_id   AS id_enfant,
  c.libelle        AS libelle_enfant,
  p.categorie_id   AS id_parent,
  p.libelle        AS libelle_parent
FROM CategorieTag c
LEFT JOIN CategorieTag p
  ON c.parent_id = p.categorie_id;

--17) requete1 qui utilise tracenumerique Proposer des matchs basés sur une activité commune

SELECT DISTINCT
  t1.user_id    AS user_a,
  t2.user_id    AS user_b,
  t1.source,
  t1.type,
  t1.details
FROM TraceNumerique t1
JOIN TraceNumerique t2
  ON t1.source    = t2.source
 AND t1.details   = t2.details
 AND t1.type      = t2.type
 AND t1.user_id <> t2.user_id;

--18) requete2 qui utilise tracenumerique Mesurer l’engagement en extrayant la dernière date d’activité de chacun
SELECT
  user_id,
  MAX(date_activite) AS date_derniere_activite
FROM TraceNumerique
GROUP BY user_id;

--19) On repère ici les paires d’utilisateurs ayant réalisé au moins 2 fois la même activité numérique (visionnage, jeu…) sur la même plateforme, 
--dans un délai de 3 jours, 
--pour suggérer des profils qui partagent vraiment des centres d’intérêt en quasi-temps réel.
SELECT
    t1.user_id                AS user_a,
    t2.user_id                AS user_b,
    t1.source,
    t1.details,
    COUNT(*)                  AS nb_rencontres_numériques
FROM
    TraceNumerique AS t1
    JOIN TraceNumerique AS t2
      ON t1.source       = t2.source
     AND t1.details      = t2.details
     AND t1.user_id    < t2.user_id
     AND t1.date_activite
         BETWEEN t2.date_activite - INTERVAL '3 days'
             AND t2.date_activite + INTERVAL '3 days'
GROUP BY
    t1.user_id,
    t2.user_id,
    t1.source,
    t1.details
HAVING
    COUNT(*) >= 2
ORDER BY
    nb_rencontres_numériques DESC;

--20)Proposer des “mentors numériques” : pour chaque nouvel utilisateur (≤ 30 jours d’activité),
--    trouver un utilisateur expérimenté (≥ 90 jours) ayant réalisé ≥ 3 fois la même activité.

WITH
    nouveaux AS (
        SELECT
            user_id,
            MIN(date_activite) AS premiere_activite
        FROM
            TraceNumerique
        GROUP BY
            user_id
        HAVING
            MIN(date_activite) >= CURRENT_DATE - INTERVAL '30 days'
    ),
    experimente AS (
        SELECT
            user_id
        FROM
            TraceNumerique
        GROUP BY
            user_id
        HAVING
            MIN(date_activite) <= CURRENT_DATE - INTERVAL '90 days'
    )
SELECT
    n.user_id    AS nouveau,
    e.user_id    AS mentor,
    tn.source,
    tn.details,
    COUNT(*)      AS nb_activites_communes
FROM
    TraceNumerique AS tn
    JOIN nouveaux AS n
      ON tn.user_id = n.user_id
    JOIN TraceNumerique AS tn2
      ON tn.source  = tn2.source
     AND tn.details = tn2.details
    JOIN experimente AS e
      ON tn2.user_id = e.user_id
GROUP BY
    n.user_id,
    e.user_id,
    tn.source,
    tn.details
HAVING
    COUNT(*) >= 3
ORDER BY
    n.user_id,
    nb_activites_communes DESC;

