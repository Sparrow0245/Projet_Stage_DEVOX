/**
 * Sentinelle V4 - Dashboard Dynamic Fetcher
 */
document.addEventListener('DOMContentLoaded', () => {
    console.log('[Sentinelle V4] Initialisation du tableau de bord...');

    function formatVal(val) {
        if (val === undefined || val === null) return '--';
        return parseFloat(val).toFixed(1);
    }

    function updateDashboard() {
        // Utilisation d'un chemin relatif pour fonctionner quel que soit le DocumentRoot
        fetch('api/metrics.php')
            .then(response => {
                if (!response.ok) throw new Error('Erreur HTTP ' + response.status);
                return response.json();
            })
            .then(res => {
                if (res.status === 'success' && res.data && res.data.length > 0) {
                    const latest = res.data[0]; // Dernier relevé en BDD

                    // Recherche dynamique des éléments d'affichage (cartes)
                    updateCardValue('cpu', latest.cpu_usage);
                    updateCardValue('ram', latest.ram_usage);
                    updateCardValue('disk', latest.disk_usage);
                    updateCardValue('swap', latest.swap_usage || 0);
                }
            })
            .catch(err => console.error('[Sentinelle V4] Erreur API metrics:', err));

        // Récupération des événements et alertes
        fetch('api/events.php')
            .then(response => response.json())
            .then(res => {
                if (res.status === 'success' && res.data) {
                    renderEvents(res.data);
                }
            })
            .catch(err => console.error('[Sentinelle V4] Erreur API events:', err));
    }

    function updateCardValue(type, val) {
        // Recherche par ID ou par texte parent
        const el = document.getElementById(`${type}-val`) || 
                   document.getElementById(`${type}_val`) ||
                   document.getElementById(type);
        
        if (el) {
            el.textContent = `${formatVal(val)} %`;
        } else {
            // Stratégie de secours : recherche par étiquette dans les cartes
            const cards = document.querySelectorAll('.card, div');
            cards.forEach(card => {
                if (card.children.length > 0 && card.children[0].textContent.trim().toLowerCase() === type.toLowerCase()) {
                    const valContainer = card.querySelector('h2, span, p, .value');
                    if (valContainer) valContainer.textContent = `${formatVal(val)} %`;
                }
            });
        }
    }

    function renderEvents(events) {
        const tbody = document.querySelector('table tbody');
        if (!tbody || events.length === 0) return;

        tbody.innerHTML = '';
        events.slice(0, 10).forEach(ev => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>${ev.created_at || ev.timestamp || '--'}</td>
                <td>${ev.type || 'INFO'}</td>
                <td><span class="badge ${ev.severity || 'low'}">${ev.severity || 'INFO'}</span></td>
                <td>${ev.message || ev.description || ''}</td>
            `;
            tbody.appendChild(tr);
        });
    }

    // Premier chargement + rafraîchissement automatique toutes les 5 secondes
    updateDashboard();
    setInterval(updateDashboard, 5000);
});
