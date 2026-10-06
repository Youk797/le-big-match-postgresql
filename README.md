# Le Big Match — Projet PostgreSQL

Projet universitaire de bases de données avancées : conception et implémentation sous PostgreSQL d'une base destinée à une application fictive de rencontres et d'événements.

Auteurs : Youssef El Kadiri & Gabriel Imbert

## Contenu

- modélisation relationnelle avec clés primaires / étrangères et contraintes d'intégrité ;
- import de données via tables temporaires ;
- scripts de nettoyage et d'insertion ;
- requêtes SQL avec jointures, agrégations, sous-requêtes et CTE ;
- algorithmes SQL de recommandation de profils et d'événements.

## Structure

```text
sql/
├── create.sql
├── import_temp.sql
├── clean_data.sql
├── insert_data.sql
├── queries.sql
└── matching_algorithm.sql

docs/
├── rapport.pdf
├── schema_relationnel.pdf
└── schema_entite_association.pdf
``

## Exécution

Dans `psql`, depuis la racine du dépôt :

```sql
\i sql/create.sql
\i sql/import_temp.sql
\i sql/clean_data.sql
\i sql/insert_data.sql
```

Les CSV utilisés pendant le projet ne sont pas inclus dans le dépôt ; les scripts d'import les attendent dans `sql/data/`. Le schéma peut néanmoins être créé indépendamment avec `create.sql`.

## Technologies

`PostgreSQL` · `SQL` · `Modélisation relationnelle` · `CTE` · `Agrégations` · `Recommandation`
