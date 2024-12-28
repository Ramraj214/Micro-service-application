import os, requests

def login(request):
    auth = request.authorization
    if not auth:
        return None, ("missing credentials", 401)

    basicAuth = (auth.username, auth.password)

    response = requests.post(
        f"http://{os.environ.get('AUTH_SVC_ADDRESS')}/login", auth=basicAuth
    )

    if response.status_code == 200:
        return response.text, None
    else:
        return None, (response.text, response.status_code)


def signup(request):
    if not request.json or not request.json.get("email") or not request.json.get("password"):
        return None, ("Missing email or password", 400)

    email = request.json["email"]
    password = request.json["password"]

    # Prepare data for the signup request
    signup_data = {
        "email": email,
        "password": password
    }

    response = requests.post(
        f"http://{os.environ.get('AUTH_SVC_ADDRESS')}/signup", json=signup_data
    )

    if response.status_code == 200:
        return response.text, None
    else:
        return None, (response.text, response.status_code)

