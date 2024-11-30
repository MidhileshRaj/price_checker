from flask import Flask, request, jsonify

from DBConnection import Db

app = Flask(__name__)
app.secret_key = "1234567"

static_path = "D:\\Riss\\Projects\\snmi_app\static\\"

app = Flask(__name__)

# Function to connect to the database


@app.route('/get_data', methods=['POST'])
def get_data():
    userName = request.form["userName"]
    dataBase = request.form["dataBase"]
    host = request.form["host"]
    password = request.form["password"]
    productCode = request.form["productCode"]
    if not userName or not dataBase or not host :
        return jsonify({'error': 'userName,host or dataBase missing in headers'}), 400

    try:
        # Assuming you are using some kind of database connection utility Db
        db = Db(user=userName, database=dataBase,host=host,password=password)

        # Query the product table with itemCode
        query = f"SELECT * FROM product WHERE product_code = '{productCode}'"
        result = db.selectOne(query)

        # Check if the result exists
        if not result:
            return jsonify({'error': 'Product not found'}), 404

        # Return the result as a JSON response
        return jsonify({'product': result}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    app.run(debug = True, host="0.0.0.0",port=5000)