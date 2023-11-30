import norm/[model, pragmas]


type
  Role* = enum
    Admin, None

type
  UserAuth* = ref object of Model
    email*: string
    password*: string

type
  User* = ref object of Model
    full_name* {.index: "User_names".}: string
    age*: int
    email*: string
    role*: Role
    hash*: string
    salt*: string
    



func newUser*(full_name: string, age: int, email: string, role: Role, hash: string, salt: string): User =
  User(full_name: full_name, age: age, email: email, role: role, hash: hash, salt: salt)


func newUser*: User =
  newUser("",0,"",Role.None,"","")