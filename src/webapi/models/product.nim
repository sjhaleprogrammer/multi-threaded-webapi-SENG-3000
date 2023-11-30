import norm/model


type
  Product* = ref object of Model
    product_name*: string
    product_price*: float


func newProduct*(product_name: string, product_price: float): Product =
  Product(product_name: product_name, product_price: product_price)


func newProduct*: Product =
  newProduct("",0.0)





