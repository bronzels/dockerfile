if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    MYHOME=/Volumes/data
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    MYHOME=/data0
    SED=sed
fi

myns=$1
echo "myns:$myns"
kubectl get ns $myns -o json  > delete-$myns.json
$SED -i '/            \"kubernetes\"/d' delete-$myns.json
kubectl proxy &
sleep 1
PID=$!
curl -X PUT http://localhost:8001/api/v1/namespaces/$myns/finalize -H "Content-Type: application/json" --data-binary @delete-$myns.json
kill $PID
