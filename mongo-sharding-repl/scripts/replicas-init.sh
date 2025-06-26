docker compose exec -T shard1_node1 mongosh --port 27018 <<EOF
 rs.initiate({_id: "shard1", members: [
{_id: 0, host: "shard1_node1:27018"},
{_id: 1, host: "shard1_node2:27019"},
{_id: 2, host: "shard1_node3:27030"}
]})
);
EOF

docker compose exec -T shard2_node1 mongosh --port 27021 <<EOF
 rs.initiate({_id: "shard2", members: [
{_id: 0, host: "shard2_node1:27021"},
{_id: 1, host: "shard2_node2:27022"},
{_id: 2, host: "shard2_node3:27023"}
]})
);
EOF
