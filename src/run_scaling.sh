#!/bin/bash

EXEC="./graph500_reference_bfs_sssp"

# --- PARTIE 1 : STRONG SCALING (Version Rapide) ---
# On fixe une taille minuscule (SCALE 16 au lieu de 22)
echo "======================================"
echo "🚀 DÉBUT DU STRONG SCALING (SCALE 16) 🚀"
echo "======================================"
echo "Cœurs(np), BFS_TEPS, SSSP_TEPS" > strong_scaling_results.csv

for np in 1 2 4 8; do
    echo "Lancement avec $np processus..."
    output=$(mpirun --oversubscribe -np $np $EXEC 16)
    
    # Extraction des colonnes corrigée ($4)
    bfs_teps=$(echo "$output" | grep "bfs  harmonic_mean_TEPS:" | awk '{print $4}')
    sssp_teps=$(echo "$output" | grep "sssp harmonic_mean_TEPS:" | awk '{print $4}')
    
    echo "$np, $bfs_teps, $sssp_teps" >> strong_scaling_results.csv
done
cat strong_scaling_results.csv

echo ""

# --- PARTIE 2 : WEAK SCALING (Version Rapide) ---
# On commence beaucoup plus bas (SCALE 14 à 17)
echo "======================================"
echo "🚀 DÉBUT DU WEAK SCALING 🚀"
echo "======================================"
echo "Cœurs(np), SCALE, BFS_TEPS, SSSP_TEPS" > weak_scaling_results.csv

nps=(1 2 4 8)
scales=(14 15 16 17) # On a baissé de 6 crans par rapport à avant

for i in ${!nps[@]}; do
    np=${nps[$i]}
    scale=${scales[$i]}
    
    echo "Lancement avec $np processus (SCALE $scale)..."
    output=$(mpirun --oversubscribe -np $np $EXEC $scale)
    
    # Extraction des colonnes corrigée ($4)
    bfs_teps=$(echo "$output" | grep "bfs  harmonic_mean_TEPS:" | awk '{print $4}')
    sssp_teps=$(echo "$output" | grep "sssp harmonic_mean_TEPS:" | awk '{print $4}')
    
    echo "$np, $scale, $bfs_teps, $sssp_teps" >> weak_scaling_results.csv
done
cat weak_scaling_results.csv

echo "Terminé ! Lance le script Python maintenant, ça devrait être instantané."