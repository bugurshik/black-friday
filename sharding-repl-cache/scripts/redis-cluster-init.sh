docker exec -t redis_1
echo "yes" | redis-cli --cluster create   173.17.0.14:6379   173.17.0.15:6379   173.17.0.16:6379   173.17.0.17:6379   --cluster-replicas 1