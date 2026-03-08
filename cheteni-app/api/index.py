"""
Vercel Serverless Function Entry Point
This file properly exposes the Flask app for Vercel's serverless environment
"""
import sys
import os

# Add parent directory to path to import cheteni module
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Import the Flask app
from cheteni import app

# Initialize the app context for database operations
with app.app_context():
    from models import db
    # Create tables if they don't exist
    db.create_all()

# Vercel expects a variable named 'app' or a handler function
# The Flask app object itself works as the WSGI application
handler = app
