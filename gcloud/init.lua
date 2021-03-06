-- as explained in https://developers.google.com/identity/protocols/OAuth2ServiceAccount#creatingjwt
local cjson = require "cjson"
local crypto = require("crypto")
local urlencode = require('gcloud.urlencode')
require 'gcloud.base64'
require("socket")
local https = require 'ssl.https'
local ltn12 = require("ltn12")
local upload_url = "https://www.googleapis.com/upload/storage/v1/b/"
local download_url = "https://www.googleapis.com/download/storage/v1/b/"
local datastore_url = "https://datastore.clients6.google.com/v1beta3/projects/"

M = {}


function M.from_service_account_json (json_file)
  if not path.exists(json_file) then print("JSON config file not found.") ; return false end
  file = io.open(json_file, "r")
  io.input(file)
  M.config = cjson.decode(io.read("*a"))
  print("Gcloud config file loaded.")
end

function M.get_token()
  if not M.config then return print([[Initialize the SDK with command :

    client.from_service_account_json("key.json")

     ]]) end
  local header = cjson.encode{alg="RS256",typ="JWT"}
  local current_time = os.time()
  local claim_set = cjson.encode{aud=M.config.token_uri , exp=(os.time()+10), iat= current_time,iss=M.config.client_email, scope="https://www.googleapis.com/auth/devstorage.read_write https://www.googleapis.com/auth/cloud-platform https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/datastore"}
  local input_signature = base64.encode(header) .. "." .. base64.encode (claim_set)
  local kpriv = assert(crypto.pkey.from_pem(M.config.private_key, true))
  local signature = input_signature .. "." .. base64.encode(crypto.sign('sha256', input_signature, kpriv))

  local s = "grant_type=" .. urlencode.string("urn:ietf:params:oauth:grant-type:jwt-bearer") .. "&assertion=" .. urlencode.string(signature)

  local body, code, headers, status = https.request(M.config.token_uri,s)
  -- print(body, code, headers, status)
  results = cjson.decode(body)
  if code == 200 then
    M.auth = {}
    M.auth.access_token = results.access_token
    M.auth.valid_until = results.expires_in + os.time()
  end
end

function M.check_valid_token()
  if not M.auth or os.time() > M.auth.valid_until then
    print("Refreshing token.")
    M.get_token()
  end
  if M.auth.valid_until and os.time() < M.auth.valid_until then
    print("Authenticated.")
    return true
  end
  print("No able to authenticate.")
  return false
end

function M.upload_from_string(s, bucket, dest_filepath)
  if not M.check_valid_token() then return nil end
  local url = upload_url .. bucket .. "/o?uploadType=media"
  if dest_filepath ~= nil then url = url .. "&name=" .. dest_filepath end
  local body, code, headers, status = https.request{
    url = url,
    headers = {
      ["Authorization"] = "Bearer " .. M.auth.access_token ,
      ["Content-length"] = #s,
      ["Content-Type"] =  "multipart/form-data",
    },
    method = "POST",
    source = ltn12.source.string(s)
  }
  if code ~= 200 then
    print(body, code, headers, status)
  end
  return code
end

function M.upload(filepath, bucket, dest_filepath)
  if not M.check_valid_token() then return nil end
  local fileHandle = io.open( filepath)
  local len = fileHandle:seek( "end", 0 )
	io.close(fileHandle)
  local url = upload_url .. bucket .. "/o?uploadType=media"
  if dest_filepath ~= nil then url = url .. "&name=" .. dest_filepath end
  local body, code, headers, status = https.request{
    url = url,
    headers = {
      ["Authorization"] = "Bearer " .. M.auth.access_token ,
      ["Content-Type"] =  "multipart/form-data",
      ["Content-Length"] = len
    },
    method = "POST",
    source = ltn12.source.file(io.open(filepath, "rb"))
  }
  if code ~= 200 then
    print(body, code, headers, status)
  end
  return code
end

function M.download_as_string(bucket, filepath)
  if not M.check_valid_token() then return nil end
  local url = download_url .. bucket .. "/o/" .. urlencode.string(filepath) .. "?alt=media"
  local t = {}
  local body, code, headers, status = https.request{
    url = url,
    headers = {
      ["Authorization"] = "Bearer " .. M.auth.access_token ,
    },
    method = "GET",
    sink = ltn12.sink.table(t)
  }
  if code ~= 200 then
    print(body, code, headers, status)
  end
  return  table.concat(t)
end

function M.download(bucket, filepath, file)
  if not M.check_valid_token() then return nil end
  local url = download_url .. bucket .. "/o/" .. urlencode.string(filepath) .. "?alt=media"
  local t = {}
  local body, code, headers, status = https.request{
    url = url,
    headers = {
      ["Authorization"] = "Bearer " .. M.auth.access_token ,
    },
    method = "GET",
    sink = ltn12.sink.file(io.open(file, "w"))
  }
  if code ~= 200 then
    print(body, code, headers, status)
  end
  return code
end

function M.insert(kind, properties)
  if not M.check_valid_token() then return nil end
  local url = datastore_url .. M.config.project_id .. ":commit"

  local t = {}
  local s = cjson.encode{
    mode="NON_TRANSACTIONAL",
    mutations={
      insert={
        key={
          partitionId={namespaceId=""},
          path={{kind=kind}}
        },
        properties=properties
      }
    }
  }

  local body, code, headers, status = https.request{
    url = url,
    headers = {
      ["Authorization"] = "Bearer " .. M.auth.access_token ,
      ["Content-length"] = #s,
      ["Content-Type"] =  "multipart/form-data",
    },
    method = "POST",
    source = ltn12.source.string(s),
    sink = ltn12.sink.table(t)
  }
  if code ~= 200 then
    print(body, code, headers, status)
    print(table.concat(t))
  end
  return code, cjson.decode(table.concat(t)).mutationResults[1].key.path[1].id
end

return M
