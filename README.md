java-example-trivy-sbom
=======================

This is an example project.
I use it to verify the creation
of an SBOM with the help of TRIVY.

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
#    id 'org.cyclonedx.bom' version '+'
# }
#
./gradlew cyclonedxBom
# -> build/reports/application.cdx.json 
```


For a huge project, my team and myself
create lots of utility libraries (libs) and publish
them to a maven repository. These libs
are used by other gradle projects.

<!--more-->

Goals
-----

- gradle projects may use the libs already, specifying bad versions for them.
  These should be overridden!
- all gradle projects should use a "similar" version of the libs, i.e. '0.+'
- the version should be specified in a central place
- the number of libs may vary over time, i.e. we start with "hello-world",
  add "bye-moon" later on, add "maybe-mars" even later and so on

Constraints
-----------

For other parts, I created a BOM project containing constraints
of various components, something like

- my-platform
  - build.gradle
    ```
    ...
    dependencies {
      constraints {
        api('cool.heller.xml:my-xml-reader:2.+')
        api('cool.heller.xml:my-xml-writer:3.+')
	...
      }
    }
    ```

I cannot use this approach for the libs, since
it would require to list all the available lists within
the constraints. I want the list to be variable!

UseVersion
----------

build.gradle:

```
...
apply from:  'cool-heller-uli.gradle'
...
``

cool-heller-uli.gradle:

```
ext {
  coolHellerUliVersion='1.+'
}

allprojects {
  dependencies {
    configurations.all {
      resolutionStrategy.eachDependency { DependencyResolveDetails details ->
        if (details.requested.group == 'cool.heller.uli') {
          details.useVersion coolHellerUliVersion
        }
      }
    }
  }
}
```

Basic Test Procedure
---------------------

```
rm -rf maven-repository
./create-maven-repository.sh 0 2
./create-maven-repository.sh 1 2
./gradlew build                                  # --> BUILD SUCCESSFUL
unzip -v build/libs/java*SNAPSHOT.jar|grep hello # --> hello-world-1.2.0-plain.jar
unzip -v build/libs/java*SNAPSHOT.jar|grep bye   # --> bye-moon-1.2.0-plain.jar
```

Works quite good!

- Latest version matching '1.+' is used
- Version '0.1.0' of hello-world is ignored
- Unspecified version for bye-moon works, too

Using Gradle Dependency Locking
-------------------------------

```
rm -rf maven-repository
./create-maven-repository.sh 0 2
./create-maven-repository.sh 1 2
./gradlew dependencies --write-locks             # --> BUILD SUCCESSFUL, *lockfile created
./gradlew build                                  # --> BUILD SUCCESSFUL
unzip -v build/libs/java*SNAPSHOT.jar|grep hello # --> hello-world-1.2.0-plain.jar
unzip -v build/libs/java*SNAPSHOT.jar|grep bye   # --> bye-moon-1.2.0-plain.jar
```

Using Gradle Dependency Locking With Fresh Dependencies
-------------------------------------------------------

```
rm -rf maven-repository
./create-maven-repository.sh 0 2
./create-maven-repository.sh 1 2
./gradlew dependencies --write-locks             # --> BUILD SUCCESSFUL, *lockfile created
./create-maven-repository.sh 1 3
./gradlew build                                  # --> BUILD FAILED
```

The build fails with this error message:

```
$ ./gradlew build
To honour the JVM settings for this build a single-use Daemon process will be forked. For more on this, please refer to https://docs.gradle.org/8.11.1/userguide/gradle_daemon.html#sec:disabling_the_daemon in the Gradle documentation.
Daemon will be stopped at the end of the build 
> Task :compileJava FAILED

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':compileJava'.
> Could not resolve all files for configuration ':compileClasspath'.
   > Did not resolve 'cool.heller.uli:bye-moon:1.2.0' which has been forced / substituted to a different version: '1.3.0'
   > Did not resolve 'cool.heller.uli:hello-world:1.2.0' which has been forced / substituted to a different version: '1.3.0'

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 5s
1 actionable task: 1 executed
```

This is kindof unexpected!
I hoped that the build will silently use version 1.2.0,
the version we locked previously!

Adding A Gradle Dependency Without useVersion
---------------------------------------------

I added a dependency named "maybe-mars". It uses the same
dynamic version "1.+", but without any usage of "useVersion()".

Same as before:

```
rm -rf maven-repository
./create-maven-repository.sh 0 2
./create-maven-repository.sh 1 2
./gradlew dependencies --write-locks             # --> BUILD SUCCESSFUL, *lockfile created
./create-maven-repository.sh 1 3
./gradlew build                                  # --> BUILD FAILED
```

Within the error message, "maybe-mars" does **NOT** show up:

```
java-example-gradle-useversion$ ./gradlew build
> Task :compileJava FAILED

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':compileJava'.
> Could not resolve all files for configuration ':compileClasspath'.
   > Did not resolve 'cool.heller.uli:hello-world:1.2.0' which has been forced / substituted to a different version: '1.3.0'
   > Did not resolve 'cool.heller.uli:bye-moon:1.2.0' which has been forced / substituted to a different version: '1.3.0'

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 1s
```

Within the lockfile, all three dependencies look similar:

```
java-example-gradle-useversion$ grep heller *lockfile
gradle.lockfile:cool.heller.uli:bye-moon:1.2.0=compileClasspath,productionRuntimeClasspath,runtimeClasspath,testCompileClasspath,testRuntimeClasspath
gradle.lockfile:cool.heller.uli:hello-world:1.2.0=compileClasspath,productionRuntimeClasspath,runtimeClasspath,testCompileClasspath,testRuntimeClasspath
gradle.lockfile:cool.heller:maybe-mars:1.2.0=compileClasspath,productionRuntimeClasspath,runtimeClasspath,testCompileClasspath,testRuntimeClasspath
```

So: I do guess the issue is within "useVersion()"!
