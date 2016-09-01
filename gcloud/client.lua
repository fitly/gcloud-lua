-- as explained in https://developers.google.com/identity/protocols/OAuth2ServiceAccount#creatingjwt
local cjson = require "cjson"
local crypto = require("crypto")
require 'base64'
require("socket")
local https = require 'ssl.https'

M = {}

function M.from_service_account_json (json_file)
  -- read
  file = io.open(json_file, "r")
  io.input(file)
  value = cjson.decode(io.read("*a"))

  local header = [[{"alg":"RS256","typ":"JWT"}]]
  local claim_set = [[{"aud":"]] .. value.token_uri .. [[","exp":]] .. (os.time(now)+10) .. [[,"iat":]] .. os.time(now) .. [[,"iss":"]] .. value.client_email .. [[","scope":"https://www.googleapis.com/auth/devstorage.read_write"}]]
  local input_signature = base64.encode(header) .. "." .. base64.encode (claim_set)
  local kpriv = assert(crypto.pkey.from_pem(value.private_key, true))
  local signature = input_signature .. "." .. base64.encode(crypto.sign('sha256', input_signature, kpriv))

  local urlencode = require('urlencode')
  local s = "grant_type=" .. urlencode.string("urn:ietf:params:oauth:grant-type:jwt-bearer") .. "&assertion=" .. urlencode.string(signature)

  local body, code, headers, status = https.request(value.token_uri,s)
  print(body, code, headers, status)
end


return M
