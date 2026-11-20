/* Arabic Editor: نافذة Win32 فارغة (Unicode) */
#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#include <windows.h>

static const wchar_t CLASS_NAME[] = L"ArabicEditorWindow";
static const wchar_t WINDOW_TITLE[] = L"Arabic Editor";

static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg) {
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PWSTR lpCmdLine, int nCmdShow)
{
    (void)hPrevInstance;
    (void)lpCmdLine;

    WNDCLASSEXW wc = {0};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursorW(NULL, (LPCWSTR)IDC_ARROW);
    wc.hIcon = LoadIconW(NULL, (LPCWSTR)IDI_APPLICATION);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = CLASS_NAME;

    if (!RegisterClassExW(&wc)) {
        MessageBoxW(NULL, L"RegisterClassExW failed", WINDOW_TITLE, MB_ICONERROR);
        return 1;
    }

    HWND hwnd = CreateWindowExW(0, CLASS_NAME, WINDOW_TITLE, WS_OVERLAPPEDWINDOW,
                                CW_USEDEFAULT, CW_USEDEFAULT, 800, 600,
                                NULL, NULL, hInstance, NULL);
    if (!hwnd) {
        MessageBoxW(NULL, L"CreateWindowExW failed", WINDOW_TITLE, MB_ICONERROR);
        return 1;
    }

    ShowWindow(hwnd, nCmdShow);
    UpdateWindow(hwnd);

    MSG msg;
    while (GetMessageW(&msg, NULL, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}
