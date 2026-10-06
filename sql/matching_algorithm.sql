-- Algorithme_de_matching.sql 
-- Implémentation de l'indice de recommandation pour profils et événements


-- 1) PROFIL  ─ Recommandation TOP 10
WITH u AS (
  SELECT *
  FROM   Utilisateur
  WHERE  pseudo = 'dhernandez16' -- Remplacer par l'utilisateur courant
)
SELECT
  p.pseudo                                                             AS candidate,
  /* ----------------------------------------------------------------
     SCORE AFFINITÉ (0‑100)
     ---------------------------------------------------------------- */
  (
      /* Tags en commun  ─────────────────────────────────────────── */
      30 * COALESCE(
            (
              SELECT COUNT(*)
              FROM   UserTag ut1
              JOIN   UserTag ut2 USING (tag_id)
              WHERE  ut1.user_id = u.pseudo
                AND  ut2.user_id = p.pseudo
            ), 0)
      / NULLIF((SELECT COUNT(*) FROM UserTag WHERE user_id = u.pseudo),1)

    + /* Événements communs ─────────────────────────────────────── */
      20 * COALESCE(
            (
              SELECT COUNT(*)
              FROM   participation pa
              JOIN   participation pb USING (event_id)
              WHERE  pa.user_id = u.pseudo
                AND  pb.user_id = p.pseudo
            ), 0)
      / NULLIF((SELECT COUNT(*) FROM participation WHERE user_id = u.pseudo),1)

    + /* Likes directs (u→p)  ───────────────────────────────────── */
      15 * COALESCE(
            (
              SELECT 1
              FROM   "Like" l
              WHERE  l.user_from = u.pseudo
                AND  l.user_to   = p.pseudo
                AND  l.type='like' AND l.actif
              LIMIT 1
            ), 0)

    + /* Likes mutuels  ─────────────────────────────────────────── */
      15 * COALESCE(
            (
              SELECT 1
              FROM   "Like" l1
              JOIN   "Like" l2
                     ON l1.user_from = u.pseudo
                    AND l1.user_to   = p.pseudo
                    AND l2.user_from = p.pseudo
                    AND l2.user_to   = u.pseudo
              WHERE  l1.type='like' AND l1.actif
                AND  l2.type='like' AND l2.actif
              LIMIT 1
            ), 0)

    + /* Géographie : même ville / même pays ───────────────────── */
      10 * CASE WHEN p.ville = u.ville                                              THEN 1 ELSE 0 END
    + 10 * CASE WHEN p.ville <> u.ville AND p.pays = u.pays                         THEN 1 ELSE 0 END
  )                                                                   AS score
FROM Utilisateur p
CROSS JOIN u
WHERE p.pseudo <> u.pseudo
  -- Filtre OBLIGATOIRE : orientation identique ------------------
  AND  p.orientation_id = u.orientation_id
ORDER BY score DESC, p.pseudo
LIMIT 10;


-- 2)  EVÉNEMENT  ─ Recommandation TOP 10
WITH u AS (
  SELECT * FROM Utilisateur WHERE pseudo = 'dhernandez16'
)
SELECT
  e.event_id,
  e.description,
  (
    -- (30) affinité tags   ─ idem
    30 * CASE WHEN EXISTS (SELECT 1 FROM EventTag et WHERE et.event_id = e.event_id)
           THEN (
                 SELECT COUNT(*)::float
                 FROM   UserTag ut JOIN EventTag et USING (tag_id)
                 WHERE  ut.user_id = u.pseudo AND et.event_id = e.event_id
               ) / NULLIF((SELECT COUNT(*) FROM EventTag WHERE event_id = e.event_id),0)
           ELSE 0 END

  + -- (30) historique participations similaires  ─ idem
    30 * CASE WHEN EXISTS (SELECT 1 FROM participation p3 WHERE p3.user_id = u.pseudo)
           THEN (
                 SELECT COUNT(*)::float
                 FROM   participation p2
                 JOIN   EventTag et1 ON p2.event_id = et1.event_id
                 JOIN   EventTag et2 USING (tag_id)
                 WHERE  p2.user_id = u.pseudo AND et2.event_id = e.event_id
               ) / NULLIF((SELECT COUNT(*) FROM participation WHERE user_id = u.pseudo),0)
           ELSE 0 END

  + -- (20) popularité              ─ idem
    20 * LEAST((SELECT COUNT(*)::float FROM participation WHERE event_id = e.event_id)/100,1)

  + -- (15) proximité géographique  ─ idem
    15 * CASE WHEN l.adresse ILIKE '%'||u.ville||'%' THEN 1
               WHEN l.adresse ILIKE '%'||u.pays||'%' THEN 0.5
               ELSE 0 END

  + -- (5) profils orientation identique présents
    5 * CASE WHEN EXISTS (SELECT 1 FROM participation p4 WHERE p4.event_id = e.event_id)
         THEN (
               SELECT COUNT(*)::float
               FROM   participation p2
               JOIN   Utilisateur p3 ON p2.user_id = p3.pseudo
               WHERE  p2.event_id = e.event_id
                 AND  p3.orientation_id = u.orientation_id
             ) / NULLIF((SELECT COUNT(*) FROM participation WHERE event_id = e.event_id),0)
         ELSE 0 END
  ) AS score
FROM Evenement e
JOIN Lieu l ON e.lieu_id = l.lieu_id
CROSS JOIN u
WHERE e.date_debut >= CURRENT_DATE
ORDER BY score DESC, e.date_debut
LIMIT 10;
