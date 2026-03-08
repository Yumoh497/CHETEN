"""
Cheteni Delivery Service Backend API
Secure, clean implementation with proper error handling and validation
"""

import os
import json
import math
import secrets
import logging
import threading
import smtplib
from datetime import datetime
from email.mime.text import MIMEText
from werkzeug.utils import secure_filename
import bcrypt
import requests
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

from flask import Flask, request, jsonify
from markupsafe import escape
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager, create_access_token, verify_jwt_in_request, get_jwt_identity
from models import db, Admin, Customer, DeliveryPersonnel, Agent, Order, Wallet, WalletTransaction, DeliveryCharges, CommodityPrice, Advertisement

# App configuration
app = Flask(__name__)

# Production configuration
database_url = os.environ.get('DATABASE_URL', 'sqlite:///cheteni.db')
# Fix for Heroku Postgres URL
if database_url.startswith('postgres://'):
    database_url = database_url.replace('postgres://', 'postgresql://', 1)

app.config['SQLALCHEMY_DATABASE_URI'] = database_url
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
# Generate secure keys if not provided
secret_key = os.environ.get('SECRET_KEY')
if not secret_key:
    secret_key = secrets.token_urlsafe(32)
    logging.warning('Using generated SECRET_KEY. Set SECRET_KEY environment variable for production.')

jwt_secret = os.environ.get('JWT_SECRET_KEY')
if not jwt_secret:
    jwt_secret = secrets.token_urlsafe(32)
    logging.warning('Using generated JWT_SECRET_KEY. Set JWT_SECRET_KEY environment variable for production.')

app.config['SECRET_KEY'] = secret_key
app.config['JWT_SECRET_KEY'] = jwt_secret
app.config['UPLOAD_FOLDER'] = 'cheteni_photos'
app.config['ENV'] = os.environ.get('FLASK_ENV', 'development')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size
app.config['PERMANENT_SESSION_LIFETIME'] = 3600  # 1 hour session timeout

# CORS configuration for production
from flask_cors import CORS
allowed_origins = os.environ.get('ALLOWED_ORIGINS', '*')
if allowed_origins != '*':
    allowed_origins = allowed_origins.split(',')
CORS(app, origins=allowed_origins, supports_credentials=True)

# Initialize extensions
db.init_app(app)
jwt = JWTManager(app)

# Create upload directory
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# Logging setup
log_level = logging.INFO if os.environ.get('FLASK_ENV') == 'production' else logging.DEBUG
logging.basicConfig(
    level=log_level,
    format='%(asctime)s %(levelname)s %(name)s %(message)s',
    handlers=[
        logging.FileHandler('cheteni_error.log'),
        logging.StreamHandler()  # Also log to console
    ]
)
logger = logging.getLogger(__name__)

# Utility functions
def hash_password(password):
    """Hash password using bcrypt"""
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def check_password(password, hashed):
    """Verify password against hash"""
    if not password or not hashed:
        return False
    try:
        return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))
    except (ValueError, TypeError, AttributeError) as e:
        logger.warning(f"Password check failed: {str(e)}")
        return False
    except Exception as e:
        logger.error(f"Unexpected error in password check: {str(e)}")
        return False

def validate_phone(phone):
    """Validate phone number format"""
    if not phone or not isinstance(phone, str):
        return False
    # Remove any non-digit characters and check length
    clean_phone = ''.join(filter(str.isdigit, phone))
    return 10 <= len(clean_phone) <= 15

def validate_email(email):
    """Basic email validation"""
    if not email or not isinstance(email, str):
        return False
    import re
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email.strip()) is not None

def sanitize_input(text):
    """Sanitize user input to prevent XSS"""
    if not text:
        return ""
    return escape(str(text))

def validate_order_data(data):
    """Validate order placement data"""
    required_fields = ['customer_phone', 'items']
    for field in required_fields:
        if field not in data or not data[field]:
            return False, f"Missing required field: {field}"
    
    if not validate_phone(data['customer_phone']):
        return False, "Invalid phone number"
    
    if not isinstance(data['items'], list) or len(data['items']) == 0:
        return False, "Items must be a non-empty list"
    
    return True, "Valid"

def get_current_admin():
    """Get current authenticated admin"""
    try:
        verify_jwt_in_request(optional=True)
        identity = get_jwt_identity()
        if identity:
            admin = Admin.query.filter_by(username=identity).first()
            if admin:
                return admin
    except Exception as e:
        logger.warning(f"JWT verification failed: {str(e)}")
    
    # Fallback to basic auth
    try:
        auth = request.authorization
        if auth and auth.username and auth.password:
            admin = Admin.query.filter_by(username=auth.username).first()
            if admin and check_password(auth.password, admin.password):
                return admin
    except Exception as e:
        logger.warning(f"Basic auth failed: {str(e)}")
    
    return None

def get_or_create_wallet(user_type, user_id):
    """Get or create wallet for user"""
    if user_type not in ['customer', 'driver', 'agent']:
        raise ValueError(f"Invalid user type: {user_type}")
    
    if not user_id or not isinstance(user_id, str):
        raise ValueError("Invalid user ID")
    
    try:
        wallet = Wallet.query.filter_by(user_type=user_type, user_id=user_id).first()
        if not wallet:
            wallet = Wallet(user_type=user_type, user_id=user_id, balance=0.0)
            db.session.add(wallet)
            db.session.commit()
        return wallet
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error creating wallet: {str(e)}")
        raise

def calculate_delivery_charge(distance_miles, weight_kg):
    """Calculate delivery charge based on distance and weight"""
    try:
        distance = float(distance_miles) if distance_miles is not None else 1.0
        weight = float(weight_kg) if weight_kg is not None else 1.0
        
        # Base charge by distance
        if distance <= 1:
            base_charge = 150
        elif distance >= 5:
            base_charge = 500
        else:
            base_charge = int(150 + (distance - 1) * (500 - 150) / (5 - 1))
        
        # Weight adjustment
        if weight <= 50:
            delivery_charge = base_charge
        elif weight <= 100:
            delivery_charge = base_charge + 50
        else:
            multiplier = math.ceil(weight / 100)
            delivery_charge = base_charge * multiplier
            
        return delivery_charge
    except (ValueError, TypeError):
        return 150  # Default charge

# Routes
@app.route('/')
def home():
    return jsonify({'message': 'Cheteni is running', 'version': '1.0'})

@app.route('/register_customer', methods=['POST'])
def register_customer():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        phone = data.get('phone', '').strip()
        name = sanitize_input(data.get('name', ''))
        email = data.get('email', '').strip()
        
        # Validate required fields
        if not phone:
            return jsonify({'success': False, 'message': 'Phone number is required'}), 400
            
        if not validate_phone(phone):
            return jsonify({'success': False, 'message': 'Invalid phone number format'}), 400
        
        if email and not validate_email(email):
            return jsonify({'success': False, 'message': 'Invalid email address format'}), 400
        
        # Check if customer exists
        existing = Customer.query.filter_by(phone=phone).first()
        if existing:
            return jsonify({'success': False, 'message': 'Customer already registered with this phone number'}), 409
        
        # Create customer
        customer = Customer(phone=phone, name=name, email=email)
        db.session.add(customer)
        db.session.commit()
        
        logger.info(f"Customer registered successfully: {phone}")
        return jsonify({
            'success': True,
            'customer': {'phone': phone, 'name': name, 'email': email}
        }), 201
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error registering customer: {str(e)}")
        return jsonify({'success': False, 'message': 'Registration failed'}), 500

@app.route('/register_delivery_personnel', methods=['POST'])
def register_delivery_personnel():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        name = sanitize_input(data.get('name', '').strip())
        phone = data.get('phone', '').strip()
        plate_number = data.get('plate_number', '').strip().upper()
        route = sanitize_input(data.get('route', '').strip())
        
        # Validate required fields
        if not name:
            return jsonify({'success': False, 'message': 'Name is required'}), 400
        if not phone:
            return jsonify({'success': False, 'message': 'Phone number is required'}), 400
        if not plate_number:
            return jsonify({'success': False, 'message': 'Plate number is required'}), 400
        if not route:
            return jsonify({'success': False, 'message': 'Route is required'}), 400
        
        if not validate_phone(phone):
            return jsonify({'success': False, 'message': 'Invalid phone number format'}), 400
        
        # Check if personnel exists
        existing_phone = DeliveryPersonnel.query.filter_by(phone=phone).first()
        if existing_phone:
            return jsonify({'success': False, 'message': 'Phone number already registered'}), 409
            
        existing_plate = DeliveryPersonnel.query.filter_by(plate_number=plate_number).first()
        if existing_plate:
            return jsonify({'success': False, 'message': 'Plate number already registered'}), 409
        
        # Create delivery personnel
        personnel = DeliveryPersonnel(
            name=name,
            phone=phone,
            plate_number=plate_number,
            route=route
        )
        db.session.add(personnel)
        db.session.commit()
        
        logger.info(f"Delivery personnel registered: {name} - {phone}")
        return jsonify({
            'success': True,
            'personnel': {'id': personnel.id, 'name': name, 'phone': phone, 'plate_number': plate_number}
        }), 201
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error registering delivery personnel: {str(e)}")
        return jsonify({'success': False, 'message': 'Registration failed'}), 500

@app.route('/place_order', methods=['POST'])
def place_order():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        # Validate order data
        is_valid, error_msg = validate_order_data(data)
        if not is_valid:
            return jsonify({'success': False, 'message': error_msg}), 400
        
        customer_phone = data.get('customer_phone', '').strip()
        items = data.get('items', [])
        distance_miles = data.get('distance_miles', 1)
        weight_kg = data.get('weight_kg', 1)
        
        # Validate customer exists
        customer = Customer.query.filter_by(phone=customer_phone).first()
        if not customer:
            return jsonify({'success': False, 'message': 'Customer not found. Please register first.'}), 404
        
        # Validate and calculate totals
        total_cost = 0
        validated_items = []
        
        for item in items:
            try:
                name = sanitize_input(item.get('name', 'Unknown Item'))
                price = float(item.get('price', 0))
                quantity = int(item.get('quantity', 1))
                
                if price < 0:
                    return jsonify({'success': False, 'message': 'Item price cannot be negative'}), 400
                if quantity <= 0:
                    return jsonify({'success': False, 'message': 'Item quantity must be positive'}), 400
                
                item_total = price * quantity
                total_cost += item_total
                
                validated_items.append({
                    'name': name,
                    'price': price,
                    'quantity': quantity,
                    'total': item_total
                })
                
            except (ValueError, TypeError) as e:
                return jsonify({'success': False, 'message': f'Invalid item data: {str(e)}'}), 400
        
        if total_cost <= 0:
            return jsonify({'success': False, 'message': 'Order total must be greater than zero'}), 400
        
        # Calculate charges
        service_charge = 100.0
        delivery_charge = calculate_delivery_charge(distance_miles, weight_kg)
        grand_total = total_cost + service_charge + delivery_charge
        
        # Create order
        order = Order(
            customer_phone=customer_phone,
            items_json=json.dumps(validated_items),
            total=grand_total,
            delivery_charge=delivery_charge,
            service_charge=service_charge,
            status='pending'
        )
        db.session.add(order)
        db.session.commit()
        
        logger.info(f"Order placed successfully: {order.id} for customer {customer_phone}")
        return jsonify({
            'success': True,
            'order_id': order.id,
            'total': grand_total,
            'items_total': total_cost,
            'delivery_charge': delivery_charge,
            'service_charge': service_charge
        }), 201
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error placing order: {str(e)}")
        return jsonify({'success': False, 'message': 'Order placement failed'}), 500

@app.route('/track_delivery', methods=['GET'])
def track_delivery():
    try:
        customer_phone = request.args.get('customer_phone', '').strip()
        
        if not customer_phone:
            return jsonify({'success': False, 'message': 'Phone number is required'}), 400
            
        if not validate_phone(customer_phone):
            return jsonify({'success': False, 'message': 'Invalid phone number format'}), 400
        
        # Get latest order for customer
        order = Order.query.filter_by(customer_phone=customer_phone)\
                          .order_by(Order.order_time.desc()).first()
        
        if not order:
            return jsonify({'success': False, 'message': 'No orders found for this phone number'}), 404
        
        # Get delivery personnel info if assigned
        delivery_info = None
        if order.delivery_personnel_phone:
            personnel = DeliveryPersonnel.query.filter_by(phone=order.delivery_personnel_phone).first()
            if personnel:
                delivery_info = {
                    'name': personnel.name,
                    'phone': personnel.phone,
                    'plate_number': personnel.plate_number
                }
        
        return jsonify({
            'success': True,
            'order': {
                'id': order.id,
                'status': order.status,
                'total': order.total,
                'delivery_charge': order.delivery_charge,
                'service_charge': order.service_charge,
                'order_time': order.order_time.isoformat() if order.order_time else None,
                'delivery_personnel': delivery_info
            }
        })
        
    except Exception as e:
        logger.error(f"Error tracking delivery: {str(e)}")
        return jsonify({'success': False, 'message': 'Tracking failed'}), 500

@app.route('/admin/login', methods=['POST'])
def admin_login():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        username = data.get('username', '').strip()
        password = data.get('password', '')
        
        if not username or not password:
            return jsonify({'success': False, 'message': 'Username and password are required'}), 400
        
        # Rate limiting could be added here in production
        admin = Admin.query.filter_by(username=username).first()
        
        # Use constant-time comparison to prevent timing attacks
        if not admin:
            # Still check password to prevent timing attacks
            check_password('dummy', 'dummy')
            return jsonify({'success': False, 'message': 'Invalid credentials'}), 401
            
        if not check_password(password, admin.password):
            return jsonify({'success': False, 'message': 'Invalid credentials'}), 401
        
        # Create JWT token with expiration
        from datetime import timedelta
        token = create_access_token(
            identity=admin.username,
            expires_delta=timedelta(hours=8)  # 8 hour expiration
        )
        
        logger.info(f"Admin login successful: {username}")
        return jsonify({
            'success': True, 
            'token': token,
            'admin': {
                'username': admin.username,
                'email': admin.email
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error in admin login: {str(e)}")
        return jsonify({'success': False, 'message': 'Login failed'}), 500

@app.route('/wallet/<user_type>/<user_id>', methods=['GET'])
def get_wallet(user_type, user_id):
    try:
        if user_type not in ['customer', 'driver', 'agent']:
            return jsonify({'success': False, 'message': 'Invalid user type. Must be customer, driver, or agent'}), 400
        
        if not user_id or not user_id.strip():
            return jsonify({'success': False, 'message': 'User ID is required'}), 400
        
        wallet = get_or_create_wallet(user_type, user_id.strip())
        return jsonify({
            'success': True, 
            'balance': wallet.balance,
            'user_type': user_type,
            'user_id': user_id
        })
        
    except ValueError as e:
        return jsonify({'success': False, 'message': str(e)}), 400
    except Exception as e:
        logger.error(f"Error getting wallet: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to get wallet'}), 500



@app.route('/delivery_charges', methods=['GET'])
def get_delivery_charges():
    try:
        charges = DeliveryCharges.query.first()
        if not charges:
            charges = DeliveryCharges()
            db.session.add(charges)
            db.session.commit()
        
        return jsonify({
            'success': True,
            'data': {
                'base_charge': charges.base_charge,
                'per_km_charge': charges.per_km_charge,
                'minimum_charge': charges.minimum_charge,
                'maximum_charge': charges.maximum_charge
            }
        })
    except Exception as e:
        logger.error(f"Error getting delivery charges: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to get charges'}), 500

@app.route('/register_agent', methods=['POST'])
def register_agent():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        name = sanitize_input(data.get('name', '').strip())
        id_number = data.get('id_number', '').strip()
        email = data.get('email', '').strip().lower()
        phone = data.get('phone', '').strip()
        password = data.get('password', '')
        market_location = sanitize_input(data.get('market_location', '').strip())
        
        # Validate required fields
        if not name:
            return jsonify({'success': False, 'message': 'Name is required'}), 400
        if not id_number:
            return jsonify({'success': False, 'message': 'ID number is required'}), 400
        if not email:
            return jsonify({'success': False, 'message': 'Email is required'}), 400
        if not phone:
            return jsonify({'success': False, 'message': 'Phone number is required'}), 400
        if not password:
            return jsonify({'success': False, 'message': 'Password is required'}), 400
        if not market_location:
            return jsonify({'success': False, 'message': 'Market location is required'}), 400
        
        # Validate formats
        if not validate_phone(phone):
            return jsonify({'success': False, 'message': 'Invalid phone number format'}), 400
        if not validate_email(email):
            return jsonify({'success': False, 'message': 'Invalid email format'}), 400
        
        # Validate password strength
        if len(password) < 6:
            return jsonify({'success': False, 'message': 'Password must be at least 6 characters long'}), 400
        
        # Check for existing agent
        existing_email = Agent.query.filter_by(email=email).first()
        if existing_email:
            return jsonify({'success': False, 'message': 'Email already registered'}), 409
            
        existing_phone = Agent.query.filter_by(phone=phone).first()
        if existing_phone:
            return jsonify({'success': False, 'message': 'Phone number already registered'}), 409
            
        existing_id = Agent.query.filter_by(id_number=id_number).first()
        if existing_id:
            return jsonify({'success': False, 'message': 'ID number already registered'}), 409
        
        # Create agent
        agent = Agent(
            name=name,
            id_number=id_number,
            email=email,
            phone=phone,
            password=hash_password(password),
            market_location=market_location
        )
        db.session.add(agent)
        db.session.commit()
        
        logger.info(f"Agent registered successfully: {name} - {email}")
        return jsonify({
            'success': True,
            'agent': {
                'id': agent.id, 
                'name': name, 
                'email': email,
                'phone': phone,
                'market_location': market_location
            }
        }), 201
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error registering agent: {str(e)}")
        return jsonify({'success': False, 'message': 'Registration failed'}), 500

@app.route('/agent/login', methods=['POST'])
def agent_login():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        email = data.get('email', '').strip()
        password = data.get('password', '')
        
        if not email or not password:
            return jsonify({'success': False, 'message': 'Email and password required'}), 400
        
        agent = Agent.query.filter_by(email=email).first()
        if not agent or not check_password(password, agent.password):
            return jsonify({'success': False, 'message': 'Invalid credentials'}), 401
        
        token = create_access_token(identity=f"agent_{agent.id}")
        return jsonify({
            'success': True,
            'token': token,
            'agent': {'id': agent.id, 'name': agent.name, 'email': agent.email}
        }), 200
        
    except Exception as e:
        logger.error(f"Error in agent login: {str(e)}")
        return jsonify({'success': False, 'message': 'Login failed'}), 500

@app.route('/agent/orders', methods=['GET'])
def get_agent_orders():
    try:
        orders = Order.query.all()
        order_list = []
        for order in orders:
            order_list.append({
                'id': order.id,
                'customer_phone': order.customer_phone,
                'total': order.total,
                'status': order.status,
                'order_time': order.order_time.isoformat() if order.order_time else None,
                'delivery_personnel_phone': order.delivery_personnel_phone
            })
        
        return jsonify({'success': True, 'orders': order_list})
    except Exception as e:
        logger.error(f"Error getting agent orders: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to get orders'}), 500

@app.route('/driver/orders', methods=['GET'])
def get_driver_orders():
    try:
        driver_name = request.args.get('driver_name', '').strip()
        if not driver_name:
            return jsonify({'success': False, 'message': 'Driver name required'}), 400
        
        # Find driver by name
        driver = DeliveryPersonnel.query.filter_by(name=driver_name).first()
        if not driver:
            return jsonify({'success': False, 'message': 'Driver not found'}), 404
        
        # Get orders assigned to this driver
        orders = Order.query.filter_by(delivery_personnel_phone=driver.phone).all()
        order_list = []
        for order in orders:
            order_list.append({
                'id': order.id,
                'customer_phone': order.customer_phone,
                'total': order.total,
                'status': order.status,
                'order_time': order.order_time.isoformat() if order.order_time else None,
                'items': json.loads(order.items_json) if order.items_json else []
            })
        
        return jsonify({'success': True, 'data': {'orders': order_list}})
    except Exception as e:
        logger.error(f"Error getting driver orders: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to get orders'}), 500

@app.route('/driver/update_status', methods=['POST'])
def update_driver_order_status():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        customer_phone = data.get('customer_phone', '').strip()
        status = data.get('status', '').strip()
        driver_name = data.get('driver_name', '').strip()
        
        if not all([customer_phone, status, driver_name]):
            return jsonify({'success': False, 'message': 'All fields required'}), 400
        
        # Find and update order
        order = Order.query.filter_by(customer_phone=customer_phone).first()
        if not order:
            return jsonify({'success': False, 'message': 'Order not found'}), 404
        
        order.status = status
        db.session.commit()
        
        return jsonify({'success': True, 'message': 'Status updated'})
    except Exception as e:
        logger.error(f"Error updating order status: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to update status'}), 500

@app.route('/driver/confirm_delivery', methods=['POST'])
def driver_confirm_delivery():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        customer_phone = data.get('customer_phone', '').strip()
        driver_name = data.get('driver_name', '').strip()
        
        if not all([customer_phone, driver_name]):
            return jsonify({'success': False, 'message': 'Phone and driver name required'}), 400
        
        # Find and update order
        order = Order.query.filter_by(customer_phone=customer_phone).first()
        if not order:
            return jsonify({'success': False, 'message': 'Order not found'}), 404
        
        order.status = 'delivered'
        db.session.commit()
        
        return jsonify({'success': True, 'message': 'Delivery confirmed'})
    except Exception as e:
        logger.error(f"Error confirming delivery: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to confirm delivery'}), 500

@app.route('/driver/profile', methods=['GET'])
def get_driver_profile():
    try:
        driver_name = request.args.get('driver_name', '').strip()
        if not driver_name:
            return jsonify({'success': False, 'message': 'Driver name required'}), 400
        
        driver = DeliveryPersonnel.query.filter_by(name=driver_name).first()
        if not driver:
            return jsonify({'success': False, 'message': 'Driver not found'}), 404
        
        # Get driver statistics
        total_orders = Order.query.filter_by(delivery_personnel_phone=driver.phone).count()
        completed_orders = Order.query.filter_by(
            delivery_personnel_phone=driver.phone, status='delivered'
        ).count()
        
        return jsonify({
            'success': True,
            'data': {
                'name': driver.name,
                'phone': driver.phone,
                'plate_number': driver.plate_number,
                'route': driver.route,
                'status': driver.status,
                'total_orders': total_orders,
                'completed_deliveries': completed_orders
            }
        })
    except Exception as e:
        logger.error(f"Error getting driver profile: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to get profile'}), 500

@app.route('/agent/assign_order', methods=['POST'])
def assign_order_to_personnel():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        order_id = data.get('order_id')
        personnel_id = data.get('personnel_id')
        
        if not order_id or not personnel_id:
            return jsonify({'success': False, 'message': 'Order ID and personnel ID required'}), 400
        
        # Find order and personnel
        order = Order.query.get(order_id)
        personnel = DeliveryPersonnel.query.get(personnel_id)
        
        if not order or not personnel:
            return jsonify({'success': False, 'message': 'Order or personnel not found'}), 404
        
        # Assign order to personnel
        order.delivery_personnel_phone = personnel.phone
        order.status = 'assigned'
        personnel.status = 'busy'
        
        db.session.commit()
        
        return jsonify({'success': True, 'message': 'Order assigned successfully'})
    except Exception as e:
        logger.error(f"Error assigning order: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to assign order'}), 500

@app.route('/agent/reassign_order', methods=['POST'])
def reassign_order():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        order_id = data.get('order_id')
        new_personnel_id = data.get('new_personnel_id')
        
        if not order_id or not new_personnel_id:
            return jsonify({'success': False, 'message': 'Order ID and new personnel ID required'}), 400
        
        # Find order and new personnel
        order = Order.query.get(order_id)
        new_personnel = DeliveryPersonnel.query.get(new_personnel_id)
        
        if not order or not new_personnel:
            return jsonify({'success': False, 'message': 'Order or personnel not found'}), 404
        
        # Free up old personnel if assigned
        if order.delivery_personnel_phone:
            old_personnel = DeliveryPersonnel.query.filter_by(phone=order.delivery_personnel_phone).first()
            if old_personnel:
                old_personnel.status = 'available'
        
        # Assign to new personnel
        order.delivery_personnel_phone = new_personnel.phone
        order.status = 'assigned'
        new_personnel.status = 'busy'
        
        db.session.commit()
        
        return jsonify({'success': True, 'message': 'Order reassigned successfully'})
    except Exception as e:
        logger.error(f"Error reassigning order: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to reassign order'}), 500

@app.route('/agent/personnel_status', methods=['POST'])
def update_personnel_status():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        personnel_id = data.get('personnel_id')
        status = data.get('status')
        
        if not personnel_id or not status:
            return jsonify({'success': False, 'message': 'Personnel ID and status required'}), 400
        
        personnel = DeliveryPersonnel.query.get(personnel_id)
        if not personnel:
            return jsonify({'success': False, 'message': 'Personnel not found'}), 404
        
        personnel.status = status
        db.session.commit()
        
        return jsonify({'success': True, 'message': 'Personnel status updated'})
    except Exception as e:
        logger.error(f"Error updating personnel status: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to update status'}), 500

@app.route('/agent/dashboard', methods=['GET'])
def get_agent_dashboard_stats():
    try:
        total_orders = Order.query.count()
        pending_orders = Order.query.filter_by(status='pending').count()
        assigned_orders = Order.query.filter(Order.status.in_(['assigned', 'picked_up', 'in_transit'])).count()
        completed_orders = Order.query.filter_by(status='delivered').count()
        
        total_personnel = DeliveryPersonnel.query.count()
        available_personnel = DeliveryPersonnel.query.filter_by(status='available').count()
        busy_personnel = DeliveryPersonnel.query.filter_by(status='busy').count()
        
        return jsonify({
            'success': True,
            'stats': {
                'total_orders': total_orders,
                'pending_orders': pending_orders,
                'assigned_orders': assigned_orders,
                'completed_orders': completed_orders,
                'total_personnel': total_personnel,
                'available_personnel': available_personnel,
                'busy_personnel': busy_personnel
            }
        })
    except Exception as e:
        logger.error(f"Error getting dashboard stats: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to get stats'}), 500

@app.route('/agent/personnel', methods=['GET'])
def get_agent_personnel():
    try:
        personnel = DeliveryPersonnel.query.all()
        personnel_list = []
        for person in personnel:
            personnel_list.append({
                'id': person.id,
                'name': person.name,
                'phone': person.phone,
                'plate_number': person.plate_number,
                'route': person.route,
                'status': person.status
            })
        
        return jsonify({'success': True, 'personnel': personnel_list})
    except Exception as e:
        logger.error(f"Error getting personnel: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to get personnel'}), 500

@app.route('/admin/send_agent_number', methods=['POST'])
def send_agent_number():
    admin = get_current_admin()
    if not admin:
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        contact = data.get('contact', '').strip()
        agent_number = data.get('agent_number', '').strip()
        
        if not contact or not agent_number:
            return jsonify({'success': False, 'message': 'Contact and agent number required'}), 400
        
        # In a real implementation, you would send SMS/email here
        logger.info(f"Agent number {agent_number} sent to {contact}")
        
        return jsonify({'success': True, 'message': 'Agent number sent successfully'})
    except Exception as e:
        logger.error(f"Error sending agent number: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to send agent number'}), 500



@app.route('/admin/commodity_prices', methods=['GET'])
def get_commodity_prices():
    admin = get_current_admin()
    if not admin:
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
        prices = CommodityPrice.query.all()
        price_dict = {}
        for price in prices:
            price_dict[price.name] = price.price
        
        # Add default prices if none exist
        if not price_dict:
            defaults = {
                'Rice': 50.0, 'Maize': 45.0, 'Beans': 80.0, 'Tomatoes': 40.0,
                'Onions': 30.0, 'Potatoes': 35.0, 'Cabbage': 25.0, 'Carrots': 60.0,
                'Bananas': 20.0, 'Oranges': 50.0
            }
            for name, price in defaults.items():
                commodity = CommodityPrice(name=name, price=price)
                db.session.add(commodity)
            db.session.commit()
            price_dict = defaults
        
        return jsonify({'success': True, 'data': {'prices': price_dict}})
    except Exception as e:
        logger.error(f"Error getting commodity prices: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to get prices'}), 500

@app.route('/admin/drivers', methods=['GET'])
def get_all_drivers():
    admin = get_current_admin()
    if not admin:
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
        drivers = DeliveryPersonnel.query.all()
        driver_list = []
        for driver in drivers:
            driver_list.append({
                'id': driver.id,
                'name': driver.name,
                'phone': driver.phone,
                'plate_number': driver.plate_number,
                'route': driver.route,
                'status': driver.status
            })
        
        return jsonify({'success': True, 'data': driver_list})
    except Exception as e:
        logger.error(f"Error getting drivers: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to get drivers'}), 500

@app.route('/admin/reports', methods=['GET'])
def get_admin_reports():
    admin = get_current_admin()
    if not admin:
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
        # Calculate various statistics
        total_orders = Order.query.count()
        completed_orders = Order.query.filter_by(status='delivered').count()
        pending_orders = Order.query.filter_by(status='pending').count()
        
        total_sales = db.session.query(db.func.sum(Order.total)).filter_by(status='delivered').scalar() or 0
        avg_order_value = total_sales / completed_orders if completed_orders > 0 else 0
        
        total_customers = Customer.query.count()
        total_drivers = DeliveryPersonnel.query.count()
        active_drivers = DeliveryPersonnel.query.filter_by(status='busy').count()
        total_agents = Agent.query.count()
        active_agents = Agent.query.filter_by(status='active').count()
        
        # Calculate payouts (simplified)
        total_payouts = completed_orders * 50  # Assuming 50 KSh per delivery
        pending_payouts = Order.query.filter(
            Order.status == 'delivered',
            Order.personnel_payout_status == 'pending'
        ).count()
        
        reports = {
            'total_orders': total_orders,
            'orders_completed': completed_orders,
            'pending_orders': pending_orders,
            'total_sales': total_sales,
            'avg_order_value': round(avg_order_value, 2),
            'total_users': total_customers + total_drivers + total_agents,
            'active_customers': total_customers,
            'total_drivers': total_drivers,
            'active_drivers': active_drivers,
            'active_agents': active_agents,
            'total_payouts': total_payouts,
            'pending_payouts': pending_payouts,
            'new_signups': 5,  # Mock data
            'active_routes': 8,  # Mock data
        }
        
        return jsonify({'success': True, 'data': reports})
    except Exception as e:
        logger.error(f"Error getting reports: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to get reports'}), 500

@app.route('/admin/commodity_prices', methods=['POST'])
def update_commodity_prices():
    admin = get_current_admin()
    if not admin:
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
        data = request.get_json()
        if not data or 'prices' not in data:
            return jsonify({'success': False, 'message': 'No prices provided'}), 400
        
        prices = data['prices']
        for name, price in prices.items():
            try:
                price_float = float(price)
                commodity = CommodityPrice.query.filter_by(name=name).first()
                if commodity:
                    commodity.price = price_float
                    commodity.updated_at = datetime.utcnow()
                else:
                    commodity = CommodityPrice(name=name, price=price_float)
                    db.session.add(commodity)
            except (ValueError, TypeError):
                continue
        
        db.session.commit()
        return jsonify({'success': True, 'message': 'Prices updated successfully'})
    except Exception as e:
        logger.error(f"Error updating commodity prices: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to update prices'}), 500

@app.route('/admin/agents', methods=['GET'])
def get_all_agents():
    admin = get_current_admin()
    if not admin:
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
        agents = Agent.query.all()
        agent_list = []
        for agent in agents:
            agent_list.append({
                'id': agent.id,
                'name': agent.name,
                'email': agent.email,
                'phone': agent.phone,
                'market_location': agent.market_location,
                'status': agent.status,
                'created_at': agent.created_at.isoformat() if agent.created_at else None
            })
        
        return jsonify({'success': True, 'data': agent_list})
    except Exception as e:
        logger.error(f"Error getting agents: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to get agents'}), 500

@app.route('/admin/advertisements', methods=['GET'])
def get_advertisements():
    try:
        ads = Advertisement.query.filter_by(is_active=True).order_by(Advertisement.priority.desc()).all()
        ad_list = []
        for ad in ads:
            ad_list.append({
                'id': ad.id,
                'title': ad.title,
                'content': ad.content,
                'image_url': ad.image_url,
                'link_url': ad.link_url,
                'created_at': ad.created_at.isoformat() if ad.created_at else None
            })
        return jsonify({'success': True, 'data': ad_list})
    except Exception as e:
        logger.error(f"Error getting advertisements: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to get advertisements'}), 500

@app.route('/admin/advertisements', methods=['POST'])
def create_advertisement():
    admin = get_current_admin()
    if not admin:
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        title = sanitize_input(data.get('title', ''))
        content = sanitize_input(data.get('content', ''))
        image_url = data.get('image_url', '')
        link_url = data.get('link_url', '')
        
        if not title or not content:
            return jsonify({'success': False, 'message': 'Title and content required'}), 400
        
        ad = Advertisement(
            title=title,
            content=content,
            image_url=image_url,
            link_url=link_url
        )
        db.session.add(ad)
        db.session.commit()
        
        return jsonify({'success': True, 'message': 'Advertisement created', 'id': ad.id}), 201
    except Exception as e:
        logger.error(f"Error creating advertisement: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to create advertisement'}), 500

@app.route('/admin/advertisements/<int:ad_id>', methods=['DELETE'])
def delete_advertisement(ad_id):
    admin = get_current_admin()
    if not admin:
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
        ad = Advertisement.query.get(ad_id)
        if not ad:
            return jsonify({'success': False, 'message': 'Advertisement not found'}), 404
        
        ad.is_active = False
        db.session.commit()
        
        return jsonify({'success': True, 'message': 'Advertisement deleted'})
    except Exception as e:
        logger.error(f"Error deleting advertisement: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to delete advertisement'}), 500

@app.route('/admin/edit_product/<int:product_id>', methods=['POST'])
def admin_edit_product(product_id):
    admin = get_current_admin()
    if not admin:
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        # For now, just return success since we don't have a Product model
        # In a real implementation, you would update the product in the database
        return jsonify({'success': True, 'message': 'Product updated successfully'})
    except Exception as e:
        logger.error(f"Error editing product: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to edit product'}), 500

@app.route('/admin/delivery_charges', methods=['POST'])
def update_delivery_charges():
    admin = get_current_admin()
    if not admin:
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        charges = DeliveryCharges.query.first()
        if not charges:
            charges = DeliveryCharges()
            db.session.add(charges)
        
        charges.base_charge = float(data.get('base_charge', charges.base_charge))
        charges.per_km_charge = float(data.get('per_km_charge', charges.per_km_charge))
        charges.minimum_charge = float(data.get('minimum_charge', charges.minimum_charge))
        charges.maximum_charge = float(data.get('maximum_charge', charges.maximum_charge))
        charges.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({'success': True, 'message': 'Delivery charges updated'})
    except Exception as e:
        logger.error(f"Error updating delivery charges: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to update charges'}), 500

@app.route('/track_order/<order_id>', methods=['GET'])
def track_order_by_id(order_id):
    try:
        order = Order.query.get(order_id)
        if not order:
            return jsonify({'success': False, 'message': 'Order not found'}), 404
        
        return jsonify({
            'success': True,
            'data': {
                'id': order.id,
                'status': order.status,
                'total': order.total,
                'order_time': order.order_time.isoformat() if order.order_time else None,
                'delivery_personnel_phone': order.delivery_personnel_phone
            }
        })
    except Exception as e:
        logger.error(f"Error tracking order: {str(e)}")
        return jsonify({'success': False, 'message': 'Tracking failed'}), 500

@app.route('/calculate_total', methods=['POST'])
def calculate_total():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        input_text = data.get('input', '').strip()
        if not input_text:
            return jsonify({'success': False, 'message': 'No input provided'}), 400
        
        # Default commodity prices
        prices = {
            'rice': 50.0, 'maize': 45.0, 'beans': 80.0, 'tomatoes': 40.0,
            'onions': 30.0, 'potatoes': 35.0, 'cabbage': 25.0, 'carrots': 60.0,
            'bananas': 20.0, 'oranges': 50.0, 'milk': 60.0, 'bread': 45.0,
            'sugar': 120.0, 'salt': 25.0, 'oil': 200.0
        }
        
        lines = input_text.split('\n')
        items = []
        total_amount = 0
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
                
            parts = line.split(' ', 1)
            if len(parts) != 2:
                items.append({'error': f'Invalid format: {line}'})
                continue
                
            try:
                quantity = int(parts[0])
                product = parts[1].lower().strip()
                
                if product in prices:
                    unit_price = prices[product]
                    item_total = quantity * unit_price
                    total_amount += item_total
                    
                    items.append({
                        'quantity': quantity,
                        'product': product.title(),
                        'unit_price': unit_price,
                        'total': item_total
                    })
                else:
                    items.append({'error': f'Product not found: {product}'})
                    
            except ValueError:
                items.append({'error': f'Invalid quantity: {parts[0]}'})
        
        return jsonify({
            'success': True,
            'items': items,
            'total_amount': total_amount
        })
        
    except Exception as e:
        logger.error(f"Error calculating total: {str(e)}")
        return jsonify({'success': False, 'message': 'Calculation failed'}), 500

@app.route('/confirm_delivery', methods=['POST'])
def confirm_delivery():
    try:
        # Handle both form data and JSON
        if request.content_type and 'multipart/form-data' in request.content_type:
            customer_phone = request.form.get('customer_phone', '').strip()
        else:
            data = request.get_json()
            if not data:
                return jsonify({'success': False, 'message': 'No data provided'}), 400
            customer_phone = data.get('customer_phone', '').strip()
        
        if not customer_phone:
            return jsonify({'success': False, 'message': 'Customer phone is required'}), 400
        
        if not validate_phone(customer_phone):
            return jsonify({'success': False, 'message': 'Invalid phone number format'}), 400
        
        # Find the latest order for this customer
        order = Order.query.filter_by(customer_phone=customer_phone)\
                          .order_by(Order.order_time.desc()).first()
        
        if not order:
            return jsonify({'success': False, 'message': 'No order found for this phone number'}), 404
        
        if order.status == 'delivered':
            return jsonify({'success': False, 'message': 'Order already confirmed as delivered'}), 400
        
        # Update order status
        order.status = 'delivered'
        
        # Free up delivery personnel
        if order.delivery_personnel_phone:
            personnel = DeliveryPersonnel.query.filter_by(phone=order.delivery_personnel_phone).first()
            if personnel:
                personnel.status = 'available'
        
        db.session.commit()
        
        logger.info(f"Delivery confirmed for order {order.id}, customer {customer_phone}")
        return jsonify({
            'success': True, 
            'message': 'Delivery confirmed successfully',
            'order_id': order.id
        })
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error confirming delivery: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to confirm delivery'}), 500

@app.route('/orders', methods=['GET'])
def get_orders():
    try:
        customer_phone = request.args.get('customer_phone')
        status = request.args.get('status')
        
        query = Order.query
        if customer_phone:
            query = query.filter_by(customer_phone=customer_phone)
        if status:
            query = query.filter_by(status=status)
        
        orders = query.order_by(Order.order_time.desc()).all()
        order_list = []
        
        for order in orders:
            order_data = {
                'id': order.id,
                'customer_phone': order.customer_phone,
                'total': order.total,
                'delivery_charge': order.delivery_charge,
                'service_charge': order.service_charge,
                'status': order.status,
                'order_time': order.order_time.isoformat() if order.order_time else None,
                'delivery_personnel_phone': order.delivery_personnel_phone,
                'items': json.loads(order.items_json) if order.items_json else []
            }
            order_list.append(order_data)
        
        return jsonify({'success': True, 'data': order_list})
        
    except Exception as e:
        logger.error(f"Error getting orders: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to get orders'}), 500

@app.route('/products', methods=['GET'])
def get_products():
    try:
        # Return commodity prices as products
        prices = CommodityPrice.query.all()
        products = []
        
        for price in prices:
            products.append({
                'id': price.id,
                'name': price.name,
                'price': price.price,
                'unit': price.unit,
                'updated_at': price.updated_at.isoformat() if price.updated_at else None
            })
        
        # Add default products if none exist
        if not products:
            defaults = [
                {'id': 1, 'name': 'Rice', 'price': 50.0, 'unit': 'KG'},
                {'id': 2, 'name': 'Maize', 'price': 45.0, 'unit': 'KG'},
                {'id': 3, 'name': 'Beans', 'price': 80.0, 'unit': 'KG'},
                {'id': 4, 'name': 'Tomatoes', 'price': 40.0, 'unit': 'KG'},
                {'id': 5, 'name': 'Onions', 'price': 30.0, 'unit': 'KG'}
            ]
            products = defaults
        
        return jsonify({'success': True, 'data': products})
        
    except Exception as e:
        logger.error(f"Error getting products: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to get products'}), 500

@app.route('/<user_type>/wallet/<user_id>', methods=['GET'])
def get_user_wallet(user_type, user_id):
    try:
        if user_type not in ['customer', 'driver', 'agent']:
            return jsonify({'success': False, 'message': 'Invalid user type'}), 400
        
        wallet = get_or_create_wallet(user_type, user_id)
        return jsonify({
            'success': True, 
            'data': {
                'balance': wallet.balance,
                'user_type': user_type,
                'user_id': user_id
            }
        })
        
    except Exception as e:
        logger.error(f"Error getting user wallet: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to get wallet'}), 500

@app.route('/personnel/rate', methods=['POST'])
def rate_personnel():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        personnel_phone = data.get('personnel_phone', '').strip()
        customer_phone = data.get('customer_phone', '').strip()
        rating = data.get('rating')
        review = data.get('review', '')
        
        if not personnel_phone or not customer_phone or rating is None:
            return jsonify({'success': False, 'message': 'Missing required fields'}), 400
        
        if not (1 <= rating <= 5):
            return jsonify({'success': False, 'message': 'Rating must be between 1 and 5'}), 400
        
        # Verify personnel exists
        personnel = DeliveryPersonnel.query.filter_by(phone=personnel_phone).first()
        if not personnel:
            return jsonify({'success': False, 'message': 'Personnel not found'}), 404
        
        logger.info(f"Personnel {personnel_phone} rated {rating}/5 by customer {customer_phone}")
        return jsonify({'success': True, 'message': 'Rating submitted successfully'})
        
    except Exception as e:
        logger.error(f"Error rating personnel: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to submit rating'}), 500

@app.route('/<user_type>/wallet/<user_id>/transactions', methods=['GET'])
def get_user_wallet_transactions(user_type, user_id):
    try:
        if user_type not in ['customer', 'driver', 'agent']:
            return jsonify({'success': False, 'message': 'Invalid user type'}), 400
        
        wallet = get_or_create_wallet(user_type, user_id)
        transactions = WalletTransaction.query.filter_by(wallet_id=wallet.id)\
                                           .order_by(WalletTransaction.timestamp.desc()).all()
        
        transaction_list = []
        for txn in transactions:
            transaction_list.append({
                'id': txn.id,
                'type': txn.type,
                'amount': txn.amount,
                'timestamp': txn.timestamp.isoformat() if txn.timestamp else None,
                'status': txn.status
            })
        
        return jsonify({'success': True, 'data': transaction_list})
        
    except Exception as e:
        logger.error(f"Error getting wallet transactions: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to get transactions'}), 500

@app.route('/<user_type>/wallet/<user_id>/withdraw', methods=['POST'])
def withdraw_user_wallet(user_type, user_id):
    try:
        if user_type not in ['customer', 'driver', 'agent']:
            return jsonify({'success': False, 'message': 'Invalid user type'}), 400
        
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        amount = data.get('amount')
        if not amount or amount <= 0:
            return jsonify({'success': False, 'message': 'Invalid amount'}), 400
        
        wallet = get_or_create_wallet(user_type, user_id)
        if wallet.balance < float(amount):
            return jsonify({'success': False, 'message': 'Insufficient balance'}), 400
        
        wallet.balance -= float(amount)
        
        # Log transaction
        transaction = WalletTransaction(
            wallet_id=wallet.id,
            type='withdraw',
            amount=float(amount)
        )
        db.session.add(transaction)
        db.session.commit()
        
        return jsonify({'success': True, 'data': {'balance': wallet.balance}})
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error withdrawing from wallet: {str(e)}")
        return jsonify({'success': False, 'message': 'Withdrawal failed'}), 500

@app.route('/<user_type>/wallet/<user_id>/deposit', methods=['POST'])
def deposit_user_wallet(user_type, user_id):
    try:
        if user_type not in ['customer', 'driver', 'agent']:
            return jsonify({'success': False, 'message': 'Invalid user type'}), 400
        
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        amount = data.get('amount')
        if not amount or amount <= 0:
            return jsonify({'success': False, 'message': 'Invalid amount'}), 400
        
        wallet = get_or_create_wallet(user_type, user_id)
        wallet.balance += float(amount)
        
        # Log transaction
        transaction = WalletTransaction(
            wallet_id=wallet.id,
            type='deposit',
            amount=float(amount)
        )
        db.session.add(transaction)
        db.session.commit()
        
        return jsonify({'success': True, 'data': {'balance': wallet.balance}})
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error depositing to wallet: {str(e)}")
        return jsonify({'success': False, 'message': 'Deposit failed'}), 500

@app.route('/mpesa/deposit', methods=['POST'])
def mpesa_deposit():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        user_id = data.get('user_id')
        amount = data.get('amount')
        
        if not user_id or not amount:
            return jsonify({'success': False, 'message': 'User ID and amount required'}), 400
        
        # Mock M-Pesa integration - in production, integrate with actual M-Pesa API
        logger.info(f"M-Pesa deposit: {amount} for user {user_id}")
        return jsonify({'success': True, 'message': 'M-Pesa deposit initiated'})
        
    except Exception as e:
        logger.error(f"Error with M-Pesa deposit: {str(e)}")
        return jsonify({'success': False, 'message': 'M-Pesa deposit failed'}), 500

@app.route('/mpesa/withdraw', methods=['POST'])
def mpesa_withdraw():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        user_id = data.get('user_id')
        amount = data.get('amount')
        
        if not user_id or not amount:
            return jsonify({'success': False, 'message': 'User ID and amount required'}), 400
        
        # Mock M-Pesa integration - in production, integrate with actual M-Pesa API
        logger.info(f"M-Pesa withdraw: {amount} for user {user_id}")
        return jsonify({'success': True, 'message': 'M-Pesa withdrawal initiated'})
        
    except Exception as e:
        logger.error(f"Error with M-Pesa withdraw: {str(e)}")
        return jsonify({'success': False, 'message': 'M-Pesa withdrawal failed'}), 500

@app.route('/admin/change_password', methods=['POST'])
def admin_change_password():
    admin = get_current_admin()
    if not admin:
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        new_password = data.get('new_password')
        if not new_password or len(new_password) < 6:
            return jsonify({'success': False, 'message': 'Password must be at least 6 characters'}), 400
        
        admin.password = hash_password(new_password)
        db.session.commit()
        
        logger.info(f"Admin password changed: {admin.username}")
        return jsonify({'success': True, 'message': 'Password changed successfully'})
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error changing admin password: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to change password'}), 500

@app.route('/admin/products', methods=['GET'])
def get_admin_products():
    admin = get_current_admin()
    if not admin:
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
        prices = CommodityPrice.query.all()
        products = []
        
        for price in prices:
            products.append({
                'id': price.id,
                'name': price.name,
                'price': price.price,
                'unit': price.unit,
                'updated_at': price.updated_at.isoformat() if price.updated_at else None
            })
        
        return jsonify({'success': True, 'data': products})
        
    except Exception as e:
        logger.error(f"Error getting admin products: {str(e)}")
        return jsonify({'success': False, 'message': 'Failed to get products'}), 500

@app.route('/wallet/<user_type>/<user_id>/deposit', methods=['POST'])
def deposit_wallet(user_type, user_id):
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        amount_str = data.get('amount')
        if amount_str is None:
            return jsonify({'success': False, 'message': 'Amount is required'}), 400
        
        try:
            amount = float(amount_str)
        except (ValueError, TypeError):
            return jsonify({'success': False, 'message': 'Invalid amount format'}), 400
        
        if amount <= 0:
            return jsonify({'success': False, 'message': 'Amount must be positive'}), 400
        
        wallet = get_or_create_wallet(user_type, user_id)
        wallet.balance += amount
        
        # Log transaction
        transaction = WalletTransaction(
            wallet_id=wallet.id,
            type='deposit',
            amount=amount
        )
        db.session.add(transaction)
        db.session.commit()
        
        return jsonify({'success': True, 'balance': wallet.balance})
        
    except Exception as e:
        logger.error(f"Error depositing to wallet: {str(e)}")
        return jsonify({'success': False, 'message': 'Deposit failed'}), 500

def ensure_admin_exists():
    """Create default admin if none exists"""
    try:
        admin_email = os.environ.get('ADMIN_EMAIL', 'admin@cheteni.com')
        admin_user = os.environ.get('ADMIN_USER', 'admin')
        admin_pass = os.environ.get('ADMIN_PASS')
        
        if not admin_pass:
            import secrets
            admin_pass = secrets.token_urlsafe(16)
            logger.warning(f"Generated secure admin password: {admin_pass}")
            print(f"ADMIN PASSWORD: {admin_pass}")
        
        if not all([admin_email, admin_user, admin_pass]):
            logger.warning("Using default admin credentials")
            admin_email = 'admin@cheteni.com'
            admin_user = 'admin'
        
        admin = Admin.query.filter_by(email=admin_email).first()
        
        if not admin:
            admin = Admin(
                email=admin_email,
                username=admin_user,
                password=hash_password(admin_pass)
            )
            db.session.add(admin)
            db.session.commit()
            
            logger.info(f"Admin user created: {admin_user}")
            
    except Exception as e:
        logger.error(f"Error creating admin: {str(e)}")

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({'success': False, 'message': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'success': False, 'message': 'Internal server error'}), 500

# Initialize database and admin
with app.app_context():
    db.create_all()
    ensure_admin_exists()
    
    # Initialize default delivery charges if none exist
    if not DeliveryCharges.query.first():
        default_charges = DeliveryCharges()
        db.session.add(default_charges)
        db.session.commit()
    
    # Initialize default commodity prices if none exist
    if not CommodityPrice.query.first():
        defaults = {
            'Rice': 50.0, 'Maize': 45.0, 'Beans': 80.0, 'Tomatoes': 40.0,
            'Onions': 30.0, 'Potatoes': 35.0, 'Cabbage': 25.0, 'Carrots': 60.0,
            'Bananas': 20.0, 'Oranges': 50.0
        }
        for name, price in defaults.items():
            commodity = CommodityPrice(name=name, price=price)
            db.session.add(commodity)
        db.session.commit()

if __name__ == '__main__':
    # Production vs Development configuration
    if os.environ.get('FLASK_ENV') == 'production':
        # Production mode
        port = int(os.environ.get('PORT', 5000))
        app.run(host='0.0.0.0', port=port, debug=False)
    else:
        # Development mode
        debug_mode = os.environ.get('FLASK_DEBUG', 'True').lower() == 'true'
        host = os.environ.get('FLASK_HOST', '127.0.0.1')
        port = int(os.environ.get('FLASK_PORT', 5000))
        app.run(host=host, port=port, debug=debug_mode)