from Crypto.Cipher import AES
from Crypto.Util.Padding import pad

key = b'hamzahfatihulhaqpassword'

cipher = AES.new(key, AES.MODE_CBC)

plaintext = b'my name is hamzah fatihulhaq and my nim is 1103192193'

ciphertext = cipher.encrypt(pad(plaintext,AES.block_size))

# print(cipher.iv)

# encryption
with open('cipher_file', 'wb') as c_file:
    c_file.write(cipher.iv)
    c_file.write(ciphertext)
