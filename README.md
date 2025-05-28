# JINI - simple jvm-starter

Jini is a simple executable for Windows that launches a JVM and starts your java app.


## Compile

### Requirements

* [MinGW](https://www.mingw-w64.org/downloads/)
* latest JDK LTS
* [Nim](https://nim-lang.org/)

```shell
# install dependencies
nimble install winim sunny
# compile jni invocation library and app
make JNI="c:/soft/java-21/include"
```

## Using

1. Compile
2. Rename jini.exe to preferred name
3. Copy exe to target location
4. In target location create folder `lib` and put classpath jars into it
5. In folder `lib` create file `package.json` which describe your distro
6. Launch exe

### package.json example

```json
{
  "main.class": "com.example.Application",
  "class.path": [
    "lib/example-1.0.jar",
    "lib/gson-2.13.0.jar",
    "lib/logback-classic-1.5.18.jar",
    "lib/logback-core-1.5.18.jar",
    "lib/slf4j-api-2.0.17.jar",
  ],
  "vm.args": [
    "-Xmx64m",
    "-XX:+UnlockExperimentalVMOptions",
    "-XX:+UseZGC"
  ],
  "args": [
    "-debug"
  ]
}
```

### Resources
Resources of exe file can be created with [rcedit](https://github.com/electron/rcedit)

```shell
rcedit "cmake-build-release/jini.exe" \
    --set-file-version "1.0.0.1" \
    --set-product-version "1.0.0.1" \
    --set-version-string "Comments" "App Comment" \
    --set-version-string "FileDescription" "File Description" \
    --set-version-string "ProductName" "Product Name" \
    --set-version-string "LegalCopyright" "Legal Copyright" \
    --set-icon "icon.ico"
```

## ROADMAP

1. gradle plugin
