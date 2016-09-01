# gcloud-lua

Install

    luarocks install bit32
    luarocks install luacrypto
    luarocks --local install luasec OPENSSL_LIBDIR=/usr/lib/x86_64-linux-gnu

Correct a bug in `~/.luarocks/share/lua/5.1/ssl/https.lua` following this [issue resolution](https://github.com/brunoos/luasec/issues/44)

Get token

    th main.lua

Use token

    curl -H "Authorization: Bearer <access_token>" -G -d part=snippet --data-urlencode id=9bZkp7q19f0 https://www.googleapis.com/youtube/v3/videos
    curl -H "Authorization: Bearer 1/fFBGRNJru1FQd44AzqT3Zg" https://www.googleapis.com/drive/v2/files
    curl https://www.googleapis.com/drive/v2/files?access_token=1/fFBGRNJru1FQd44AzqT3Zg

    GET /storage/v1/b/example-bucket/o HTTP/1.1
    Host: www.googleapis.com
    Authorization: Bearer ya29.AHES6ZRVmB7fkLtd1XTmq6mo0S1wqZZi3-Lh_s-6Uw7p8vtgSwg
