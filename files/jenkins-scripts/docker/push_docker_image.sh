#!/bin/bash

#digest=$(curl -k -X GET https://net-docker-registry.adm.netways.de:5000/v2/$image_name/manifests/latest | grep blobSum | cut -d '"' -f4)
#curl -k -X DELETE https://net-docker-registry.adm.netways.de:5000/v2/$image_name/manifests/$digest

docker tag $image_name net-docker-registry.adm.netways.de:5000/$image_name
pushed=0
for i in $(seq 1 $END); do
  if docker push net-docker-registry.adm.netways.de:5000/$image_name; then
	pushed=1
    break
  fi
  sleep 30
done

docker rmi $image_name
docker rmi net-docker-registry.adm.netways.de:5000/$image_name

if [ "$pushed" != "1" ]; then
	exit 1
fi
