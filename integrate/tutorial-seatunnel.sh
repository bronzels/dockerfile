docker run  --restart=always -itd --name mongo -p 27017:27017 mongo:latest --auth
#进入mongo
docker exec -it mongo mongosh admin
  db.createUser({ user:'admin',pwd:'123456',roles:[{ role:'userAdminAnyDatabase', db: 'admin'},"readWriteAnyDatabase"]})
  db.auth('admin', '123456')
  db.createUser(
    {
      user:"root",
      pwd:"123456",
      roles:[{role:"root",db:"admin"}]
    }
  );
docker restart mongo
docker exec -it mongo mongosh --username admin --password 123456
  use inventory
  db.createCollection("products")
  db.products.insert({_id:"001",name:'toyota',model:'camery',price:180000})
  db.products.insert({_id:"002",name:'li',model:'l9',price:450000})
  db.products.insert({_id:"003",name:'pyd',model:'bao5',price:320000})
  db.products.insert({_id:"004",name:'fort',model:'bronco',price:350000})
  db.products.find()