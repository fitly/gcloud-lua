-- as explained in https://developers.google.com/identity/protocols/OAuth2ServiceAccount#creatingjwt
local cjson = require "cjson"
local crypto = require("crypto")
local urlencode = require('lib.urlencode')
require 'lib.base64'
require("socket")
local https = require 'ssl.https'
local ltn12 = require("ltn12")
local upload_url = "https://www.googleapis.com/upload/storage/v1/b/"
local download_url = "https://www.googleapis.com/download/storage/v1/b/"

M = {}

function M.from_service_account_json (json_file)
  file = io.open(json_file, "r")
  io.input(file)
  value = cjson.decode(io.read("*a"))

  local header = [[{"alg":"RS256","typ":"JWT"}]]
  local claim_set = [[{"aud":"]] .. value.token_uri .. [[","exp":]] .. (os.time(now)+10) .. [[,"iat":]] .. os.time(now) .. [[,"iss":"]] .. value.client_email .. [[","scope":"https://www.googleapis.com/auth/devstorage.read_write"}]]
  local input_signature = base64.encode(header) .. "." .. base64.encode (claim_set)
  local kpriv = assert(crypto.pkey.from_pem(value.private_key, true))
  local signature = input_signature .. "." .. base64.encode(crypto.sign('sha256', input_signature, kpriv))


  local s = "grant_type=" .. urlencode.string("urn:ietf:params:oauth:grant-type:jwt-bearer") .. "&assertion=" .. urlencode.string(signature)

  local body, code, headers, status = https.request(value.token_uri,s)
  -- print(body, code, headers, status)
  results = cjson.decode(body)
  if code == 200 then
    M.access_token = results.access_token
    M.expires_in = results.expires_in
  end
end

function M.upload_from_string(s, bucket, dest_filepath)
  local url = upload_url .. bucket .. "/o?uploadType=media"
  if dest_filepath ~= nil then url = url .. "&name=" .. dest_filepath end
  local body, code, headers, status = https.request{
    url = url,
    headers = {
      ["Authorization"] = "Bearer " .. M.access_token ,
      ["Content-length"] = #s,
      ["Content-Type"] =  "multipart/form-data",
    },
    method = "POST",
    source = ltn12.source.string(s)
  }
  -- print(body, code, headers, status)
  return code
end

function M.upload(filepath, bucket, dest_filepath)
  local fileHandle = io.open( filepath)
  local len = fileHandle:seek( "end", 0 )
	io.close(fileHandle)
  local url = upload_url .. bucket .. "/o?uploadType=media"
  if dest_filepath ~= nil then url = url .. "&name=" .. dest_filepath end
  local body, code, headers, status = https.request{
    url = url,
    headers = {
      ["Authorization"] = "Bearer " .. M.access_token ,
      ["Content-Type"] =  "multipart/form-data",
      ["Content-Length"] = len
    },
    method = "POST",
    source = ltn12.source.file(io.open(filepath, "rb"))
  }
  -- print(body, code, headers, status)
  return code
end

function M.download_as_string(bucket, filepath)
  local url = download_url .. bucket .. "/o/" .. urlencode.string(filepath) .. "?alt=media"
  local t = {}
  local body, code, headers, status = https.request{
    url = url,
    headers = {
      ["Authorization"] = "Bearer " .. M.access_token ,
    },
    method = "GET",
    sink = ltn12.sink.table(t)
  }
  -- print(body, code, headers, status)
  return  table.concat(t)
end

function M.download(bucket, filepath, file)
  local url = download_url .. bucket .. "/o/" .. urlencode.string(filepath) .. "?alt=media"
  local t = {}
  local body, code, headers, status = https.request{
    url = url,
    headers = {
      ["Authorization"] = "Bearer " .. M.access_token ,
    },
    method = "GET",
    sink = ltn12.sink.file(io.open(file, "w"))
  }
  -- print(body, code, headers, status)
  return code
end

return M
