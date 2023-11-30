include normanpkg/prelude

import strutils
import sugar

import norm/sqlite

import models/[user,order,product]

import ../../src/password_manager



migrate:
  withDb:
    db.transaction:
      db.createTables(newUser())
    db.transaction:
      db.createTables(newProduct())
    db.transaction:
      db.createTables(newOrder())


    #john and jane have the same password
    let (hash, salt) = hashPassword("123")


    var 
      john = newUser("John",25,"john@gmail.com",Role.Admin,hash,salt)
      jane = newUser("Jane",21,"jane@gmail.com",Role.None,hash,salt)
    

    discard john.dup:
        db.insert
    discard jane.dup:
        db.insert
    
    discard newProduct("Apple",2.99).dup:
        db.insert
    discard newProduct("Banana",3.00).dup:
        db.insert

    discard newOrder(john.id,"[0,1]").dup:
        db.insert
    discard newOrder(jane.id,"[1]").dup:
        db.insert


  


undo:
  let qry1 = """DROP TABLE IF EXISTS "User""""
  let qry2 = """DROP TABLE IF EXISTS "Product""""
  let qry3 = """DROP TABLE IF EXISTS "Order""""
  

  withDb:
    debug qry1
    debug qry2
    debug qry3

    db.exec sql qry3
    db.exec sql qry2
    db.exec sql qry1