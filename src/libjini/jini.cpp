#include <jni.h>
#include <stdio.h>
#include <windows.h>

#define ERROR_LOAD_JVM_DLL 1001
#define ERROR_CREATE_JAVA_VM 1002
#define ERROR_MAIN_CLASS_LOAD 1003
#define ERROR_MAIN_METHOD_NOT_FOUND 1004
#define ERROR_MAIN_METHOD_INVOKE 1005

typedef jint (JNICALL *CreateJavaVM)(JavaVM **, void **, void *);

void print_error(JNIEnv *env, jthrowable th) {
    jclass throwable_class = env->FindClass("java/lang/Throwable");
    jmethodID get_msg = env->GetMethodID(throwable_class, "printStackTrace", "()V");
    env->CallVoidMethod(th, get_msg);
}

bool check_exception(JNIEnv *env) {
    if (env->ExceptionCheck()) {
        jthrowable thr = env->ExceptionOccurred();
        print_error(env, thr);
        env->ExceptionClear();
        return true;
    }
    return false;
}

extern "C" int start_jvm(char *jvm_dll_path, char *class_path, char *main_class,
                         int vm_argc, char *vm_argv[], int argc, char *argv[]) {
    auto jvm_dll = LoadLibrary(jvm_dll_path);
    if (jvm_dll == nullptr) {
        return ERROR_LOAD_JVM_DLL;
    }
    CreateJavaVM createJavaVM = (CreateJavaVM) GetProcAddress(jvm_dll, "JNI_CreateJavaVM");

    JavaVMOption *options = new JavaVMOption[vm_argc + 1];
    options[0].optionString = class_path;
    for (int i = 0; i < vm_argc; ++i) {
        options[i + 1].optionString = vm_argv[i];
    }

    JavaVMInitArgs vm_init_args;
    vm_init_args.version = JNI_VERSION_21;
    vm_init_args.nOptions = vm_argc + 1;
    vm_init_args.options = options;
    vm_init_args.ignoreUnrecognized = true;

    JavaVM *jvm;
    JNIEnv *env;
    createJavaVM(&jvm, (void **) &env, &vm_init_args);
    delete[] options;
    if (jvm == nullptr || env == nullptr) {
        return ERROR_CREATE_JAVA_VM;
    }

    jclass clz = env->FindClass(main_class);
    if (clz == nullptr) {
        check_exception(env);
        return ERROR_MAIN_CLASS_LOAD;
    }
    jmethodID main_method = env->GetStaticMethodID(clz, "main", "([Ljava/lang/String;)V");
    if (main_method == nullptr) {
        check_exception(env);
        return ERROR_MAIN_METHOD_NOT_FOUND;
    }

    jclass str_clz = env->FindClass("java/lang/String");
    jobjectArray params = env->NewObjectArray(argc, str_clz, env->NewStringUTF(""));
    for (int i = 0; i < argc; ++i) {
        env->SetObjectArrayElement(params, i, env->NewStringUTF(argv[i]));
    }
    env->CallStaticVoidMethod(clz, main_method, params);
    if (check_exception(env)) {
        return ERROR_MAIN_METHOD_INVOKE;
    }

    jvm->DestroyJavaVM();
    return 0;
}
