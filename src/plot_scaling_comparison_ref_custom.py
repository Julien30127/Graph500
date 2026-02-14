import pandas as pd
import matplotlib.pyplot as plt

def plot_strong_scaling():
    try:
        # Lecture du CSV en ignorant les espaces après les virgules
        df = pd.read_csv('strong_scaling_comparison.csv', skipinitialspace=True)
        
        plt.figure(figsize=(10, 6))
        
        # Séparation des données
        ref_data = df[df['Version'] == 'REFERENCE']
        cust_data = df[df['Version'] == 'CUSTOM']
        
        # Tracé des courbes
        plt.plot(ref_data['Coeurs(np)'], ref_data['BFS_TEPS'], marker='o', linestyle='--', color='red', label='Référence (MPI Pur)')
        plt.plot(cust_data['Coeurs(np)'], cust_data['BFS_TEPS'], marker='s', linestyle='-', color='blue', linewidth=2, label='Custom (Hybride MPI+OpenMP)')
        
        # Esthétique du graphique
        plt.title('Strong Scaling - Performance du BFS (Taille de graphe fixe)', fontsize=14, fontweight='bold')
        plt.xlabel('Nombre de Processus MPI (np)', fontsize=12)
        plt.ylabel('Performance (TEPS - Traversed Edges Per Second)', fontsize=12)
        plt.xticks(df['Coeurs(np)'].unique())
        plt.grid(True, which="both", ls="--", alpha=0.6)
        plt.legend(fontsize=12)
        
        # Sauvegarde
        plt.savefig('strong_scaling_plot_comparison.png', dpi=300, bbox_inches='tight')
        print("Graphique Strong Scaling généré : strong_scaling_plot_comparison.png")
        
    except FileNotFoundError:
        print("Erreur : Le fichier strong_scaling_comparison.csv est introuvable.")

def plot_weak_scaling():
    try:
        df = pd.read_csv('weak_scaling_comparison.csv', skipinitialspace=True)
        
        plt.figure(figsize=(10, 6))
        
        ref_data = df[df['Version'] == 'REFERENCE']
        cust_data = df[df['Version'] == 'CUSTOM']
        
        # Pour le weak scaling, on veut voir si la ligne reste horizontale
        plt.plot(ref_data['Coeurs(np)'], ref_data['BFS_TEPS'], marker='o', linestyle='--', color='red', label='Référence (MPI Pur)')
        plt.plot(cust_data['Coeurs(np)'], cust_data['BFS_TEPS'], marker='s', linestyle='-', color='blue', linewidth=2, label='Custom (Hybride MPI+OpenMP)')
        
        # Esthétique du graphique
        plt.title('Weak Scaling - Performance du BFS (Taille de graphe croissante)', fontsize=14, fontweight='bold')
        plt.xlabel('Nombre de Processus MPI (np)', fontsize=12)
        plt.ylabel('Performance (TEPS - Traversed Edges Per Second)', fontsize=12)
        
        # Ajout des labels X avec le SCALE correspondant
        x_labels = [f"np={row['Coeurs(np)']}\n(Scale {row['SCALE']})" for index, row in ref_data.iterrows()]
        plt.xticks(ref_data['Coeurs(np)'], x_labels)
        
        # On force l'axe Y à commencer à 0 pour bien voir la "platitude"
        plt.ylim(bottom=0)
        plt.grid(True, which="both", ls="--", alpha=0.6)
        plt.legend(fontsize=12)
        
        # Sauvegarde
        plt.savefig('weak_scaling_plot_comparison.png', dpi=300, bbox_inches='tight')
        print("Graphique Weak Scaling généré : weak_scaling_plot_comparison.png")
        
    except FileNotFoundError:
        print("Erreur : Le fichier weak_scaling_comparison.csv est introuvable.")

if __name__ == "__main__":
    print("Génération des graphiques.")
    plot_strong_scaling()
    plot_weak_scaling()