import os
import std/json
import std/strutils

const
    PATH_SEPARATOR = ":"
    SEPARATOR = "\\"

    libjini = "libjini.dll"
    homeJvmParts = @["bin", "server", "jvm.dll"]
    pathJvmParts = @["server", "jvm.dll"]

proc start_jvm(jvm_dll_path: cstring, class_path: cstring, main_class: cstring,
    vm_argc: int, vm_argv: cstringArray,
    argc: int, args: cstringArray): int {. cdecl dynlib: libjini importc: "start_jvm" .}

proc create_mutex(name: cstring) : int {. cdecl dynlib: libjini importc: "create_mutex" .}
proc release_mutex(mutex: int) {. cdecl dynlib: libjini importc: "release_mutex" .}
proc show_error_msg(msg: cstring, title: cstring): void {. cdecl dynlib: libjini importc: "show_error_msg" .}

type
    Config = object
        mainClass: string
        classPath: seq[string]
        vmArgs: seq[string]
        args: seq[string]

proc readConfig(location: string): Config =
    if fileExists(location):
        let json = parseFile(location)
        var vmArgs: seq[string] = @[]
        for node in json{"vm.args"}.getElems():
            vmArgs.add(node.getStr())
        var args: seq[string] = @[]
        for node in json{"args"}.getElems():
            args.add(node.getStr())
        let cfg = Config(
            mainClass: json["main.class"].getStr(),
            classPath: json["class.path"].to(seq[string]),
            vmArgs: vmArgs,
            args: args,
        )
        return cfg

    raise newException(IOError, "Package description not found")

proc findJvmDll(): string =
    if existsEnv("JAVA_HOME"):
        let path = getEnv("JAVA_HOME") & SEPARATOR & homeJvmParts.join(SEPARATOR)
        return path

    let paths = getEnv("PATH").split(PATH_SEPARATOR)
    for path in paths:
        let loc = path & SEPARATOR & pathJvmParts.join(SEPARATOR)
        if fileExists(loc):
            return path

    raise newException(IOError, "Not found jvm.dll")

when isMainModule:
    let args = commandLineParams()
    try:
        let cfg = readConfig("lib/package.json")
        let handle = create_mutex(cstring(cfg.mainClass))
        if handle == 0:
            system.quit("another instance already running", 1)

        let jvmDll = findJvmDll()
        discard start_jvm(
            cstring(jvmDll),
            cstring("-Djava.class.path=" & cfg.classPath.join(";")),
            cstring(cfg.mainClass.replace('.', '/')),
            cfg.vmArgs.len,
            allocCStringArray(cfg.vmArgs),
            args.len + cfg.args.len,
            allocCStringArray(args & cfg.args),
        )

        release_mutex(handle)
    except JsonParsingError, ValueError:
        show_error_msg(
            cstring("Package description read error: " & getCurrentExceptionMsg()),
            cstring("")
        )
    except:
        show_error_msg(
            cstring(getCurrentExceptionMsg()),
            cstring("")
        );
