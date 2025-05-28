import os
import sunny
import std/strutils
import strformat
import winim/lean

const
    ERROR_LOAD_JVM_DLL: int = 1001
    ERROR_CREATE_JAVA_VM: int = 1002
    ERROR_MAIN_CLASS_LOAD: int = 1003
    ERROR_MAIN_METHOD_NOT_FOUND: int = 1004
    ERROR_MAIN_METHOD_INVOKE: int = 1005

const
    PATH_SEPARATOR = ":"
    SEPARATOR = "\\"

    libjini = "libjini.dll"
    homeJvmParts = @["bin", "server", "jvm.dll"]
    pathJvmParts = @["server", "jvm.dll"]

proc start_jvm(jvm_dll_path: cstring, class_path: cstring, main_class: cstring,
    vm_argc: int, vm_argv: cstringArray,
    argc: int, args: cstringArray): int {.cdecl dynlib: libjini importc: "start_jvm".}

type
    Config = object
        mainClass {.json: "main.class,required".}: string
        classPath {.json: "class.path,required".}: seq[string]
        vmArgs {.json: "vm.args,omitempty".}: seq[string]
        args {.json: ",omitempty".}: seq[string]

proc readConfig(location: string): Config =
    if fileExists(location):
        let json = readFile(location)
        let instance = Config.fromJson(json)
        return instance

    raise newException(IOError, "no config file 'lib/package.json'")

proc findJvmDll(): string =
    if existsEnv("JAVA_HOME"):
        let path = getEnv("JAVA_HOME") & SEPARATOR & homeJvmParts.join(SEPARATOR)
        return path

    let paths = getEnv("PATH").split(PATH_SEPARATOR)
    for path in paths:
        let loc = path & SEPARATOR & pathJvmParts.join(SEPARATOR)
        if fileExists(loc):
            return path

    raise newException(IOError, "cannot find jvm.dll")

proc showMessageBox(msg: string) =
    MessageBox(0, msg, "", MB_ICONERROR)

when isMainModule:
    let args = commandLineParams()
    try:
        let cfg = readConfig("lib/package.json")
        let jvmDll = findJvmDll()
        let result = start_jvm(
            cstring(jvmDll),
            cstring("-Djava.class.path=" & cfg.classPath.join(";")),
            cstring(cfg.mainClass.replace('.', '/')),
            cfg.vmArgs.len,
            allocCStringArray(cfg.vmArgs),
            args.len + cfg.args.len,
            allocCStringArray(args & cfg.args),
        )
        case result:
            of ERROR_LOAD_JVM_DLL:
                raise newException(IOError, fmt"Не найден jvm.dll ({ERROR_LOAD_JVM_DLL})")
            of ERROR_CREATE_JAVA_VM:
                raise newException(IOError, fmt"Ошибка создания JVM ({ERROR_CREATE_JAVA_VM})")
            of ERROR_MAIN_CLASS_LOAD:
                raise newException(IOError, fmt"Ошибка ({ERROR_MAIN_CLASS_LOAD})")
            of ERROR_MAIN_METHOD_NOT_FOUND:
                raise newException(IOError, fmt"Ошибка ({ERROR_MAIN_METHOD_NOT_FOUND})")
            of ERROR_MAIN_METHOD_INVOKE:
                raise newException(IOError, fmt"Ошибка ({ERROR_MAIN_METHOD_INVOKE})");
            else:
                discard
    except:
        showMessageBox(
            getCurrentExceptionMsg()
        )
