#!/usr/bin/env bash
set -eu
# build-debian-packages.sh:
# Build Debian packages for Neo4j Community from tarball

workspace=${1}
template_common_directory=${2}
template_directory=${3}
version=${4}
stability=${5}
package=${6}

# Prepare workspace
package_directory=${workspace}/debian/package
mkdir -p ${package_directory}
cp -r ${template_directory}/* ${package_directory}

# Update changelog
VERSION=${version} STABILITY=${stability} DATE=`date -R` envsubst '${VERSION} ${STABILITY} ${DATE}' < ${template_directory}/debian/changelog > ${package_directory}/debian/changelog
VERSION=${version} envsubst '${VERSION}' < ${template_directory}/debian/files > ${package_directory}/debian/files

# Untar the tarball
cp -r ${package}/* ${package_directory}/server

# Make the Neo4j init scripts available to debuild
cp ${template_common_directory}/neo4j ${package_directory}/server

# Make the default values file available to debuild
mkdir -p ${package_directory}/server/default
cp ${template_common_directory}/default/neo4j ${package_directory}/server/default

# Make the Neo4j wrapper scripts available to debuild
mkdir -p ${package_directory}/server/scripts
cp ${template_common_directory}/neo4j-script ${package_directory}/server/scripts/neo4j
cp ${template_common_directory}/neo4j-script ${package_directory}/server/scripts/neo4j-admin
cp ${template_common_directory}/neo4j-script ${package_directory}/server/scripts/neo4j-import
cp ${template_common_directory}/neo4j-script ${package_directory}/server/scripts/neo4j-shell

# Make UDC successful
sed -i 's/unsupported.dbms.udc.source=tarball/unsupported.dbms.udc.source=debian/' ${package_directory}/server/conf/neo4j-wrapper.conf

# Modify directories to match the FHS (https://www.debian.org/doc/packaging-manuals/fhs/fhs-2.3.html)
sed -i 's/#dbms.directories.data=data/dbms.directories.data=\/var\/lib\/neo4j\/data/'             ${package_directory}/server/conf/neo4j.conf
sed -i 's/#dbms.directories.plugins=plugins/dbms.directories.plugins=\/var\/lib\/neo4j\/plugins/' ${package_directory}/server/conf/neo4j.conf
sed -i 's/#dbms.directories.import=import/dbms.directories.import=\/var\/lib\/neo4j\/import/'     ${package_directory}/server/conf/neo4j.conf
cat ${template_common_directory}/directories.conf >>${package_directory}/server/conf/neo4j.conf

# Copy manpages into place
cp -r ${template_common_directory}/manpages ${package_directory}

# Make scripts executable
chmod 700 ${package_directory}/server/bin/neo4j
chmod 700 ${package_directory}/server/bin/neo4j-shell
chmod 700 ${package_directory}/server/bin/neo4j-import
#chmod 700 ${package_directory}/server/bin/neo4j-backup
chmod 700 ${package_directory}/server/bin/neo4j-admin

chmod 700 ${package_directory}/server/scripts/neo4j
chmod 700 ${package_directory}/server/scripts/neo4j-shell
chmod 700 ${package_directory}/server/scripts/neo4j-import
#chmod 700 ${package_directory}/server/scripts/neo4j-backup
chmod 700 ${package_directory}/server/scripts/neo4j-admin

# build package and metadata files
(cd ${package_directory} && debuild -B -uc -us --lintian-opts --profile debian)

