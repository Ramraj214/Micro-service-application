import jwt
import datetime
import os
from flask import Flask, request, jsonify
import psycopg2
from werkzeug.security import generate_password_hash, check_password_hash

server = Flask(__name__)

def get_db_connection():
    conn = psycopg2.connect(
        host=os.getenv('DATABASE_HOST'),
        database=os.getenv('DATABASE_NAME'),
        user=os.getenv('DATABASE_USER'),
        password=os.getenv('DATABASE_PASSWORD'),
        port=5432
    )
    return conn

@server.route('/signup', methods=['POST'])
def signup():
    auth_table_name = os.getenv('AUTH_TABLE')
    data = request.json
    if not data or not data.get('email') or not data.get('password'):
        return jsonify({'message': 'Email and password are required!'}), 400
    email = data['email']
    password = data['password']
    
    # Hash the password before storing it
    hashed_password = generate_password_hash(password, method='sha256')
    
    conn = get_db_connection()
    cur = conn.cursor()
    # Check if the user already exists
    cur.execute(f"SELECT email FROM {auth_table_name} WHERE email = %s", (email,))
    if cur.fetchone():
        return jsonify({'message': 'User already exists!'}), 409
    
    # Insert the new user into the database
    try:
        cur.execute(f"INSERT INTO {auth_table_name} (email, password) VALUES (%s, %s)", (email, hashed_password))
        conn.commit()
    except Exception as e:
        return jsonify({'message': f'Error occurred: {str(e)}'}), 500
    finally:
        cur.close()
        conn.close()

    return jsonify({'message': 'User created successfully!'}), 201

@server.route('/login', methods=['POST'])
def login():
    auth_table_name = os.getenv('AUTH_TABLE')
    auth = request.authorization
    if not auth or not auth.username or not auth.password:
        return 'Could not verify', 401, {'WWW-Authenticate': 'Basic realm="Login required!"'}

    conn = get_db_connection()
    cur = conn.cursor()
    query = f"SELECT email, password FROM {auth_table_name} WHERE email = %s"
    cur.execute(query, (auth.username,))
    user_row = cur.fetchone()

    if user_row is None:
        return 'Could not verify', 401, {'WWW-Authenticate': 'Basic realm="Login required!"'}
    
    email = user_row[0]
    hashed_password = user_row[1]

    if auth.username != email or not check_password_hash(hashed_password, auth.password):
        return 'Could not verify', 401, {'WWW-Authenticate': 'Basic realm="Login required!"'}
    else:
        # Return JWT on successful login
        return jsonify({'token': CreateJWT(auth.username, os.environ['JWT_SECRET'], True)}), 200

def CreateJWT(username, secret, authz):
    try:
        return jwt.encode(
            {
                "username": username,
                "exp": datetime.datetime.now(tz=datetime.timezone.utc) + datetime.timedelta(days=1),
                "iat": datetime.datetime.now(tz=datetime.timezone.utc),
                "admin": authz,
            },
            secret,
            algorithm="HS256",
        )
    except Exception as e:
        return jsonify({'message': f'Error creating JWT: {str(e)}'}), 500

@server.route('/validate', methods=['POST'])
def validate():
    encoded_jwt = request.headers.get('Authorization')
    
    if not encoded_jwt or not encoded_jwt.startswith('Bearer '):
        return 'Unauthorized', 401, {'WWW-Authenticate': 'Basic realm="Login required!"'}

    encoded_jwt = encoded_jwt.split(' ')[1]
    try:
        decoded_jwt = jwt.decode(encoded_jwt, os.environ['JWT_SECRET'], algorithms=["HS256"])
    except jwt.ExpiredSignatureError:
        return 'Token expired', 401, {'WWW-Authenticate': 'Basic realm="Login required!"'}
    except jwt.InvalidTokenError:
        return 'Invalid token', 401, {'WWW-Authenticate': 'Basic realm="Login required!"'}
    
    return jsonify(decoded_jwt), 200

if __name__ == '__main__':
    server.run(host='0.0.0.0', port=5000)
