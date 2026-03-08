"""
Database models for Cheteni API
"""
from datetime import datetime
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class Admin(db.Model):
    __tablename__ = 'admin'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(100), unique=True, nullable=False, index=True)
    username = db.Column(db.String(50), unique=True, nullable=False, index=True)
    password = db.Column(db.String(200), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login = db.Column(db.DateTime)

class Customer(db.Model):
    __tablename__ = 'customer'
    
    phone = db.Column(db.String(15), primary_key=True)
    name = db.Column(db.String(50))
    email = db.Column(db.String(100), index=True)
    fcm_token = db.Column(db.String(255))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    is_active = db.Column(db.Boolean, default=True)
    
    # Relationships
    orders = db.relationship('Order', backref='customer', lazy='dynamic')

class DeliveryPersonnel(db.Model):
    __tablename__ = 'delivery_personnel'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), nullable=False)
    phone = db.Column(db.String(15), unique=True, nullable=False, index=True)
    plate_number = db.Column(db.String(20), unique=True, nullable=False, index=True)
    route = db.Column(db.String(100))
    status = db.Column(db.String(20), default='available', index=True)
    agent_id = db.Column(db.Integer, db.ForeignKey('agent.id'))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    rating = db.Column(db.Float, default=0.0)
    total_deliveries = db.Column(db.Integer, default=0)
    
    # Relationships
    orders = db.relationship('Order', backref='delivery_personnel', lazy='dynamic')

class Agent(db.Model):
    __tablename__ = 'agent'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), nullable=False)
    id_number = db.Column(db.String(20), unique=True, nullable=False, index=True)
    email = db.Column(db.String(100), unique=True, nullable=False, index=True)
    phone = db.Column(db.String(15), unique=True, nullable=False, index=True)
    password = db.Column(db.String(200), nullable=False)
    market_location = db.Column(db.String(100), nullable=False)
    status = db.Column(db.String(20), default='active', index=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login = db.Column(db.DateTime)
    
    # Relationships
    personnel = db.relationship('DeliveryPersonnel', backref='agent', lazy='dynamic')

class Order(db.Model):
    __tablename__ = 'order'
    
    id = db.Column(db.Integer, primary_key=True)
    customer_phone = db.Column(db.String(15), db.ForeignKey('customer.phone'), nullable=False, index=True)
    items_json = db.Column(db.Text, nullable=False)
    total = db.Column(db.Float, nullable=False)
    delivery_charge = db.Column(db.Float, default=0.0)
    service_charge = db.Column(db.Float, default=100.0)
    status = db.Column(db.String(20), default='pending', index=True)
    order_time = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    delivery_personnel_phone = db.Column(db.String(15), db.ForeignKey('delivery_personnel.phone'))
    personnel_payout_status = db.Column(db.String(20), default='pending')
    personnel_payout_amount = db.Column(db.Float, default=0.0)
    estimated_delivery = db.Column(db.DateTime)
    actual_delivery = db.Column(db.DateTime)
    
    # Location data
    pickup_latitude = db.Column(db.Float)
    pickup_longitude = db.Column(db.Float)
    delivery_latitude = db.Column(db.Float)
    delivery_longitude = db.Column(db.Float)

class Wallet(db.Model):
    __tablename__ = 'wallet'
    
    id = db.Column(db.Integer, primary_key=True)
    user_type = db.Column(db.String(20), nullable=False, index=True)
    user_id = db.Column(db.String(50), nullable=False, index=True)
    balance = db.Column(db.Float, default=0.0)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    __table_args__ = (db.UniqueConstraint('user_type', 'user_id', name='unique_wallet'),)
    
    # Relationships
    transactions = db.relationship('WalletTransaction', backref='wallet', lazy='dynamic')

class WalletTransaction(db.Model):
    __tablename__ = 'wallet_transaction'
    
    id = db.Column(db.Integer, primary_key=True)
    wallet_id = db.Column(db.Integer, db.ForeignKey('wallet.id'), nullable=False, index=True)
    type = db.Column(db.String(10), nullable=False, index=True)  # deposit, withdrawal, payment
    amount = db.Column(db.Float, nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    status = db.Column(db.String(20), default='success', index=True)
    reference = db.Column(db.String(100))
    description = db.Column(db.String(255))

class DeliveryCharges(db.Model):
    __tablename__ = 'delivery_charges'
    
    id = db.Column(db.Integer, primary_key=True)
    base_charge = db.Column(db.Float, default=150.0)
    per_km_charge = db.Column(db.Float, default=87.5)
    minimum_charge = db.Column(db.Float, default=150.0)
    maximum_charge = db.Column(db.Float, default=500.0)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class CommodityPrice(db.Model):
    __tablename__ = 'commodity_price'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), unique=True, nullable=False, index=True)
    price = db.Column(db.Float, nullable=False)
    unit = db.Column(db.String(10), default='KG')
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class Advertisement(db.Model):
    __tablename__ = 'advertisement'
    
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    content = db.Column(db.Text, nullable=False)
    image_url = db.Column(db.String(255))
    link_url = db.Column(db.String(255))
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    expires_at = db.Column(db.DateTime)
    priority = db.Column(db.Integer, default=1)

class AuditLog(db.Model):
    __tablename__ = 'audit_log'
    
    id = db.Column(db.Integer, primary_key=True)
    user_type = db.Column(db.String(20), nullable=False)
    user_id = db.Column(db.String(50), nullable=False)
    action = db.Column(db.String(100), nullable=False)
    resource = db.Column(db.String(100))
    resource_id = db.Column(db.String(50))
    timestamp = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    ip_address = db.Column(db.String(45))
    user_agent = db.Column(db.String(255))