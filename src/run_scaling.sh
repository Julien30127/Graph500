#!/bin/bash

EXEC="./graph500_reference_bfs_sssp"

# STRONG SCALING 

echo "Scale 21"

echo "Cœurs(np), BFS_TEPS, SSSP_TEPS" > strong_scaling_results.csv

for np in 1 2 4 8; do
    echo "Lancement avec $np processus..."
    output=$(mpirun --oversubscribe -np $np $EXEC 21)
    
    bfs_teps=$(echo "$output" | grep "bfs  harmonic_mean_TEPS:" | awk '{print $4}')
    sssp_teps=$(echo "$output" | grep "sssp harmonic_mean_TEPS:" | awk '{print $4}')
    
    echo "$np, $bfs_teps, $sssp_teps" >> strong_scaling_results.csv
done
cat strong_scaling_results.csv

echo ""

# WEAK SCALING

echo "Cœurs(np), SCALE, BFS_TEPS, SSSP_TEPS" > weak_scaling_results.csv

nps=(1 2 4 8)
scales=(18 19 20 21) 

for i in ${!nps[@]}; do
    np=${nps[$i]}
    scale=${scales[$i]}
    
    echo "Lancement avec $np processus (SCALE $scale)..."
    output=$(mpirun --oversubscribe -np $np $EXEC $scale)
    
    bfs_teps=$(echo "$output" | grep "bfs  harmonic_mean_TEPS:" | awk '{print $4}')
    sssp_teps=$(echo "$output" | grep "sssp harmonic_mean_TEPS:" | awk '{print $4}')
    
    echo "$np, $scale, $bfs_teps, $sssp_teps" >> weak_scaling_results.csv
done
cat weak_scaling_results.csv