import random, nimcrypto/pbkdf2


const keySize: int = 64

const iterations: int = 300000


proc hashPassword*(password: string): (string, string) =

  var salt: seq[byte]
  setLen(salt, keySize)
  for i in 0 ..< keySize:
    salt[i] = rand(256).byte
 
  var hash = pbkdf2(sha256, password, $salt, iterations, keySize) 

  return ($hash, $salt)


proc verifyPassword*(password: string, hashedPassword: string, salt: string): bool =

  var hash = pbkdf2(sha256, password, $salt, iterations, keySize) 
  
  return $hash == hashedPassword



 

#test code

#[

let password = "test"

let (hash, salt) = hashPassword(password)


echo "hash = " & $hash

echo "salt = " & $salt



let answer = verifyPassword(password,hash,salt)

echo answer 


]#







