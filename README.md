# gcloud-lua

### Install

    luarocks install bit32
    luarocks install luacrypto
    luarocks --local install luasec OPENSSL_LIBDIR=/usr/lib/x86_64-linux-gnu

Correct a bug in `~/.luarocks/share/lua/5.1/ssl/https.lua` following this [issue resolution](https://github.com/brunoos/luasec/issues/44)

Create a service account for your application in Gcloud console, download the private key as a `key.json` and configure your client :

```lua
client = require 'gcloud.client'
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
