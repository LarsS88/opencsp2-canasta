#!/bin/bash

cd "$MW_HOME"

cp -v /mediawiki/config/LocalSettings.php .
grep -n wfLoadSkin LocalSettings.php | sed -n 's,^\([^:]*\).*,sed -i "\1\,\$ d" LocalSettings.php,p' | head -n1 | sh
cat <<EOF>>LocalSettings.php
wfLoadSkin( 'chameleon' );
wfLoadSkin( 'Vector' );

require_once( 'settings/CSPSettings.php' );

# End of automatically generated settings.
# Add more configuration options below.
EOF

wget https://releases.wikimedia.org/mediawiki/1.39/mediawiki-1.39.10.tar.gz -q -O /tmp/mediawiki.tgz
tar zxf /tmp/mediawiki.tgz --strip-components=1

git -C /tmp/ clone https://github.com/Open-CSP/open-csp.git --branch REL1_39
find /tmp/open-csp/ -type f -name '.git*' -delete
find /tmp/open-csp/ -type d -name '.git*' -exec rm -r {} \;
cp -a /tmp/open-csp/* ./
sed -i 's,localhost:9200,elasticsearch:9200,' settings/CSPSettings.php

composer config repositories.38 composer https://gitlab.wikibase.nl/api/v4/group/38/-/packages/composer/
rm -rf extensions/* vendor/* composer.lock
composer u --no-dev
rm composer.lock
composer u --no-dev
composer u --no-dev
chmod -v +x extensions/Scribunto/includes/engines/LuaStandalone/binaries/lua5_1_5_linux_64_generic/lua
/create-symlinks.sh # Symlink all extensions and skins (both bundled and user)

mkdir images/temp
chmod 777 images/temp

php maintenance/update.php --quick
php extensions/SemanticMediaWiki/maintenance/updateEntityCountMap.php
php extensions/SemanticMediaWiki/maintenance/setupStore.php
php extensions/SemanticMediaWiki/maintenance/rebuildElasticIndex.php
if ! php extensions/PageSync/maintenance/WSps.maintenance.php --user 'Open CSP installation script'; then
    php extensions/PageSync/maintenance/WSps.maintenance.php --user 'Open CSP installation script';
fi

rm -rf /tmp/*