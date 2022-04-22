from eth_hash.auto import keccak
import binascii


string = 'teste'

cipher = keccak.new(string.encode()).digest()
# cipher1 = keccak(b'teste')
print("Keccak256:", binascii.hexlify(cipher))


