# gcloud-lua

### Install

```
luarocks install bit32
luarocks install luacrypto
luarocks install luasec OPENSSL_LIBDIR=/usr/lib/x86_64-linux-gnu
luarocks install https://raw.githubusercontent.com/fitly/gcloud-lua/master/gcloud-g-1.rockspec
```

Create a service account for your application in Gcloud console, download the private key as a `key.json` and configure your client :

```lua
client = require 'gcloud'
client.from_service_account_json("key.json")
```

### Main functions :

Upload a file to gcloud storage:

```lua
client.upload(local_file_path, bucket, gcloud_file_path)
```

Upload a string content to gcloud storage:

```lua
client.upload_from_string(string, bucket, gcloud_file_path)
```


Download a file as a string :

```lua
client.download_as_string(bucket, gcloud_file_path)
```

Download a file and save to disk :

```lua
client.download(bucket, gcloud_file_path, local_file_path)
```

Insert an entity in the datastore :

```lua
client.insert(kind, properties)
```

Example :

```lua
client.insert("MyEntity", {
  comment={stringValue="qfdqdsfqsf2",excludeFromIndexes=false},
  elapsed_time={doubleValue=10,excludeFromIndexes=false},
  time_stamp={timestampValue=os.date("!%Y-%m-%dT%H:%M:%SZ",os.time()),excludeFromIndexes=false}
})
```
