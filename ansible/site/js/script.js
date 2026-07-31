document.addEventListener('DOMContentLoaded', async () => {
    
    // --- ÉLÉMENTS DOM ---
    const appContainer = document.getElementById('app');
    const siteTitle = document.getElementById('siteTitle');
    const mainNav = document.getElementById('mainNav');
    const siteFooterText = document.getElementById('siteFooterText');
    const apiStatus = document.getElementById('apiStatus');
    
    // Panier DOM
    let cartItems = {};
    const cartBadge = document.getElementById('cartCount');
    const toast = document.getElementById('toast');
    let toastTimeout;
    
    const cartBtn = document.getElementById('cartBtn');
    const modal = document.getElementById('cartModal');
    const closeModal = document.getElementById('closeCartBtn');
    const cartItemsList = document.getElementById('cartItemsList');
    const cartTotalPrice = document.getElementById('cartTotalPrice');
    const checkoutBtn = document.getElementById('checkoutBtn');
    const checkoutStatus = document.getElementById('checkoutStatus');

    // --- INITIALISATION (FETCH CONFIG & PRODUCTS) ---
    try {
        // Appels parallèles pour aller plus vite
        const [configRes, productsRes, statusRes] = await Promise.all([
            fetch('/api/config'),
            fetch('/api/products'),
            fetch('/api/status')
        ]);
        
        const config = await configRes.json();
        const products = await productsRes.json();
        const status = await statusRes.json();
        
        // Mise à jour de l'interface globale
        apiStatus.innerHTML = `🟢 ${status.message}`;
        buildSite(config, products);
        
    } catch (error) {
        console.error("Erreur critique de l'API:", error);
        appContainer.innerHTML = `
            <div style="text-align:center; padding: 4rem; color: var(--primary-color);">
                <h2>Le serveur est momentanément indisponible</h2>
                <p>Impossible de joindre l'API MaBoule.</p>
            </div>
        `;
    }

    // --- CONSTRUCTION DU SITE ---
    function buildSite(config, products) {
        // 1. Config Header
        document.title = config.site_name;
        siteTitle.textContent = config.site_name;
        
        // Footer (Rich)
        const footer = document.querySelector('.footer');
        let footerLinksHtml = '';
        config.footer_links.forEach(link => {
            footerLinksHtml += `<li><a href="${link.url}">${link.label}</a></li>`;
        });
        
        footer.innerHTML = `
            <div class="footer-content">
                <div class="footer-col">
                    <h3>${config.site_name}</h3>
                    <p>${config.footer_about}</p>
                    <div id="apiStatus" style="font-size: 0.8rem; margin-top: 15px; color: #27ae60;">🟢 API Connectée</div>
                </div>
                <div class="footer-col">
                    <h3>Informations</h3>
                    <ul class="footer-links">
                        ${footerLinksHtml}
                    </ul>
                </div>
            </div>
            <div class="footer-bottom">
                <p>${config.footer_copyright}</p>
            </div>
        `;
        
        // 2. Navigation
        let navHtml = '';
        config.nav_links.forEach(link => {
            navHtml += `<a href="#${link.target}">${link.label}</a>`;
        });
        mainNav.innerHTML = navHtml;
        
        // 3. Corps de page (Hero + Heritage + Produits)
        let appHtml = `
            <section id="home" class="hero" style="background-image: url('${config.hero_image}');">
                <h1>${config.tagline}</h1>
                <p>${config.hero_description}</p>
            </section>
            
            <section id="heritage" class="heritage">
                <h2>${config.heritage_title}</h2>
                <p>${config.heritage_text}</p>
            </section>
            
            <section id="collection" class="collection">
                <h2 class="section-title">Notre Collection</h2>
                <div class="grid">
        `;
        
        products.forEach(p => {
            const badgeHtml = p.badge ? `<span class="badge">${p.badge}</span>` : '';
            appHtml += `
                <div class="card">
                    <div class="card-img-wrapper">
                        <img src="${p.image}" alt="${p.name}">
                        ${badgeHtml}
                    </div>
                    <div class="card-body">
                        <h3>${p.name}</h3>
                        <p>${p.description}</p>
                        <div class="card-footer">
                            <span class="price">${p.price.toFixed(2).replace('.', ',')} €</span>
                            <button class="btn btn-cart" data-id="${p.id}" data-name="${p.name}" data-price="${p.price}">Ajouter</button>
                        </div>
                    </div>
                </div>
            `;
        });
        
        appHtml += `
                </div>
            </section>
        `;
        
        appContainer.innerHTML = appHtml;
        
        // Attacher les événements du panier aux nouveaux boutons
        attachCartEvents();
        
        // Smooth scroll automatique pour les liens SPA
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                e.preventDefault();
                const target = document.querySelector(this.getAttribute('href'));
                if(target) {
                    const headerOffset = 80;
                    const elementPosition = target.getBoundingClientRect().top;
                    const offsetPosition = elementPosition + window.pageYOffset - headerOffset;
                    window.scrollTo({
                         top: offsetPosition,
                         behavior: "smooth"
                    });
                }
            });
        });
    }

    // --- LOGIQUE DU PANIER ---
    // cartItems est maintenant un dictionnaire: id -> {id, name, price, quantity}
    
    function updateCartDisplay() {
        let totalItems = 0;
        let totalPrice = 0;
        let html = "";
        
        for (const [id, item] of Object.entries(cartItems)) {
            totalItems += item.quantity;
            totalPrice += item.price * item.quantity;
            html += `
                <div class="cart-item">
                    <span>${item.name} <strong style="color:var(--primary-color)">x${item.quantity}</strong></span>
                    <span style="font-weight: 600;">${(item.price * item.quantity).toFixed(2).replace('.', ',')} €</span>
                </div>
            `;
        }
        
        cartBadge.textContent = totalItems;
        
        if (totalItems === 0) {
            cartItemsList.innerHTML = "<p>Votre panier est vide.</p>";
            checkoutBtn.disabled = true;
            cartTotalPrice.textContent = "0.00";
            return;
        }

        checkoutBtn.disabled = false;
        cartItemsList.innerHTML = html;
        cartTotalPrice.textContent = totalPrice.toFixed(2);
    }

    function attachCartEvents() {
        document.querySelectorAll('.btn-cart').forEach(button => {
            button.addEventListener('click', () => {
                const id = button.getAttribute('data-id');
                const name = button.getAttribute('data-name');
                const price = parseFloat(button.getAttribute('data-price'));
                
                if (cartItems[id]) {
                    cartItems[id].quantity += 1;
                } else {
                    cartItems[id] = { id: parseInt(id), name, price, quantity: 1 };
                }
                
                updateCartDisplay();

                const originalText = button.textContent;
                button.textContent = "✓";
                button.style.backgroundColor = "#27ae60";
                setTimeout(() => {
                    button.textContent = originalText;
                    button.style.backgroundColor = "";
                }, 1000);

                cartBadge.style.transform = "scale(1.5)";
                setTimeout(() => { cartBadge.style.transform = "scale(1)"; }, 200);

                toast.textContent = `${name} ajouté !`;
                toast.classList.add('show');
                clearTimeout(toastTimeout);
                toastTimeout = setTimeout(() => { toast.classList.remove('show'); }, 3000);
            });
        });
    }

    // Modale
    cartBtn.addEventListener('click', () => {
        modal.classList.add('active');
        checkoutStatus.style.display = 'none';
    });
    
    closeModal.addEventListener('click', () => {
        modal.classList.remove('active');
    });

    modal.addEventListener('click', (e) => {
        if (e.target === modal) modal.classList.remove('active');
    });

    // Paiement API (Sécurisé)
    checkoutBtn.addEventListener('click', async () => {
        checkoutBtn.disabled = true;
        checkoutBtn.textContent = "Vérification sécurisée...";
        checkoutStatus.style.display = 'block';
        checkoutStatus.style.color = 'var(--text-color)';
        checkoutStatus.textContent = "Calcul du montant par le serveur...";

        // On n'envoie plus le prix total, on envoie juste l'ID et la quantité
        const payload = {
            items: Object.values(cartItems).map(item => ({
                product_id: item.id,
                quantity: item.quantity
            }))
        };

        try {
            const response = await fetch('/api/checkout', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            const data = await response.json();
            
            if(data.success) {
                checkoutStatus.style.color = '#27ae60';
                checkoutStatus.innerHTML = `✅ ${data.message} <br> <small style="color:#777">ID: ${data.transaction_id}</small>`;
                cartItems = {}; // Vider le panier
                updateCartDisplay();
                checkoutBtn.textContent = "Validé";
            } else {
                // Erreur venant de l'API (ex: 400 Bad Request)
                checkoutStatus.style.color = 'var(--primary-color)';
                checkoutStatus.textContent = "Erreur : " + (data.detail || "Refusé.");
                checkoutBtn.disabled = false;
                checkoutBtn.textContent = "Payer";
            }
        } catch(error) {
            checkoutStatus.style.color = 'var(--primary-color)';
            checkoutStatus.textContent = "Échec de connexion au serveur.";
            checkoutBtn.disabled = false;
            checkoutBtn.textContent = "Payer";
        }
    });

});
