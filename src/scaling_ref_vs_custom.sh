#!/bin/bash

# Compilation des deux versions
make graph500_reference_bfs
make graph500_custom_bfs

# Paramètres
SCALE_STRONG=19
SCALES_WEAK=(16 17 18 19)
NPS=(1 2 4 8)
# Nombre de threads pour le custom
# Sur ROMÉO, on peut carrément monter à 192 (chad)
export OMP_NUM_THREADS=4 

RESULTS_STRONG="strong_scaling_comparison.csv"
RESULTS_WEAK="weak_scaling_comparison.csv"

echo "Version, Coeurs(np), BFS_TEPS" > $RESULTS_STRONG
echo "Version, Coeurs(np), SCALE, BFS_TEPS" > $RESULTS_WEAK

# Strong Scaling

echo "Démarrage Strong Scaling (SCALE $SCALE_STRONG)..."
for np in "${NPS[@]}"; do
    # Run Reference (MPI Pur)
    echo "Ref MPI - np $np"
    out_ref=$(mpirun --oversubscribe -np $np ./graph500_reference_bfs $SCALE_STRONG)
    teps_ref=$(echo "$out_ref" | grep "bfs  harmonic_mean_TEPS:" | awk '{print $4}')
    echo "REFERENCE, $np, $teps_ref" >> $RESULTS_STRONG

    # Run Custom (Hybride)
    echo "Custom Hybride - np $np (Threads: $OMP_NUM_THREADS)"
    out_cust=$(mpirun --oversubscribe -np $np ./graph500_custom_bfs $SCALE_STRONG)
    teps_cust=$(echo "$out_cust" | grep "bfs  harmonic_mean_TEPS:" | awk '{print $4}')
    echo "CUSTOM, $np, $teps_cust" >> $RESULTS_STRONG
done

# Weak Scaling
echo "Démarrage Weak Scaling..."
for i in ${!NPS[@]}; do
    np=${NPS[$i]}
    scale=${SCALES_WEAK[$i]}
    
    # Run Reference
    echo "Ref MPI - np $np (SCALE $scale)"
    out_ref=$(mpirun --oversubscribe -np $np ./graph500_reference_bfs $scale)
    teps_ref=$(echo "$out_ref" | grep "bfs  harmonic_mean_TEPS:" | awk '{print $4}')
    echo "REFERENCE, $np, $scale, $teps_ref" >> $RESULTS_WEAK

    # Run Custom
    echo "Custom Hybride - np $np (SCALE $scale)"
    out_cust=$(mpirun --oversubscribe -np $np ./graph500_custom_bfs $scale)
    teps_cust=$(echo "$out_cust" | grep "bfs  harmonic_mean_TEPS:" | awk '{print $4}')
    echo "CUSTOM, $np, $scale, $teps_cust" >> $RESULTS_WEAK
done

echo "Terminé ! Résultats sauvegardés dans $RESULTS_STRONG et $RESULTS_WEAK"