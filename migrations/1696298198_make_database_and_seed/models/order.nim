import norm/[model, pragmas],user


type
  Order* = ref object of Model 
    user_id* {.fk: User.} : int64
    product_ids*: string


func newOrder*(user_id: int64, product_ids: string): Order =
  Order(user_id: user_id, product_ids: product_ids)


func newOrder*: Order =
  newOrder(0'i64,"")