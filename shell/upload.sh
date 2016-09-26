#####################################################
# Jenica Abrudan, NIPM V1.0 09/21/2016              #
#####################################################
#!/usr/bin/env bash -x

DBNAME=$1; 
DBPATH="/data1/home/nipm/jenica/testDBs/neo4j-community-3.0.3"

if ($2 ==    "clean")
then
   rm -r $DBPATH"/data/databases/"$DBNAME;
   echo "we want clean!";
fi; 
 $DBPATH"/bin/neo4j-import" --into $DBPATH"/data/databases/test.db" --skip-duplicate-nodes true --delimiter "\t" --array-delimiter "|" --nodes:Variant_L1:GRCh37 ~/Data/exac/curent/v1_full_exac_3.1_v3.txt --nodes:African_american_pop_L3 ~/Data/exac/curent/af_full_exac_3.1_3.txt --relationships:has_frequency ~/Data/exac/curent/v1-af_full_exac_3.1._v3.txt --nodes:Reference_L1:GRCh37:p13 ~/Data/csv/full_assembly/curent/hg19_all_v1.3d.tab --relationships:changes_to ~/Data/exac/curent/v1-r_full_exac_3.1_v3.txt --nodes:American_pop_L3 ~/Data/exac/curent/am_full_exac_3.1_v3.txt --relationships:has_frequency ~/Data/exac/curent/v1-am_full_exac_3.1._v3.txt --nodes:All_pop_L2 ~/Data/exac/curent/all_full_exac_3.1_v3.txt --relationships:has_frequency ~/Data/exac/curent/v1-all_full_exac_3.1._v3.txt --nodes:East_Asian_pop_L3 ~/Data/exac/curent/ea_full_exac_3.1_v3.txt --relationships:has_frequency ~/Data/exac/curent/v1-ea_full_exac_3.1._v3.txt --nodes:South_Asian_pop_L3 ~/Data/exac/curent/sas_full_exac_3.1_v3.txt --relationships:has_frequency ~/Data/exac/curent/v1-sas_full_exac_3.1._v3.txt --nodes:European_nfe_pop_L3 ~/Data/exac/curent/nfe_full_exac_3.1_v3.txt --relationships:has_frequency ~/Data/exac/curent/v1-nfe_full_exac_3.1._v3.txt --nodes:Finnish_pop_L3 ~/Data/exac/curent/fin_full_exac_3.1_v3.txt --relationships:has_frequency ~/Data/exac/curent/v1-fin_full_exac_3.1._v3.txt --nodes:Genes_L1 ~/Data/hugo/curent/hugo_cleaned0917_gene1_tab.txt --nodes:Gene_family_L2 ~/Data/hugo/curent/hugo_cleaned0917_fam_tab.txt --relationships:belongs_to ~/Data/hugo/curent/hugo_cleaned0917_g1-fam_tab.txt --nodes:Cyto_location_L2 ~/Data/hugo/curent/hugo_cleaned0917_cyto_tab.txt --relationships:is_located_at ~/Data/hugo/curent/hugo_cleaned0917_g1-cyto_tab.txt --nodes:Gene_alias_L2 ~/Data/hugo/curent/hugo_cleaned0917_alias_tab.txt --relationships:also_known_as ~/Data/hugo/curent/hugo_cleaned0917_g1-alias_tab.txt;