WITH
cog AS  (       SELECT dep as code_dept,
                       libelle
                FROM   cog_departement 
                ORDER BY 1),
t AS (  SELECT          code_dep as code_dept,
                        count(*) voies_topo
                FROM    topo
                WHERE   type_voie in ('1','2') AND
                	date_annul = '0'
                GROUP BY code_dept),
tn AS (         SELECT  code_dept,
                        count(*) voies_topo_non_integrees
                FROM    (SELECT fantoir,
                                code_dep as code_dept
                        FROM   topo
                        WHERE  type_voie in ('1','2') AND
                	date_annul = '0'
                        EXCEPT
                        SELECT fantoir,
                               code_dept
                        FROM   nom_fantoir
                        WHERE  source = 'OSM') a
                GROUP BY code_dept),
f AS (  	SELECT	code_dep as code_dept,
                        count(*) voies_topo_et_ld
                FROM    topo
                WHERE   type_voie in ('1','2','3')
                GROUP BY code_dept),
fn AS (         SELECT  code_dept,
                        count(*) voies_topo_et_ld_non_integrees
                FROM    (SELECT fantoir,
                                code_dep as code_dept
                        FROM   topo
                        WHERE  type_voie in ('1','2','3') AND
                	date_annul = '0'
                        EXCEPT
                        SELECT fantoir,
                               code_dept
                        FROM   nom_fantoir
                        WHERE  source = 'OSM') a
                GROUP BY code_dept),
b AS (  	SELECT	code_dept,
                        count(*) voies_ban
                FROM    nom_fantoir
                WHERE   source = 'BAN'
                GROUP BY code_dept),
bn AS (         SELECT  code_dept,
                        count(*) voies_ban_non_integrees
                FROM    (SELECT fantoir,
                                code_dept
                        FROM   nom_fantoir
                        WHERE  source = 'BAN'
                        EXCEPT
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
adrBANc AS (    SELECT  code_dept,
                        count(*) adresses_certifiees_BAN
                FROM    bano_adresses
                WHERE   source = 'BAN' AND
                	certification_commune=1
                GROUP BY code_dept),
adrnonrap AS (  SELECT  code_dept,
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
adrnonint AS (  SELECT  b.code_dept,
                        count(distinct concat(b.numero,b.fantoir)) adresses_non_integrees
                FROM    (SELECT code_dept,numero,fantoir
                        FROM    bano_adresses
                        WHERE   source = 'BAN')b
                LEFT OUTER JOIN (SELECT code_dept,numero,fantoir
                                 FROM   bano_adresses
                                 WHERE  source = 'OSM')o
                USING (fantoir)
                WHERE o.fantoir IS NULL
                GROUP BY b.code_dept),
adrcnonrap AS (  SELECT  code_dept,
                        count(distinct concat(numero,b.fantoir)) adresses_certifiees_non_rapprochees
                FROM    (SELECT code_dept,numero,fantoir
                        FROM    bano_adresses
                        WHERE   source = 'BAN' AND
                		certification_commune=1)b
                LEFT OUTER JOIN (SELECT fantoir
                                 FROM   nom_fantoir
                                 WHERE  source = 'OSM')o
                USING (fantoir)
                WHERE o.fantoir IS NULL
                GROUP BY code_dept),
adrcnonint AS (  SELECT  b.code_dept,
                        count(distinct concat(b.numero,b.fantoir)) adresses_certifiees_non_integrees
                FROM    (SELECT code_dept,numero,fantoir
                        FROM    bano_adresses
                        WHERE   source = 'BAN' AND
                		certification_commune=1)b
                LEFT OUTER JOIN (SELECT code_dept,numero,fantoir
                                 FROM   bano_adresses
                                 WHERE  source = 'OSM')o
                USING (fantoir)
                WHERE o.fantoir IS NULL
                GROUP BY b.code_dept),
z AS (SELECT  cog.code_dept, --Code dept
                cog.libelle, --departement
                t.voies_topo, --Voies TOPO
                tn.voies_topo_non_integrees, --Voies TOPO non intégrées
                (100-(tn.voies_topo_non_integrees*100/t.voies_topo)), --Pourcentage de Voies TOPO intégrées
                f.voies_topo_et_ld, --Voies TOPO + lieux-dits
                fn.voies_topo_et_ld_non_integrees, --Voies TOPO + lieux-dits non intégrées
                (100-(fn.voies_topo_et_ld_non_integrees*100/f.voies_topo_et_ld)), --Pourcentage de Voies TOPO + lieux-dits intégrées
                b.voies_ban, --Voies BAN
                bn.voies_ban_non_integrees, --Voies BAN
                (100-(bn.voies_ban_non_integrees*100/b.voies_ban)), --Pourcentage de Voies BAN intégrées
                adrOSM.adresses_OSM, --Adresses OSM
                adrBAN.adresses_BAN, --Adresses BAN
                adrnonrap.adresses_non_rapprochees, --Adresses BAN sans voie rapprochée
                ((100-adrnonrap.adresses_non_rapprochees*100/adrBAN.adresses_BAN))::integer, --Pourcentage d'adresses BAN avec voie rapprochée
                adrnonint.adresses_non_integrees, --Adresses BAN non intégrées
                ((100-adrnonint.adresses_non_integrees*100/adrBAN.adresses_BAN))::integer, --Pourcentage d'adresses BAN non intégrées
                adrBANc.adresses_certifiees_BAN, --Adresses BAN certifiees
                adrcnonrap.adresses_certifiees_non_rapprochees, --Adresses BAN certifiees sans voie rapprochée
                ((100-adrcnonrap.adresses_certifiees_non_rapprochees*100/adrBANc.adresses_certifiees_BAN))::integer, --Pourcentage d'adresses BAN certifiees avec voie rapprochée
                adrcnonint.adresses_certifiees_non_integrees, --Adresses BAN certifiees non intégrées
                ((100-adrcnonint.adresses_certifiees_non_integrees*100/adrBANc.adresses_certifiees_BAN))::integer --Pourcentage d'adresses BAN certifiees non intégrées
        FROM    cog
        LEFT OUTER JOIN t USING (code_dept)
        LEFT OUTER JOIN tn USING (code_dept)
        JOIN f USING (code_dept)
        LEFT OUTER JOIN fn USING (code_dept)
        LEFT OUTER JOIN b USING (code_dept)
        LEFT OUTER JOIN bn USING (code_dept)
        LEFT OUTER JOIN adrOSM USING (code_dept)
        LEFT OUTER JOIN adrBAN USING (code_dept)
        LEFT OUTER JOIN adrBANc USING (code_dept)
        LEFT OUTER JOIN adrnonrap USING (code_dept)
        LEFT OUTER JOIN adrnonint USING (code_dept)
        LEFT OUTER JOIN adrcnonrap USING (code_dept)
        LEFT OUTER JOIN adrcnonint USING (code_dept)
        )
select *
FROM (
  SELECT *
  FROM z
  UNION ALL
  SELECT 'Total',
         'Total',
         sum(voies_topo),
         sum(voies_topo_non_integrees),
         (100-(sum(voies_topo_non_integrees)*100/sum(voies_topo)))::integer, --Pourcentage de Voies TOPO intégrées
         sum(voies_topo_et_ld), --Voies TOPO + lieux-dits
         sum(voies_topo_et_ld_non_integrees), --Voies TOPO + lieux-dits non intégrées
         (100-(sum(voies_topo_et_ld_non_integrees)*100/sum(voies_topo_et_ld)))::integer, --Pourcentage de Voies TOPO + lieux-dits intégrées
         sum(voies_ban), --Voies BAN
         sum(voies_ban_non_integrees), --Voies BAN
         (100-(sum(voies_ban_non_integrees)*100/sum(voies_ban)))::integer, --Pourcentage de Voies BAN intégrées
         sum(adresses_OSM), --Adresses OSM
         sum(adresses_BAN), --Adresses BAN
         sum(adresses_non_rapprochees), --Adresses BAN sans voie rapprochée
         ((100-sum(adresses_non_rapprochees)*100/sum(adresses_BAN)))::integer, --Pourcentage d'adresses BAN avec voie rapprochée
         sum(adresses_non_integrees), --Adresses BAN non intégrées
         ((100-sum(adresses_non_integrees)*100/sum(adresses_BAN)))::integer, --Pourcentage d'adresses BAN non intégrées
         sum(adresses_certifiees_BAN), --Adresses BAN certifiees
         sum(adresses_certifiees_non_rapprochees), --Adresses BAN certifiees sans voie rapprochée
         ((100-sum(adresses_certifiees_non_rapprochees)*100/sum(adresses_certifiees_BAN)))::integer, --Pourcentage d'adresses BAN certifiees avec voie rapprochée
         sum(adresses_certifiees_non_integrees), --Adresses BAN certifiees non intégrées
         ((100-sum(adresses_certifiees_non_integrees)*100/sum(adresses_certifiees_BAN)))::integer --Pourcentage d'adresses BAN certifiees non intégrées
  FROM z
) t
