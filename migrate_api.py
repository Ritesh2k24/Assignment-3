from flask import Flask, request
import subprocess

app = Flask(__name__)

@app.route("/migrate", methods=["POST"])
def migrate():
    subprocess.run(["/bin/bash", "migrate_to_aws.sh"])
    return "Migration started", 200

if __name__ == "__main__":
    app.run(port=5001)
