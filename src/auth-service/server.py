import jwt, datetime, os
import psycopg2
from flask import Flask, request


server = Flask(__name__)

def get_db_connection():
    conn = psycopg2.connect(host=os.getenv('DATABASE_HOST'),
                            database=os.getenv('DATABASE_NAME'),
                            user=os.getenv('DATABASE_USER'),
                            password=os.getenv('DATABASE_PASSWORD'),
                            port=os.getenv(DATABASE_PORT))
    return conn

@server.route('/signup', methods=['POST'])
def signup():
    auth_table_name = os.getenv('AUTH_TABLE')
    data = request.json
    if not data or not data.get('email') or not data.get('password'):
        return jsonify({'message': 'Email and password are required!'}), 400
    email = data['email']
    password = data['password']
    
    hashed_password = generate_password_hash(password, method='sha256')
    conn = get_db_connection()
    cur = conn.cursor()
    # Check if user already exists
    cur.execute(f"SELECT email FROM {auth_table_name} WHERE email = %s", (email,))
    if cur.fetchone():
        return jsonify({'message': 'User already exists!'}), 409
    # Insert new user into the database
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
    res = cur.execute(query, (auth.username,))
    
    if res is None:
        user_row = cur.fetchone()
        email = user_row[0]
        password = user_row[1]

        if auth.username != email or auth.password != password:
            return 'Could not verify', 401, {'WWW-Authenticate': 'Basic realm="Login required!"'}
        else:
            return CreateJWT(auth.username, os.environ['JWT_SECRET'], True)
    else:
        return 'Could not verify', 401, {'WWW-Authenticate': 'Basic realm="Login required!"'}

def CreateJWT(username, secret, authz):
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

@server.route('/validate', methods=['POST'])
def validate():
    encoded_jwt = request.headers['Authorization']
    
    if not encoded_jwt:
        return 'Unauthorized', 401, {'WWW-Authenticate': 'Basic realm="Login required!"'}

    encoded_jwt = encoded_jwt.split(' ')[1]
    try:
        decoded_jwt = jwt.decode(encoded_jwt, os.environ['JWT_SECRET'], algorithms=["HS256"])
    except:
        return 'Unauthorized', 401, {'WWW-Authenticate': 'Basic realm="Login required!"'}
    
    return decoded_jwt, 200

if __name__ == '__main__':
    server.run(host='0.0.0.0', port=5000)
