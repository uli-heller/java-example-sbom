#!/bin/sh
#
# ./create-version.sh project version...
#
# ./create-version.sh hello-world 1.0.0
# -> creates for "hello-world" the version within the local maven repository
#
#      maven-repository/cool/heller/uli/hello-world/maven-metadata.xml
#      maven-repository/cool/heller/uli/hello-world/maven-metadata.xml.sha512
#      maven-repository/cool/heller/uli/hello-world/maven-metadata.xml.sha1
#      maven-repository/cool/heller/uli/hello-world/maven-metadata.xml.sha256
#      maven-repository/cool/heller/uli/hello-world/maven-metadata.xml.md5
#      maven-repository/cool/heller/uli/hello-world/1.0.0/hello-world-1.0.0.module.sha512
#      maven-repository/cool/heller/uli/hello-world/1.0.0/hello-world-1.0.0-plain.jar
#      maven-repository/cool/heller/uli/hello-world/1.0.0/hello-world-1.0.0.module.sha256
#      maven-repository/cool/heller/uli/hello-world/1.0.0/hello-world-1.0.0.pom
#      maven-repository/cool/heller/uli/hello-world/1.0.0/hello-world-1.0.0-plain.jar.md5
#      maven-repository/cool/heller/uli/hello-world/1.0.0/hello-world-1.0.0-plain.jar.sha512
#      maven-repository/cool/heller/uli/hello-world/1.0.0/hello-world-1.0.0.module.sha1
#      maven-repository/cool/heller/uli/hello-world/1.0.0/hello-world-1.0.0.pom.sha256
#      maven-repository/cool/heller/uli/hello-world/1.0.0/hello-world-1.0.0-plain.jar.sha1
#      maven-repository/cool/heller/uli/hello-world/1.0.0/hello-world-1.0.0-plain.jar.sha256
#      maven-repository/cool/heller/uli/hello-world/1.0.0/hello-world-1.0.0.pom.md5
#      maven-repository/cool/heller/uli/hello-world/1.0.0/hello-world-1.0.0.module
#      maven-repository/cool/heller/uli/hello-world/1.0.0/hello-world-1.0.0.pom.sha1
#      maven-repository/cool/heller/uli/hello-world/1.0.0/hello-world-1.0.0.module.md5
#
# ./create-version.sh bye-moon  0.9.0 0.9.1 1.0-SNAPSHOT
# -> creates for "bye-moon" multiple versions within the local maven repository
#
D="$(dirname "$0")"
D="$(realpath "${D}")"
BN="$(basename "$0")"

MAVEN_REPOSITORY="${D}/maven-repository"
MAVEN_REPOSITORY_URL="file://${MAVEN_REPOSITORY}"

#rm -rf "${MAVEN_REPOSITORY}"

PROJECT="$1"
shift

test -d "${PROJECT}" || {
    echo >&2 "${BN}: Unable to find project '${PROJECT}'"
    exit 1
}

RC=0
while [ $# -gt 0 ]; do
    VERSION=$1
    shift
    ( cd "${PROJECT}"; "${D}/gradlew" publish -Pversion=${VERSION} -PmavenRepositoryUrl="${MAVEN_REPOSITORY_URL}" )
    NRC=$?
    test "$RC" -eq 0 && RC=$NRC
done

exit "${RC}"
