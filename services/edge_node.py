# Edge node

import threading
from flask import Flask, request
import numpy as np
import cv2
import logging

log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)

ALPHA = 0.03                   # background adaptation rate: lower is slower
DIFF_THRESHOLD = 40            # change in brightness: is pixel changed?
ERODE_KERNEL_SIZE = 3          # cluster of more/less pixels
PIXELS_CHANGED_THRESHOLD = 60  # how many pixels in total have changed for us to notify home?

app = Flask(__name__)

lock = threading.Lock()
background = None

@app.route("/receive", methods=["POST"])
def receive_data():
    global lock, background

    file = request.files["frame.mjpeg"]
    
    image_bytes = file.read()
    image_np = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(image_np, cv2.IMREAD_COLOR)

    # https://medium.com/@abbessafa1998/motion-detection-techniques-with-code-on-opencv-18ed2c1acfaf
    img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) # greyscale

    with lock:
        if background is None:
            background = img
        background = np.uint8(ALPHA * img + (1 - ALPHA) * background)
    
    diff = cv2.absdiff(background, img)
    _, motion_mask = cv2.threshold(diff, DIFF_THRESHOLD, 255, cv2.THRESH_BINARY)
    motion_mask = cv2.erode(motion_mask, np.ones((ERODE_KERNEL_SIZE, ERODE_KERNEL_SIZE), np.uint8), cv2.BORDER_REFLECT)  
    pixels_count = np.sum(motion_mask) / 255

    if pixels_count >= PIXELS_CHANGED_THRESHOLD:
        with lock:
            print("Motion! ", pixels_count)
            cv2.imwrite("diff.png", diff)
            cv2.imwrite("mask.png", motion_mask)
            cv2.imwrite("background.png", background)

    return {"data": "success"}, 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3002, threaded=True) # Envoy will make this 3002
