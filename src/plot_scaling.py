import pandas as pd
import matplotlib.pyplot as plt

try:
    df_strong = pd.read_csv('strong_scaling_results.csv', skipinitialspace=True)
    plt.figure(figsize=(10, 5))
    plt.plot(df_strong['Cœurs(np)'], df_strong['BFS_TEPS'], marker='o', label='BFS (Parcours en largeur)')
    plt.plot(df_strong['Cœurs(np)'], df_strong['SSSP_TEPS'], marker='s', label='SSSP (Plus court chemin)')
    
    plt.title('Strong Scaling (Graphe de taille fixe : SCALE 22)')
    plt.xlabel('Nombre de processus MPI (Cœurs)')
    plt.ylabel('Performance (TEPS - Liens/sec)')
    plt.grid(True, linestyle='--', alpha=0.7)
    plt.legend()
    plt.xticks(df_strong['Cœurs(np)'])
    plt.savefig('strong_scaling_MPI_pur.png', dpi=300)
    print("✅ Graphique Strong Scaling généré : strong_scaling_MPI_pur.png")
except Exception as e:
    print("Erreur avec le Strong Scaling :", e)


try:
    df_weak = pd.read_csv('weak_scaling_results.csv', skipinitialspace=True)
    plt.figure(figsize=(10, 5))
    plt.plot(df_weak['Cœurs(np)'], df_weak['BFS_TEPS'], marker='o', color='green', label='BFS')
    plt.plot(df_weak['Cœurs(np)'], df_weak['SSSP_TEPS'], marker='s', color='orange', label='SSSP')
    
    plt.title('Weak Scaling (Taille proportionnelle aux cœurs)')
    plt.xlabel('Nombre de processus MPI (Cœurs)')
    plt.ylabel('Performance (TEPS - Liens/sec)')
    plt.grid(True, linestyle='--', alpha=0.7)
    plt.legend()
    plt.xticks(df_weak['Cœurs(np)'])
    plt.savefig('weak_scaling_MPI_pur.png', dpi=300)
    print("✅ Graphique Weak Scaling généré : weak_scaling_MPI_pur.png")
except Exception as e:
    print("Erreur avec le Weak Scaling :", e)