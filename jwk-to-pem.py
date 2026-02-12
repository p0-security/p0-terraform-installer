import jwt
import sys
from cryptography.hazmat.primitives import serialization

"""
This script is used to convert a JWK private key (from Okta UI) to a PEM private key (for Okta Terraform provider).
"""


if __name__ == "__main__":
    """
    Pass the JWK file as an argument to the script.
    Usage:
      python jwk-to-pem.py private_key.jwk
    """
    private_key = jwt.algorithms.RSAAlgorithm.from_jwk(open(sys.argv[1], "r").read())
    private_key_bytes = private_key.private_bytes(
      encoding=serialization.Encoding.PEM,
      format=serialization.PrivateFormat.PKCS8, 
      encryption_algorithm=serialization.NoEncryption())
    print(private_key_bytes)