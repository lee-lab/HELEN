from flask import Flask, request
import ssl

app = Flask(__name__)
context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
context.load_cert_chain('./key/server.crt', './key/server.key')


@app.route('/', methods=['POST'])
def upload():
    print(request.headers)
    upfile = request.files['data']
    upfile.save("test.log")

    return request.data

@app.route('/index')
def hello():
    name = "hello world"
    return name


if __name__ == "__main__":
    #if you set host="0.0.0.0", this server open local network
    app.run(debug=True, host="0.0.0.0", port=8080, ssl_context=context)
    #app.run(debug=True, host="0.0.0.0", port=8080)
