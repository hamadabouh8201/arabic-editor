# تحليل editor.exe بـ REA (Ghidra 12.2)

SHA-256: `6b09f03dd6e739e2ff9ce667716bfe69a5be2a7061a2d184aa7ddc3409b58eb9`

الأوامر:

```bash
rea decompile build/editor.exe wWinMain --provider ghidra
rea decompile build/editor.exe 0x140001480 --provider ghidra
```

## wWinMain

```c
int __stdcall wWinMain(HINSTANCE hInstance,HINSTANCE hPrevInstance,LPWSTR lpCmdLine,int nShowCmd)

{
  ATOM AVar1;
  BOOL BVar2;
  HICON pHVar3;
  HWND hWnd;
  tagMSG local_a8;
  WNDCLASSEXW local_78;
  
  local_78.cbWndExtra = 0;
  local_78.hIcon._0_4_ = 0;
  local_78.hbrBackground._4_4_ = 0;
  local_78.lpszMenuName = (LPCWSTR)0x0;
  local_78.hIcon._4_4_ = 0;
  local_78.hCursor = (HCURSOR)0x0;
  local_78.hbrBackground._0_4_ = 0;
  local_78.lpszClassName._0_4_ = 0;
  local_78.lpszClassName._4_4_ = 0;
  local_78.hIconSm = (HICON)0x0;
  local_78.cbSize = 0x50;
  local_78._4_12_ = ZEXT812(0x140001480) << 0x20;
  local_78.cbClsExtra = 0;
  local_78.hInstance = hInstance;
  local_78.hCursor = LoadCursorW((HINSTANCE)0x0,(LPCWSTR)0x7f00);
  pHVar3 = LoadIconW((HINSTANCE)0x0,(LPCWSTR)0x7f00);
  local_78.lpszClassName._0_4_ = 0x40004080;
  local_78.lpszClassName._4_4_ = 1;
  local_78.hIcon._0_4_ = SUB84(pHVar3,0);
  local_78.hIcon._4_4_ = (undefined4)((ulonglong)pHVar3 >> 0x20);
  local_78.hbrBackground._0_4_ = 6;
  local_78.hbrBackground._4_4_ = 0;
  AVar1 = RegisterClassExW(&local_78);
  if (AVar1 == 0) {
    MessageBoxW((HWND)0x0,L"RegisterClassExW failed",L"Arabic Editor",0x10);
  }
  else {
    hWnd = CreateWindowExW(0,L"ArabicEditorWindow",L"Arabic Editor",0xcf0000,-0x80000000,-0x80000000
                           ,800,600,(HWND)0x0,(HMENU)0x0,hInstance,(LPVOID)0x0);
    if (hWnd != (HWND)0x0) {
      ShowWindow(hWnd,nShowCmd);
      UpdateWindow(hWnd);
      while( true ) {
        BVar2 = GetMessageW(&local_a8,(HWND)0x0,0,0);
        if (BVar2 < 1) break;
        TranslateMessage(&local_a8);
        DispatchMessageW(&local_a8);
      }
      return (int)local_a8.wParam;
    }
    MessageBoxW((HWND)0x0,L"CreateWindowExW failed",L"Arabic Editor",0x10);
  }
  return 1;
}
```

## 0x140001480

```c
LRESULT WndProc(HWND param_1,UINT param_2,WPARAM param_3,LPARAM param_4)

{
  LRESULT LVar1;
  
  if (param_2 == 2) {
    PostQuitMessage(0);
    return 0;
  }
                    /* WARNING: Could not recover jumptable at 0x00014000148d. Too many branches */
                    /* WARNING: Treating indirect jump as call */
  LVar1 = DefWindowProcW(param_1,param_2,param_3,param_4);
  return LVar1;
}
```
