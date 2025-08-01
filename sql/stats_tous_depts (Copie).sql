WITH
cog AS  (       SELECT dep as code_dept,
                       libelle
                FROM   cog_departement 
                ORDER BY 1),
a AS (          SELECT  code_dept,
                        count(distinct fantoir) voies_avec_adresses_rapprochees
                FROM    (SELECT fantoir,
                                code_dept
                        FROM   bano_adresses
                        WHERE  source = 'BAN'
                        INTERSECT
                        SELECT fantoir,
                               code_dept
                        FROM   nom_fantoir
                        WHERE  source = 'OSM') a
                GROUP BY code_dept),
adrOSM AS (     SELECT  code_dept,
                        count(*) adresses_OSM
                FROM    bano_adresses
                WHERE   source = 'OSM'
                GROUP BY code_dept),
adrBAN AS (     SELECT  code_dept,
                        count(*) adresses_BAN
                FROM    bano_adresses
                WHERE   source = 'BAN'
                GROUP BY code_dept),
adrnon AS (     SELECT  code_dept,
                        count(distinct concat(numero,b.fantoir)) adresses_non_rapprochees
                FROM    (SELECT code_dept,numero,fantoir
                        FROM    bano_adresses
                        WHERE   source = 'BAN')b
                LEFT OUTER JOIN (SELECT fantoir
                                 FROM   nom_fantoir
                                 WHERE  source = 'OSM')o
                USING (fantoir)
                WHERE o.fantoir IS NULL
                GROUP BY code_dept),
v AS (  SELECT          code_dept,
                        count(distinct fantoir) voies_rapprochees
                FROM    nom_fantoir
                WHERE   fantoir IS NOT NULL     AND
                        nature = 'voie'         AND
                        source = 'OSM'
                GROUP BY code_dept),
vl AS (  SELECT         code_dept,
                        count(distinct fantoir) voies_rapprochees
                FROM    nom_fantoir
                WHERE   fantoir IS NOT NULL     AND
                        source = 'OSM'
                GROUP BY code_dept),
t AS (  SELECT          code_dep as code_dept,
                        count(*) voies_fantoir
                FROM    topo
                WHERE   type_voie in ('1','2')
                GROUP BY code_dept),
f AS (  SELECT          code_dep as code_dept,
                        count(*) voies_fantoir
                FROM    topo
                WHERE   type_voie in ('1','2','3')
                GROUP BY code_dept)
SELECT  cog.code_dept, --Code dept
                cog.libelle, --departement
                COALESCE(a.voies_avec_adresses_rapprochees::integer,0) a, --Voies avec adresses rapprochées (a)
                COALESCE(v.voies_rapprochees::integer,0) b, --Toutes voies rapprochées (b)
                COALESCE(vl.voies_rapprochees::integer,0) b1, --Voies rapprochées sur lieux-dits (bl)
                COALESCE(t.voies_fantoir::integer,0) c, --Voies FANTOIR (c)
                f.voies_fantoir d, --Voies FANTOIR + lieux-dits (d)
                COALESCE(((a.voies_avec_adresses_rapprochees*100/t.voies_fantoir))::integer,0), --Pourcentage de rapprochement avec adresses
                COALESCE(((v.voies_rapprochees*100/t.voies_fantoir))::integer,0), --Pourcentage de rapprochement sur voies
                COALESCE(((v.voies_rapprochees*100/f.voies_fantoir))::integer,0), --Pourcentage de rapprochement sur voies+lieux-dits
                COALESCE(adrOSM.adresses_OSM::integer,0), --Adresses OSM
                COALESCE(adrBAN.adresses_BAN::integer,0), --Adresses BAN, BAL
                COALESCE(adrnon.adresses_non_rapprochees::integer,0), --Adresses sans voie rapprochée
                COALESCE(((100-adrnon.adresses_non_rapprochees*100/adrBAN.adresses_BAN))::integer,100) --Pourcentage d'adresses avec voie rapprochée
        FROM    cog
        LEFT OUTER JOIN v USING (code_dept)
        LEFT OUTER JOIN vl USING (code_dept)
        LEFT OUTER JOIN a USING (code_dept)
        LEFT OUTER JOIN adrOSM USING (code_dept)
        LEFT OUTER JOIN adrBAN USING (code_dept)
        LEFT OUTER JOIN adrnon USING (code_dept)
        LEFT OUTER JOIN    t USING (code_dept)
        JOIN    f USING (code_dept)
