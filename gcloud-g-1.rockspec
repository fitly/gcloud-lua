package = 'gcloud'
version = 'g-1'

source = {
   url = 'git://github.com/fitly/gcloud-lua',
}

description = {
   summary = 'Lightweigth library for Gcloud in Lua',
   detailed = [[Lightweigth library for Gcloud in Lua]],
   homepage = 'https://github.com/fitly/gcloud-lua'
}

dependencies = {
   'bit32',
   'luacrypto',
   'luasec  >= 0.6'
}

build = {
   type = 'command',
   install_command = 'cp -r gcloud $(LUADIR)'
}
