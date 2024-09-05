#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb

import lxml
import requests

from bs4 import BeautifulSoup

import helpers as hp
import db
from sql import sql_get_data

cgitb.enable()

# force IP V4 cf https://github.com/osm-fr/osm-vs-fantoir/issues/162
requests.packages.urllib3.util.connection.HAS_IPV6 = False



import requete_numeros

code_insee="63417"
format='json'
liste = sql_get_data('pifometre', {'code_insee': code_insee, 'condition_fantoir_unique': ""})
'''
fantoir,
date_creation,
annule,
nom_topo,
nom_osm,
nom_ban,
source_nom_ban,
nom_ancienne_commune,
lon,
lat,
statut_voie,
numeros_a_proposer,
caractere_annul,
categorie,
avec_adresses_ban
'''
for fantoir, date_creation, annule, nom_topo, nom_osm, nom_ban, source_nom_ban, nom_ancienne_commune, lon, lat, statut_voie, numeros_a_proposer, caractere_annul, categorie, avec_adresses_ban in liste :
    xmlResponse = None
    if numeros_a_proposer :
        if categorie==0 :
            modele='Relation'
            fantoir_dans_relation='ok'
            xmlResponse =  requete_numeros.truc(code_insee, fantoir, modele, fantoir_dans_relation)
            print(xmlResponse)
            print("\n\n")

