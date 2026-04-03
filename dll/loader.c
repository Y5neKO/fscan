#include <stdio.h>
#include <windows.h>

typedef void (*FuncType)(const char *);

int main(int argc, char *argv[]) {
    HMODULE hDLL;
    const char *dllName = "fscan.dll";

    if (argc < 2) {
        printf("Usage: %s <dll_path> [args...]\n", argv[0]);
        printf("Example: %s fscan.dll -h 192.168.1.0/24 -p 80,443\n", argv[0]);
        return 1;
    }

    dllName = argv[1];
    hDLL = LoadLibraryA(dllName);
    if (hDLL == NULL) {
        printf("Failed to load DLL: %s\n", dllName);
        return 1;
    }

    char argBuf[4096] = {0};
    int i;
    for (i = 2; i < argc; i++) {
        if (i > 2) {
            strncat(argBuf, " ", sizeof(argBuf) - strlen(argBuf) - 1);
        }
        strncat(argBuf, argv[i], sizeof(argBuf) - strlen(argBuf) - 1);
    }

    FuncType Run = (FuncType)GetProcAddress(hDLL, "Run");
    if (Run) Run(argBuf);

    FreeLibrary(hDLL);
    return 0;
}
