WITH
cog AS  (       SELECT dep as code_dept,
                       libelle
                FROM   cog_departement 
                ORDER BY 1),
a AS (          SELECT  code_dept,
                        count(*) voies_avec_adresses_rapprochees
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
                        count(*) voies_fantoir_et_ld
                FROM    topo
                WHERE   type_voie in ('1','2','3')
                GROUP BY code_dept)
SELECT  cog.code_dept, --Code dept
                cog.libelle, --departement
                a.voies_avec_adresses_rapprochees, --Voies avec adresses rapprochées (a)
                v.voies_rapprochees, --Toutes voies rapprochées (b)
                vl.voies_rapprochees, --Voies rapprochées sur lieux-dits (bl)
                t.voies_fantoir, --Voies FANTOIR (c)
                f.voies_fantoir_et_ld, --Voies FANTOIR + lieux-dits (d)
                ((a.voies_avec_adresses_rapprochees*100/t.voies_fantoir))::integer, --Pourcentage de rapprochement avec adresses
                ((v.voies_rapprochees*100/t.voies_fantoir))::integer, --Pourcentage de rapprochement sur voies
                ((v.voies_rapprochees*100/f.voies_fantoir_et_ld))::integer, --Pourcentage de rapprochement sur voies+lieux-dits
                adrOSM.adresses_OSM, --Adresses OSM
                adrBAN.adresses_BAN, --Adresses BAN, BAL
                adrnon.adresses_non_rapprochees, --Adresses sans voie rapprochée
                ((100-adrnon.adresses_non_rapprochees*100/adrBAN.adresses_BAN))::integer --Pourcentage d'adresses avec voie rapprochée
        FROM    cog
        LEFT OUTER JOIN v USING (code_dept)
        LEFT OUTER JOIN vl USING (code_dept)
        LEFT OUTER JOIN a USING (code_dept)
        LEFT OUTER JOIN adrOSM USING (code_dept)
        LEFT OUTER JOIN adrBAN USING (code_dept)
        LEFT OUTER JOIN adrnon USING (code_dept)
        LEFT OUTER JOIN    t USING (code_dept)
        JOIN    f USING (code_dept)
