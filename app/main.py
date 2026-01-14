from flask import Flask
import time
import math

app = Flask(__name__)

@app.route('/')
def hello():
    return "Cloud Resource Management App Active"

@app.route('/load')
def load():
    # Simulate CPU load
    # Calculate primes or something heavy
    start_time = time.time()
    # Run for about 1 second to cause noticeable load per request
    while time.time() - start_time < 1.0:
        for x in range(10000):
            math.sqrt(x)
            x * x
    return "Load generated"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
