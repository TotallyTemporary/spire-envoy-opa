# Edge node

import time, requests

# from flask import Flask, request

# app = Flask(__name__)

# @app.route("/receive", methods=["POST"])
# def receive_data():
#     data = request.get_json().get("processed_data")
#     # print(data)
#     return {}, 200

if __name__ == "__main__":
    # app.run(host="0.0.0.0", port=8003)
    while True:
        time.sleep(2)
        result = requests.get("http://localhost:4002/receive")
        print(vars(result))
