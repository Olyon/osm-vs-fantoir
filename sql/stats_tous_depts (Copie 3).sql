--voies Topo intégrees
--85 % (reste 2416 sur 15279)

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
                        count(*) adresses_BAN,
                        avg(certification_commune*100)::int certification
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
                GROUP BY code_dept)
SELECT  cog.code_dept, --Code dept
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
                adrBAN.certification, --Pourcentage d'Adresses BAN certifiées
                adrnon.adresses_non_rapprochees, --Adresses sans voie rapprochée
                ((100-adrnon.adresses_non_rapprochees*100/adrBAN.adresses_BAN))::integer --Pourcentage d'adresses avec voie rapprochée
                
        FROM    cog
        LEFT OUTER JOIN t USING (code_dept)
        LEFT OUTER JOIN tn USING (code_dept)
        JOIN f USING (code_dept)
        LEFT OUTER JOIN fn USING (code_dept)
        LEFT OUTER JOIN b USING (code_dept)
        LEFT OUTER JOIN bn USING (code_dept)
        LEFT OUTER JOIN adrOSM USING (code_dept)
        LEFT OUTER JOIN adrBAN USING (code_dept)
        LEFT OUTER JOIN adrnon USING (code_dept)
