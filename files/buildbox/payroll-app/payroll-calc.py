from flask import (
    Flask,
    render_template,
    redirect,
    url_for,
    request,
    make_response,
)
from pymongo import MongoClient
from bson.objectid import ObjectId
import socket
import os
import time
import json

app = Flask(__name__)

LINK = os.environ.get("LINK", "www.cloudyuga.guru")
TEXT1 = os.environ.get("TEXT1", "CloudYuga")
TEXT2 = os.environ.get("TEXT2", "Garage Payroll")
LOGO = os.environ.get(
    "LOGO",
    "https://raw.githubusercontent.com/cloudyuga/payrollapp/master/static/cloudyuga.png",
)
COMPANY = os.environ.get("COMPANY", "CloudYuga Technology Pvt. Ltd.")
DELAY = int(os.environ.get("DELAY", "120"))

MONGODB_HOST = os.environ.get("MONGODB_HOST", "localhost")
client = MongoClient(MONGODB_HOST, 27017)
db = client.payrolldata


class Payroll(object):
    """Simple Model class for Payroll"""

    def __init__(self, name, email, _id=None):
        self.name = name
        self.email = email
        self._id = _id

    def dict(self):
        _id = str(self._id)
        return {
            "_id": _id,
            "name": self.name,
            "email": self.email,
            "links": {
                "self": "{}api/payrolls/{}".format(request.url_root, _id)
            },
        }

    def delete(self):
        db.payrolldata.find_one_and_delete({"_id": self._id})

    @staticmethod
    def find_all():
        return [Payroll(**doc) for doc in db.payrolldata.find()]

    @staticmethod
    def find_one(id):
        doc = db.payrolldata.find_one({"_id": ObjectId(id)})
        return doc and Payroll(doc["name"], doc["email"], doc["_id"])

    @staticmethod
    def new(name, email):
        doc = {"name": name, "email": email}
        result = db.payrolldata.insert_one(doc)
        return Payroll(name, email, result.inserted_id)


@app.route("/")
def payroll():
    _items = db.payrolldata.find()
    items = [item for item in _items]
    count = len(items)
    hostname = socket.gethostname()
    return render_template(
        "profile.html",
        counter=count,
        hostname=hostname,
        items=items,
        TEXT1=TEXT1,
        TEXT2=TEXT2,
        LOGO=LOGO,
        COMPANY=COMPANY,
    )


@app.route("/new", methods=["POST"])
def new():
    item_doc = {"name": request.form["name"], "email": request.form["email"]}
    db.payrolldata.insert_one(item_doc)
    return redirect(url_for("payroll"))


@app.route("/api/payrolls", methods=["GET", "POST"])
def api_payrolls():
    if request.method == "GET":
        docs = [payroll.dict() for payroll in Payroll.find_all()]
        return json.dumps(docs, indent=True)
    else:
        try:
            doc = json.loads(request.data)
        except ValueError:
            return '{"error": "expecting JSON payload"}', 400

        if "name" not in doc:
            return '{"error": "name field is missing"}', 400
        if "email" not in doc:
            return '{"error": "email field is missing"}', 400

        payroll = Payroll.new(name=doc["name"], email=doc["email"])
        return json.dumps(payroll.dict(), indent=True)


@app.route("/api/payrolls/<id>", methods=["GET", "DELETE"])
def api_payroll(id):
    payroll = Payroll.find_one(id)
    if not payroll:
        return json.dumps({"error": "not found"}), 404

    if request.method == "GET":
        return json.dumps(payroll.dict(), indent=True)
    elif request.method == "DELETE":
        payroll.delete()
        return json.dumps({"deleted": "true"})


if __name__ == "__main__":
    print(f"Starting up - holding of {DELAY} seconds")
    time.sleep(DELAY)
    print("Starting web server")
    app.run(host="0.0.0.0", debug=True)
