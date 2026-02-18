#!/bin/bash

# Compilation
make graph500_reference_bfs
make graph500_custom_bfs

# PAramètres globaux
SCALE_STRONG=19
SCALES_WEAK=(16 17 18 19)

# Fichiers de sortie
RESULTS_STRONG="strong_scaling_comparison.csv"
RESULTS_WEAK="weak_scaling_comparison.csv"
RESULTS_OMP="openmp_scaling_custom.csv"

echo "Version, Coeurs(np), BFS_TEPS" > $RESULTS_STRONG
echo "Version, Coeurs(np), SCALE, BFS_TEPS" > $RESULTS_WEAK
echo "Version, np, Threads, BFS_TEPS" > $RESULTS_OMP

# Test 1 & 2 : Strong et Weak Scaling (MPI)
# On bloque les threads OpenMP à 3 pour que le test max (np=4) fasse 4*3 = 12 cœurs (La limite de mon CPU, à modifier si l'architecture change)

NPS_MPI=(1 2 4)
export OMP_NUM_THREADS=3 

echo "Démarrage Strong Scaling (SCALE $SCALE_STRONG, Threads: $OMP_NUM_THREADS)"
for np in "${NPS_MPI[@]}"; do
    echo "Ref MPI - np $np"
    out_ref=$(mpirun --oversubscribe -np $np ./graph500_reference_bfs $SCALE_STRONG)
    teps_ref=$(echo "$out_ref" | grep "bfs  harmonic_mean_TEPS:" | awk '{print $4}')
    echo "Référence, $np, $teps_ref" >> $RESULTS_STRONG

    echo "Custom Hybride - np $np"
    out_cust=$(mpirun --oversubscribe -np $np ./graph500_custom_bfs $SCALE_STRONG)
    teps_cust=$(echo "$out_cust" | grep "bfs  harmonic_mean_TEPS:" | awk '{print $4}')
    echo "Custom, $np, $teps_cust" >> $RESULTS_STRONG
done

echo "Démarrage Weak Scaling (Threads: $OMP_NUM_THREADS)"
for i in ${!NPS_MPI[@]}; do
    np=${NPS_MPI[$i]}
    scale=${SCALES_WEAK[$i]}
    
    echo "Ref MPI - np $np (SCALE $scale)"
    out_ref=$(mpirun --oversubscribe -np $np ./graph500_reference_bfs $scale)
    teps_ref=$(echo "$out_ref" | grep "bfs  harmonic_mean_TEPS:" | awk '{print $4}')
    echo "Référence, $np, $scale, $teps_ref" >> $RESULTS_WEAK

    echo "Custom Hybride - np $np (SCALE $scale)"
    out_cust=$(mpirun --oversubscribe -np $np ./graph500_custom_bfs $scale)
    teps_cust=$(echo "$out_cust" | grep "bfs  harmonic_mean_TEPS:" | awk '{print $4}')
    echo "Custom, $np, $scale, $teps_cust" >> $RESULTS_WEAK
done

# TEST 3 : OPENMP SCALING
# On fige MPI à 2 processus, et on fait varier OpenMP de 1 à 6 (L'idée, encore une fois, est d'arriver au nombre de coeur physiques de la machine sur laquelle on travaille)

NP_FIXED=2
THREADS_ARRAY=(1 2 4 6)

echo "Démarrage OpenMP Scaling (MPI fixé à np=$NP_FIXED, SCALE $SCALE_STRONG)"
for t in "${THREADS_ARRAY[@]}"; do
    export OMP_NUM_THREADS=$t
    echo "Custom Hybride - Threads OpenMP: $t"
    
    out_cust=$(mpirun --oversubscribe -np $NP_FIXED ./graph500_custom_bfs $SCALE_STRONG)
    teps_cust=$(echo "$out_cust" | grep "bfs  harmonic_mean_TEPS:" | awk '{print $4}')
    
    echo "Custom, $NP_FIXED, $t, $teps_cust" >> $RESULTS_OMP
done

echo "Benchmarks terminés"