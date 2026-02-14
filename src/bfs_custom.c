#include "common.h"
#include "aml.h"
#include "csr_reference.h"
#include "bitmap_reference.h"
#include <stdint.h>
#include <inttypes.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <limits.h>
#include <assert.h>
#include <omp.h>

// Structure pour les messages
typedef struct visitmsg {
    int vloc;
    int vfrom;
} visitmsg;

// Double buffer (comme la référence)
int *q1, *q2;
int qc, q2c;

//VISITED bitmap parameters
unsigned long *visited;
int64_t visited_size;

int64_t *pred_glob, *column;
unsigned int *rowstarts;
oned_csr_graph g;

// Le Handler (exécutée sur le nœud receveur)
void visithndl(int from, void* data, int sz) {
    if (!pred_glob || !visited || !q2) return; 
    
    visitmsg *m = data;
    int v_loc = m->vloc;
    
    unsigned long mask = 1UL << (v_loc % ulong_bits);
    unsigned long old_val = __sync_fetch_and_or(&visited[v_loc / ulong_bits], mask);

    if (!(old_val & mask)) { 
        // Reconstitution magique du parent global
        pred_glob[v_loc] = VERTEX_TO_GLOBAL(from, m->vfrom);
        
        int my_spot;
        #pragma omp atomic capture
        {
            my_spot = q2c; 
            q2c++; 
        }
        q2[my_spot] = v_loc;
    }
}

void make_graph_data_structure(const tuple_graph* const tg) {
    
    convert_graph_to_oned_csr(tg, &g);
    column = g.column;
    rowstarts = g.rowstarts;

    visited_size = (g.nlocalverts + ulong_bits - 1) / ulong_bits;
    visited = xmalloc(visited_size * sizeof(unsigned long));

    q1 = xmalloc(g.nlocalverts * sizeof(int));
    q2 = xmalloc(g.nlocalverts * sizeof(int));
    
    // Touch memory 
    for(int i = 0; i < g.nlocalverts; i++) {
        q1[i] = 0;
        q2[i] = 0;
    }

    aml_register_handler(visithndl, 1);
}

//user should provide this function which would be called several times to do kernel 2: breadth first search
//pred[] should be root for root, -1 for unrechable vertices
//prior to calling run_bfs pred is set to -1 by calling clean_pred
void run_bfs(int64_t root, int64_t* pred) {
    
    // Connection avec le pointeur global
    pred_glob = pred;
    aml_register_handler(visithndl, 1);

    // Nettoyage du tableau visited
    memset(visited, 0, visited_size * sizeof(unsigned long));

    qc = 0; 
    q2c = 0;
    long sum = 1;

    // Pour le processus qui possède la racine :
    if (VERTEX_OWNER(root) == aml_my_pe()) { 
        int local_root = VERTEX_LOCAL(root);
        visited[local_root / ulong_bits] |= (1UL << (local_root % ulong_bits));
        pred[local_root] = root;
        q1[0] = local_root; 
        qc = 1; 
    }

    // Tant qu'au moins un nœud sur le supercalculateur a quelque chose à traiter
    while (sum > 0) {
    
    // Parallelisation de la lecture de la file q1
    #pragma omp parallel for
        for (int i = 0; i < qc; i++) {
            
            // Chaque thread pioche un sommet
            int u_local = q1[i];
            
            // Nom global ?
            int64_t u_global = VERTEX_TO_GLOBAL(aml_my_pe(), u_local);

            // On récupère les limites pour lire ses voisins dans le graphe CSR
            unsigned int start = rowstarts[u_local]; 
            unsigned int end   = rowstarts[u_local + 1];

            // On boucle sur eux
            for (unsigned int j = start; j < end; j++) {
                
                int64_t v_global = COLUMN(j); 

                // À qui est ce voisin ?
                if (VERTEX_OWNER(v_global) == aml_my_pe()) {
                    
                    // CAS 1 : Sur "notre" noeud
                    int v_local = VERTEX_LOCAL(v_global);
                    unsigned long mask = 1UL << (v_local % ulong_bits);
                    
                    unsigned long old_val = __sync_fetch_and_or(&visited[v_local / ulong_bits], mask);

                    // Si l'ancienne valeur ne contenait pas déjà ce bit à 1 
                    if (!(old_val & mask)) { 
                        pred[v_local] = u_global;

                        int my_spot;
                        #pragma omp atomic capture
                        {
                            my_spot = q2c; 
                            q2c++; 
                        }
                        q2[my_spot] = v_local;
                    }
                } else {

                    // CAS 2 : Sur un autre noeud (aie aie aie, MPI -> rhyme)
                    int target_rank = VERTEX_OWNER(v_global);
    
                    visitmsg msg = {VERTEX_LOCAL(v_global), u_local}; 

                    // On envoie le message via AML (protégé -> potentiel goulot d'étranglement si trop de rank MPI sur une "petite" machine)
                    #pragma omp critical
                    {
                        aml_send(&msg, 1, sizeof(visitmsg), target_rank);
                    }
                }
            }
        }
        
        // On attend la réception de tous les messages (qui vont remplir q2 via visithndl)
        aml_barrier();

        // Échange des buffers (q1 devient la nouvelle frontière)
        qc = q2c;
        int *tmp = q1; 
        q1 = q2; 
        q2 = tmp;

        // On synchronise avec tous les autres nœuds
        sum = qc;
        aml_long_allsum(&sum); 
        
        // On prépare le buffer de réception pour le prochain tour
        q2c = 0;
    }
    aml_barrier();
}

//we need edge count to calculate teps. Validation will check if this count is correct
//user should change this function if another format (not standart CRS) used
void get_edge_count_for_teps(int64_t* edge_visit_count) {
    long i,j;
    long edge_count=0;
    for(i=0;i<g.nlocalverts;i++)
        if(pred_glob[i]!=-1) {
            for(j=rowstarts[i];j<rowstarts[i+1];j++)
                // ICI AUSSI : LA MACRO MAGIQUE
                if(COLUMN(j)<=VERTEX_TO_GLOBAL(aml_my_pe(),i))
                    edge_count++;
        }
    aml_long_allsum(&edge_count);
    *edge_visit_count=edge_count;
}

//user provided function to initialize predecessor array to whatevere value user needs
void clean_pred(int64_t* pred) {
    int i;
    #pragma omp parallel for
    for(i=0;i<g.nlocalverts;i++) pred[i]=-1;
}

//user provided function to be called once graph is no longer needed
void free_graph_data_structure(void) {
    free_oned_csr_graph(&g);
    free(visited);
    free(q1); 
    free(q2);
}

//user should change is function if distribution(and counts) of vertices is changed
size_t get_nlocalverts_for_pred(void) {
    return g.nlocalverts;
}