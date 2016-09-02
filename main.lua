client = require 'gcloud.client'
client.from_service_account_json("key.json")
blob = client.get_blob('remote/path/to/file.txt')
print(blob)
