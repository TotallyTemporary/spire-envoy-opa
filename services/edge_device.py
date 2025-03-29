import io
import sys
import asyncio
import aiohttp
import time
import threading
from picamera2.encoders import MJPEGEncoder, Quality
from picamera2.outputs import FileOutput
from picamera2 import Picamera2

from flask import Flask, request

app = Flask(__name__)

CAMERA_RES = (1280, 720)
CAMERA_FPS = 24
SENDER_MAX_CONCURRENT = 6  # Requests currently being served
SENDER_MAX_QUEUED = 6      # Frames generated and not sent
EDGE_NODE_IP = "127.0.0.1"
EDGE_NODE_PORT = 4002

# Adaptive frame rate! This reduces inconsistent frame timings.
FT_START_FRAMETIME = 1 / 20
FT_SUCCESS_DECREASE = 0.98
FT_FAILURE_INCREASE = 1.05


# For load testing
@app.route("/", methods=["GET"])
def test():
    return {}, 204

# Largely copied from https://github.com/raspberrypi/picamera2/blob/main/examples/mjpeg_server.py
class StreamingOutput(io.BufferedIOBase):
    def __init__(self):
        self.frame = None
        self.condition = threading.Condition()

    def write(self, buf):
        with self.condition:
            self.frame = buf
            self.condition.notify_all()

class SenderWorker:
    def __init__(self, loop, thread):
        self.loop = loop
        self.thread = thread

        self.running = True
        self.requests_semaphore = asyncio.Semaphore(SENDER_MAX_CONCURRENT)
        self.queue = asyncio.Queue()

    async def run(self):
        async with aiohttp.ClientSession() as session:
            while self.running:
                frame = await self.queue.get()
                try:
                    if not frame:
                        return
                    async with self.requests_semaphore:
                        async with session.post(f"http://{EDGE_NODE_IP}:{EDGE_NODE_PORT}/receive", data={
                            "frame.mjpeg": frame
                        }) as response:
                            text = await response.text()
                finally:
                    self.queue.task_done()

    def enqueue_frame(self, frame):
        if self.queue.qsize() > SENDER_MAX_QUEUED:
            return False

        def job():
            self.queue.put_nowait(frame)
        self.loop.call_soon_threadsafe(job)
        return True

class Sender:
    def __init__(self, frame_input: StreamingOutput):
        self.frame_input = frame_input
        self.running = True
        self.last_time = time.time()
        self.delta = 0

        # start worker
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        worker_thread = threading.Thread(target=lambda: loop.run_forever(), args=(), daemon=True)
        worker_thread.start()

        self.worker = SenderWorker(loop, worker_thread)
        loop.create_task(self.worker.run())

    def run(self):
        frametime = FT_START_FRAMETIME
        count = 0
        total_start = time.time()

        while self.running:
            now = time.time()
            self.delta += (now - self.last_time)
            self.last_time = now

            if self.delta > frametime:
                with self.frame_input.condition:
                    frame = self.frame_input.frame
                    if not frame:
                        continue

                    is_sending = self.worker.enqueue_frame(frame)
                    if is_sending:
                        # we're sending a frame! let's give ourselves a pat on our backs.
                        frametime *= FT_SUCCESS_DECREASE
                        count += 1
                        self.delta -= frametime
                    else:
                        # we're too congested to send a frame, let's slow down a bit.
                        frametime *= FT_FAILURE_INCREASE

        total_time = time.time() - total_start
        fps = count / total_time
        print(f"{fps=}, frametime={1/fps}")

        self.worker.running = False
        self.worker.enqueue_frame(None)
        self.worker.thread.join(1000)

def run_sender(sender):
    sender.run()

def main():
    # Configure the sending server
    output = StreamingOutput()
    sender = Sender(output)

    # Configure the camera
    picam2 = Picamera2()
    camera_config = picam2.create_video_configuration()
    picam2.configure(camera_config)
    picam2.resolution = CAMERA_RES
    picam2.framerate = CAMERA_FPS

    # picam2.set_controls({"AnalogueGain": 16.0, "ExposureTime": 80_000})
    encoder = MJPEGEncoder()

    picam2.start_recording(encoder, FileOutput(output), quality=Quality.HIGH)

    # Start sending frames
    sender_thread = threading.Thread(target=lambda sender: sender.run(), args=(sender,), daemon=True)
    sender_thread.start()

    time.sleep(3*60)

    picam2.stop_recording()

    sender.running = False
    sender_thread.join(1000)

    sys.exit(0)

if __name__ == "__main__":
    main()
    # app.run(host="127.0.0.1", port=3002, threaded=True) 
