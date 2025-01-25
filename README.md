java-example-sbom
=======================

This is an example project.
I use it to verify the creation
of an SBOM with the help of TRIVY
or the CDXGEN gradle plugin.

Please note: I know that typically,
you integrate sub projects via "settings.gradle".
This is NOT what I want to do here!
I want the sub project to show up as
independent components of my java project!

Here is the test procedure:

```
./create-maven-repository.sh
./gradlew build
#
# sbom using trivy -> does not seem to work
#
trivy filesystem . --format spdx-json --output sbom.json
trivy filesystem build/libs --format spdx-json --output sbom.json
trivy filesystem build/libs/java-example-trivy-sbom-0.0.2.jar --format spdx-json --output sbom.json
#
# https://www.thomasvitale.com/supply-chain-security-java-sbom/
# plugins {
#    id 'org.cyclonedx.bom' version '+' //-> 2.0.0
# }
#
./gradlew cyclonedxBom
# -> build/reports/application.cdx.json

# Activate dependency locking
./gradlew --write-locks dependencies
trivy filesystem gradle.lockfile --format spdx-json --output sbom.json
# -> sbom.json
```
