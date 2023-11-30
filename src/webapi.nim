import happyx, std/[json, asyncdispatch, logging, strutils, times, tables, sugar, marshal], norm/[model, sqlite], webapi/db_backend, webapi/models/[user,order,product]
import password_manager, jwt 

#happyx models
model User:
  full_name: string
  age: int
  email: string
  role: string
  password: string

model Product:
  product_name: string
  product_price: float

model Order:
  user_id: int64
  product_ids: string

model UserAuth:
  email: string
  password: string


proc adminDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode) =
  statementList.insert(0, parseStmt"""
var token = headers.toJsonNode(){"authorization"}.getStr().replace("Bearer ","")

if not headers.hasKey("Authorization"):
  var statusCode = 401
  return {"response": "failure", "reason": "You should to use Bearer authorization!"}

if not verifyjwt(token):
  return "Invalid token."

if verifyjwt(token) and decodeJWT(token) != "Admin":
  var statusCode = 401
  return "Not admin role"

  """
  )

proc noneDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode) =
  statementList.insert(0, parseStmt"""
var token = headers.toJsonNode(){"authorization"}.getStr().replace("Bearer ","")

if not headers.hasKey("Authorization"):
  var statusCode = 401
  return {"response": "failure", "reason": "You should to use Bearer authorization!"}

if not verifyjwt(token):
  return "Invalid token."

if verifyjwt(token) and (decodeJWT(token) != "Admin" or decodeJWT(token) != "None"):
  var statusCode = 401
  return "Not signed in"

  """
  )

static:
  regDecorator("Admin", adminDecoratorImpl)
  regDecorator("None", noneDecoratorImpl)






proc main() =

  
  #DB CONNECTION
  let dbConn = open("webapi.db", "", "", "")

  let logger = newConsoleLogger(fmtStr="[$time] - $levelname: ")

  #TOKEN CONTROLLER CODE
  proc createSymmetricSecurityKey(secret: string): string =
      var secretKey = ""
      for c in secret:
        secretKey.add chr(ord(c)) 
      result = secretKey

  let secret = createSymmetricSecurityKey("MyVerySuperSecureSecretSharedKey")
  let issuer = "http://www.ecu.edu";
  let audience = "http://www.ecu.edu";

  proc signJWT(user: user.User): string =

    var token = toJWT(%*{
      "header": {
        "alg": "HS256",
        "typ": "JWT"
      },
      "claims": {
        "issuer": issuer,
        "audience": audience,
        "email": user.email,
        "rol": user.role,
        "exp": (getTime() + 30.days).toUnix(),
        "notbefore": getTime().toUnix()  
      }
    })

    token.sign(secret)

    return $token

  proc verifyJWT(token: string): bool =
    try:
      let jwtToken = token.toJWT()
      return jwtToken.verify(secret, HS256)
    except InvalidToken:
      return false
      


  proc decodeJWT(token: string): string =
    let jwt = token.toJWT()
    return $jwt.claims["rol"].node.str

  



  #CORS
  regCORS:
      origins: ["*"]
      methods: ["*"]
      headers: ["*"]
      credentials: true


  logger.log(lvlInfo, "started web server at http://127.0.0.1:5000")


  #Serve at http://127.0.0.1:5000
  serve "127.0.0.1", 5000:

  
    middleware:
      logger.log(lvlInfo, headers)
  


    # auth user
    post "/authenticate[o:UserAuth:json]":
      
      if dbConn.exists(user.User, "email = ?", o.email.toLowerAscii()):
        var user = newUser()
        dbConn.select(user,"email = ?", o.email.toLowerAscii())

        if not verifyPassword(o.password,user.hash,user.salt):
          statusCode = 401
          return "Invalid email or password."

        var token = signjwt(user)

        return token

      else:
        statusCode = 401
        return "Invalid email or password."

   

    #EXAMPLE ROUTES 

    
    # API home page ******** EVERYONE ******** 
    get "/":
      return FileResponse("index.html")

    

    
    # GET All User table ******** ADMIN ONLY ******** 
    @Admin
    get "/users":
      var users = @[newUser()]
      dbConn.selectAll(users)
      return $$users
    
    
    # GET All Product table *********** ANY SIGNED IN USER ************
    @None
    get "/products":   
      var products = @[newProduct()]
      dbConn.selectAll(products)
      return $$products
      

    # GET All Orders table ******** ADMIN ONLY ******** 
    @Admin
    get "/orders":
      var orders = @[newOrder()]
      dbConn.selectAll(orders)
      return $$orders
      
          
   
    # GET User by ID ******** ADMIN ONLY ******** 
    @Admin
    get "/users/{userId:int}":
      if dbConn.exists(user.User, "id = ?", userId):
        var user = newUser()
        dbConn.select(user,"id = ?", userId)
        return $$user[]
      else:
        return "User not found"
      
      
    
    # GET Product by ID *********** ANY SIGNED IN USER ************]
    @None
    get "/products/{productId:int}":
      if dbConn.exists(product.Product, "id = ?", productId):
        var product = newProduct()
        dbConn.select(product,"id = ?", productId)
        return $$product[]
      else:
        return "Product not found"
      

    
    # DELETE User and if they orders delete them too ******** ADMIN ONLY ******** 
    @Admin
    delete "/users/{userId:int}":
      if dbConn.exists(user.User, "id = ?", userId):
        var user = newUser()
        dbConn.select(user,"id = ?", userId)
        dbConn.delete(user)
        if dbConn.exists(order.Order, "id = ?", userId):
          var order = newOrder()
          dbConn.select(order,"id = ?", userId)
          dbConn.delete(order)
        return "Successfully deleted user id " & $$userId & " and their orders."  
      else:
        return "The user you were trying to delete is not found"
    
    
  
    # DELETE Product by ID ******** ADMIN ONLY ******** 
    @Admin
    delete "/products/{productId:int}":
      if dbConn.exists(product.Product, "id = ?", productId):
        var product = newProduct()
        dbConn.select(product,"id = ?", productId)
        dbConn.delete(product)
        return "Successfully deleted product id " & $$productId  
      else:
        return "The product you were trying to delete is not found"
    
   
    # DELETE Order by ID *this one shouldn't be need* ******** ADMIN ONLY ******** 
    @Admin
    delete "/orders/{orderId:int}":
      if dbConn.exists(order.Order, "id = ?", orderId):
        var order = newOrder()
        dbConn.select(order,"id = ?", orderId)
        dbConn.delete(order)
        return "Successfully deleted order id " & $$orderId  
      else:
        return "The order you were trying to delete is not found"
    
      
    
    # POST Create a New User and order entry
    #[ 
    post "/users[o:User:json]":
    
      var user = newUser(o.full_name,o.age)

      dbConn.insert(user)

      var order = newOrder(user.id,"[]")
    
      dbConn.insert(order)

      echo "new user and order: ", o
      return {"response": {
        "full_name": o.full_name,
        "product_price": o.age
      }}
    ]#
      

     
    # POST Create a New Product ******** ADMIN ONLY ******** 
    @Admin
    post "/products[o:Product:json]":
        var product = newProduct(o.product_name,o.product_price)
        dbConn.insert(product)
        echo "new product: ", o
        return {"response": {
          "product_name": o.product_name,
          "product_price": o.product_price
        }}
      
   
      

   
    #NOTE email is not checked for validation also there is a better way to check role maybe

    # PUT modify an existing user by id ******** ADMIN ONLY ******** 
    @Admin
    put "/users/{userId:int}[o:User:json]":
      if dbConn.exists(user.User, "id = ?", userId):
        var user = newUser()
        dbConn.select(user,"id = ?", userId)
        if (o.role != "Admin") and (o.role != "None"):
          statusCode = 422
          return "not a valid role"
        else:
          var (hash, salt) = hashPassword(o.password)

          user.full_name = o.full_name
          user.age = o.age
          user.email = o.email
          user.role = parseEnum[Role](o.role)
          user.hash = hash
          user.salt = salt

          dbConn.update(user)
          return "Successfully updated user id " & $$userId  
      else:
        return "The user you were trying to update is not found"
     
   

    
    # PUT modify an existing product ******** ADMIN ONLY ********
    @Admin
    put "/products/{productId:int}[o:Product:json]":
      if dbConn.exists(product.Product, "id = ?", productId):
        var product = newProduct()
        dbConn.select(product,"id = ?", productId)
        product.product_name = o.product_name
        product.product_price = o.product_price
        dbConn.update(product)
        return "Successfully updated product id " & $$productId  
      else:
        return "The product you were trying to update is not found"
  

   

main()