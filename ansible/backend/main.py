import asyncio
import uuid
from typing import List, Optional
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from datetime import datetime

# --- CONFIGURATION BASE DE DONNÉES ---
SQLALCHEMY_DATABASE_URL = "sqlite:///./maboule.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# --- MODÈLES ORM ---
class ProductDB(Base):
    __tablename__ = "products"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    price = Column(Float)
    description = Column(String)
    image = Column(String)
    badge = Column(String, nullable=True)

class OrderDB(Base):
    __tablename__ = "orders"
    id = Column(Integer, primary_key=True, index=True)
    transaction_id = Column(String, unique=True, index=True)
    total_amount = Column(Float)
    created_at = Column(DateTime, default=datetime.utcnow)

Base.metadata.create_all(bind=engine)

# --- INITIALISATION DES DONNÉES ---
def init_db():
    db = SessionLocal()
    if db.query(ProductDB).count() == 0:
        default_products = [
            ProductDB(name="Édition Carbone Noir", price=189.0, description="Finition mate exclusive. Acier carbone trempé pour un rebond nul. Idéal pour les tireurs d'élite.", image="assets/product_hd.png", badge="Premium"),
            ProductDB(name="Inox Prestige", price=149.0, description="Brillance miroir et résistance extrême à l'oxydation. Le choix des pointeurs exigeants.", image="assets/product_hd.png", badge="Meilleure Vente"),
            ProductDB(name="Cochonnet Ébène", price=15.0, description="Bois d'ébène véritable, tourné à la main. Gravure or personnalisée.", image="assets/product_hd.png", badge=None)
        ]
        db.add_all(default_products)
        db.commit()
    db.close()

init_db()

# --- DÉPENDANCE DB ---
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- APPLICATION FASTAPI ---
app = FastAPI(title="MaBoule API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/config")
def get_config():
    return {
        "site_name": "MaBoule",
        "tagline": "L'Art de la Pétanque.",
        "hero_description": "Forgées dans l'acier le plus pur, nos boules incarnent l'excellence de l'artisanat français. Un équilibre parfait pour une précision absolue.",
        "hero_image": "assets/hero_hd.png",
        "heritage_title": "L'Héritage d'un Savoir-Faire",
        "heritage_text": "Depuis plus de 50 ans, MaBoule perpétue la tradition des maîtres forgerons. Chaque pièce est soigneusement calibrée, polie à la main, et soumise aux contrôles les plus stricts pour vous offrir un matériel de compétition inégalé.",
        "footer_about": "MaBoule conçoit des boules de pétanque d'exception pour les passionnés et les professionnels du monde entier.",
        "footer_links": [
            {"label": "Mentions Légales", "url": "#"},
            {"label": "Politique de Confidentialité", "url": "#"},
            {"label": "Nous contacter", "url": "#"}
        ],
        "footer_copyright": "© 2026 MaBoule - Design Premium & Qualité Française.",
        "nav_links": [
            {"label": "Accueil", "target": "home"},
            {"label": "L'Héritage", "target": "heritage"},
            {"label": "Collection", "target": "collection"}
        ]
    }

@app.get("/api/status")
def get_status():
    return {"status": "ok", "message": "MaBoule Backend (SQLite) opérationnel !"}

@app.get("/api/products")
def get_products(db: Session = Depends(get_db)):
    products = db.query(ProductDB).all()
    return products

# --- LOGIQUE PANIER SÉCURISÉE ---
class CartItem(BaseModel):
    product_id: int
    quantity: int

class CheckoutRequest(BaseModel):
    items: List[CartItem]

@app.post("/api/checkout")
async def process_checkout(request: CheckoutRequest, db: Session = Depends(get_db)):
    if not request.items:
        raise HTTPException(status_code=400, detail="Panier vide")
        
    total_calculated = 0.0
    
    # Validation du prix côté SERVEUR
    for item in request.items:
        product = db.query(ProductDB).filter(ProductDB.id == item.product_id).first()
        if not product:
            raise HTTPException(status_code=404, detail=f"Produit {item.product_id} introuvable")
        if item.quantity <= 0:
            raise HTTPException(status_code=400, detail="Quantité invalide")
            
        total_calculated += product.price * item.quantity

    # Simulation paiement
    await asyncio.sleep(1.0)
    
    transaction_id = f"MB-{str(uuid.uuid4()).split('-')[0].upper()}"
    
    # Enregistrer la commande en base de données
    new_order = OrderDB(
        transaction_id=transaction_id,
        total_amount=total_calculated
    )
    db.add(new_order)
    db.commit()
    
    return {
        "success": True, 
        "message": f"Paiement de {total_calculated:.2f} € validé et sécurisé.",
        "transaction_id": transaction_id,
        "total_paid": total_calculated
    }
