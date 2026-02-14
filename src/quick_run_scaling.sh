# On force le mode pur MPI (1 seul thread par processus) pour le test
export OMP_NUM_THREADS=1

echo "MPI sur 1 seul Cœur (SCALE 20)"
mpirun --oversubscribe -np 1 ./graph500_reference_bfs_sssp 20 | grep "bfs  harmonic_mean_TEPS"


echo "MPI sur 8 Cœurs (SCALE 20)"
mpirun --oversubscribe -np 8 ./graph500_reference_bfs_sssp 20 | grep "bfs  harmonic_mean_TEPS"