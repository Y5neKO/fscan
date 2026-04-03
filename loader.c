#include <stdio.h>
#include <windows.h>

typedef void (*FuncType)();

int main(int argc, char *argv[]) {
    HMODULE hDLL;
    const char *dllName = "fscan.dll";

    if (argc > 1) {
        dllName = argv[1];
    }

    hDLL = LoadLibraryA(dllName);
    if (hDLL == NULL) {
        printf("Failed to load DLL: %s\n", dllName);
        return 1;
    }

    FuncType Run = (FuncType)GetProcAddress(hDLL, "Run");
    FuncType Start = (FuncType)GetProcAddress(hDLL, "Start");
    FuncType Execute = (FuncType)GetProcAddress(hDLL, "Execute");

    if (Run) Run();
    if (Start) Start();
    if (Execute) Execute();

    FreeLibrary(hDLL);
    return 0;
}
