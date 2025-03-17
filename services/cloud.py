# Cloud server

from flask import Flask, request

app = Flask(__name__)

@app.route("/receive", methods=["GET"])
def receive_data():
    return {"data": "success"}, 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=4002) # Envoy will make this 3002
