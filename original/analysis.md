# تحليل Notepad2 4.2.25 (x64) بأدوات REA

- **المصدر:** `https://www.flos-freeware.ch/zip/notepad2_4.2.25_x64.zip`
  (SHA-256 للأرشيف: `37a62f7e891335a1e671f444cefe761fcd814a2fa1a3141fe2501d8433d8920b`)
- **الملف المحلَّل:** `original/notepad2_4.2.25_x64/Notepad2.exe`
  (SHA-256: `c6086336a827a9852ee5cf6f46ffb7b1fccf82f194132a0c8a217d1240654f9f`، الحجم 919552 بايت)
- **الرخصة:** BSD بثلاث فقرات (`License.txt`، حقوق Florian Balmer 2004-2011). تسمح بالدراسة وإعادة التوزيع بشرط إرفاق نص الرخصة.
- **الأدوات:** `rea-agents@6.10.1` من سطر الأوامر، مع Ghidra 12.2 و JDK 25:
  `inspect-pe-imports` و `inspect-binary-hardening` و `inspect-pe-resources` و `analyze` و `procedure-references` و `decompile-all`.
  أداة `inspect-binary-layout` لم تعمل لأنها تحتاج pwntools، وهو غير مثبّت.

## 1. نوع الملف

| الخاصية | القيمة |
|---|---|
| الصيغة | PE32+ (Windows 64 بت)، تطبيق واجهة رسومية (GUI) |
| المعالج | x86-64 (AMD64)، وعنوان التحميل الافتراضي `0x140000000` |
| الأقسام | `.text` (668KB كود)، `.data` (136KB)، `.pdata` (جداول الاستثناءات)، `.rsrc` (108KB موارد)، `.reloc` |
| المترجم | Microsoft Visual C++. الدليل: اعتماده على `msvcrt.dll` و `msvcp60.dll`، ومعلومات أنواع C++ بصيغة MSVC مثل `.?AVScintillaWin@@` |
| الإصدار (VERSIONINFO) | `Notepad2 4.2.25`، والاسم الداخلي `notepad2.exe` |
| الحماية | ASLR (`dynamic_base`) و NX مفعّلان. `high_entropy_va` و CFG معطّلان. لا توقيع رقمي ولا سجل تصحيح (PDB) |
| رموز التصحيح | غير موجودة، لذلك تظهر الدوال بأسماء Ghidra الافتراضية `FUN_<address>` |

**الموارد (87 موردا):** 30 جدول نصوص، و29 مربع حوار، و11 أيقونة (في 3 مجموعات)، و6 صور bitmap (لشريط الأدوات)، وقائمتان،
وجدولا اختصارات لوحة المفاتيح، ومؤشر فأرة واحد، ومورد VERSIONINFO، وملف manifest.

## 2. المكتبات المستوردة من ويندوز

REA قرأ جدول الاستيراد كاملا (`coverage: complete`): **506 دالة من 12 مكتبة**، دون أي استيراد مؤجَّل (delay-load).
قيمة imphash هي `37dbcc3aa03d6ea9633e60bf6bdf58bb`.

| المكتبة | عدد الدوال | فيمَ يستعملها Notepad2 | أمثلة |
|---|---:|---|---|
| `USER32.dll` | 173 | النوافذ والقوائم ومربعات الحوار والحافظة والمؤشر النصي وحلقة الرسائل | `CreateWindowExW` و `GetMessageW` و `TranslateAcceleratorW` و `TrackPopupMenuEx` و `SetClipboardData` و `CreateCaret` |
| `KERNEL32.dll` | 104 | الملفات وتحويل الترميزات والذاكرة وملف الإعدادات ini | `CreateFileW` و `ReadFile` و `WriteFile` و `MultiByteToWideChar` و `WritePrivateProfileStringW` |
| `msvcrt.dll` | 58 | مكتبة C: الذاكرة والنصوص ومعالجة استثناءات C++ | `memmove` و `qsort` و `sscanf` و `__CxxFrameHandler` |
| `GDI32.dll` | 50 | الخطوط والرسم والطباعة | `CreateFontIndirectW` و `ExtTextOutW` و `StartDocW` و `StartPage` |
| `SHLWAPI.dll` | 50 | معالجة المسارات والنصوص | `PathCanonicalizeW` و `PathRelativePathToW` و `StrStrIW` و `SHAutoComplete` |
| `msvcp60.dll` | 23 | `std::string` من مكتبة C++، ويستعملها مكوّن Scintilla | `basic_string::find` و `insert` و `erase` |
| `SHELL32.dll` | 17 | السحب والإفلات، وتشغيل البرامج، والمجلدات الخاصة، وأيقونة منطقة الإشعارات | `DragQueryFileW` و `ShellExecuteExW` و `SHBrowseForFolderW` و `Shell_NotifyIconW` |
| `ole32.dll` | 10 | سحب النص وإفلاته (OLE) و COM | `OleInitialize` و `RegisterDragDrop` و `DoDragDrop` |
| `COMDLG32.dll` | 6 | مربعات الحوار القياسية | `GetOpenFileNameW` و `GetSaveFileNameW` و `ChooseFontW` و `ChooseColorW` و `PrintDlgW` و `PageSetupDlgW` |
| `COMCTL32.dll` | 6 | شريط الأدوات وشريط الحالة وقوائم الصور | `InitCommonControlsEx` و `CreateStatusWindowW` و `ImageList_Create` |
| `IMM32.dll` | 6 | محرر طرق الإدخال (IME) للغات الآسيوية | `ImmGetCompositionStringW` و `ImmSetCompositionWindow` |
| `ADVAPI32.dll` | 3 | كشف UTF-16 وصلاحيات المستخدم | `IsTextUnicode` و `OpenProcessToken` و `GetTokenInformation` |

**ملاحظة:** في الملف `FindTextW` و `ReplaceTextW` غير مستوردتين، فالبحث والاستبدال في Notepad2 يستعملان مربعات حوار من موارده هو، لا مربعات ويندوز القياسية.

## 3. عدد الدوال

| المقياس | العدد | المصدر |
|---|---:|---|
| كل الدوال في مخزون Ghidra | **2426** | `rea analyze` (`procedure_count`) |
| دوال خارجية (مستوردة) | 497 | `rea decompile-all` (`external`) |
| **دوال داخل البرنامج نفسه** | **1929** | `rea decompile-all`: فُكّكت 1927، وفشل تفكيك 2 |
| النصوص التي عثر عليها Ghidra | 1970 | `rea analyze` (`string_count`) |

**حدود هذه الأرقام:**
- REA يصف التغطية بأنها `discovery_coverage: unknown`، أي أن هذا ما وجده Ghidra، وقد توجد دوال لم يكتشفها.
- الدوال المستوردة 506 في جدول الاستيراد و497 في Ghidra، والفرق 9. على الأرجح لأن بعض البنود متغيرات بيانات لا دوال، مثل `std::string::npos` و `_Nullstr` و `_acmdln` و `_commode` و `_fmode`.
- **معظم الدوال الداخلية تنتمي إلى محرك Scintilla المدمج** في الملف، لا إلى كود Notepad2 نفسه. الدليل: أصناف `ScintillaWin` و `ScintillaBase`، وتسجيل الصنفين `Scintilla` و `CallTip` في `FUN_14006d6d4`، و `ListBoxX` في `FUN_140068cc0`.

## 4. أهم الدوال ووظيفة كل منها

الملف بلا رموز، فالأسماء العربية أدناه استنتجتها من الدوال المستوردة التي تستدعيها كل دالة ومن النصوص التي تستعملها،
ثم من قراءة الكود المفكّك. العناوين هي عناوين Ghidra.

| العنوان | الوظيفة المستنتجة | الدليل |
|---|---|---|
| `0x140092eb8` | **WinMain**: نقطة البداية | يحفظ `hInstance`، ويرفض ويندوز الأقدم من 2000 برسالة، ويقرأ الإعدادات، ثم يستدعي `OleInitialize` و `InitCommonControlsEx` وينشئ النافذة، وفيه حلقة `GetMessageW` و `TranslateAcceleratorW` |
| `0x140092e3c` | تسجيل صنف النافذة الرئيسية | `RegisterClassW` باسم `Notepad2`، والقائمة من المورد `0x64`، و `lpfnWndProc = FUN_140091fe0` |
| `0x140091fe0` | **إجراء النافذة الرئيسية** (MainWndProc) | يوزّع الرسائل (491 سطرا)، ويستدعي `SendMessageW` إلى Scintilla 24 مرة، ويعالج إفلات الملفات `DragQueryFileW` والقوائم المنبثقة `TrackPopupMenuEx` |
| `0x14006d6d4` | تسجيل محرك Scintilla | `RegisterClassExW` للصنفين `Scintilla` و `CallTip` |
| `0x140083db8` | إنشاء شريط الأدوات وشريط الحالة | `ToolbarWindow32` و `ReBarWindow32` و `CreateStatusWindowW` و `LoadImageW` |
| `0x14007f724` | **قراءة الملف وفك ترميزه** (فتح) | `CreateFileW` و `GetFileSize` و `ReadFile` و `MultiByteToWideChar`، ورسالة التحذير `MsgFileSizeWarning` للملفات الكبيرة |
| `0x140073ecc` | كشف UTF-16 | `IsTextUnicode`، وتستدعيها دالة القراءة |
| `0x14007fff8` | **كتابة الملف** (حفظ) | `CreateFileW` و `WriteFile` و `SetEndOfFile` و `WideCharToMultiByte`، والرسالة `MsgConv3` عند فقد أحرف في التحويل |
| `0x140087fd4` | مربع حوار "فتح" | `GetOpenFileNameW` مع معالجة المسار (`PathCanonicalizeW` و `ExpandEnvironmentStringsW`) |
| `0x140088204` | مربع حوار "حفظ باسم" | `GetSaveFileNameW` بالبنية نفسها |
| `0x140098d3c` | الطباعة | `StartDocW` و `GetDeviceCaps` و `ExtTextOutW`، ورسم الترويسة والتذييل بخط `Arial` |
| `0x140099ee4` | إعداد الصفحة | `PageSetupDlgW` |
| `0x140085410` | تحميل الإعدادات من `Notepad2.ini` | `GetPrivateProfileSectionW`، والمفاتيح `AlwaysOnTop` و `AutoCloseTags` وموضع النافذة |
| `0x14008a898` | حفظ الإعدادات | `WritePrivateProfileStringW` و `GetWindowPlacement`، والمفاتيح `SaveSettings` و `%ix%i PosX`… |
| `0x140086fa4` | قراءة الخيارات المتقدمة (`Settings2`) | `MultiFileArg` و `PortableMyDocs` و `RelativeFileMRU` |
| `0x140087700` | إنشاء ملف ini إن لم يكن موجودا | `SHCreateDirectoryExW` و `CreateFileW` و `WriteFile` |
| `0x140093204` | تحميل أنظمة تلوين الصيغ (Styles) | `GetPrivateProfileSectionW`، والمفاتيح `Styles` و `DefaultScheme` و `FileNameExtensions` |
| `0x14009380c` و `0x140093a14` | استيراد إعدادات التلوين وتصديرها | `GetOpenFileNameW` و `GetSaveFileNameW` على ملفات `.ini` |
| `0x14006e9f0` | مربع حوار "تشغيل" (Run) | `ShellExecuteExW` و `SHAutoComplete` |
| `0x140069618` | دعم محرر طرق الإدخال (IME) في Scintilla | `ImmGetCompositionStringW` و `GetKeyboardLayout` |

## 5. ما يفيد Arabic Editor من هذا التحليل

- نحتاج نصف هذه المكتبات تقريبا: USER32 و KERNEL32 و GDI32 و COMDLG32، وربما COMCTL32 لشريط الحالة.
  Notepad2 يجرّ معه Scintilla و C++ و OLE، ولا حاجة لنا بأي منها، فعنصر `EDIT` القياسي يكفي لمحرر بسيط.
- **الفتح والحفظ:** نسلك ترتيب الدالتين `0x14007f724` و `0x14007fff8`: نقرأ الملف كاملا، ثم نكشف الترميز (BOM أو `IsTextUnicode` أو UTF-8)، ثم نحوّله بـ `MultiByteToWideChar`. وعند الحفظ نحذّر إن فُقدت أحرف في التحويل.
- **الخط:** نستعمل `ChooseFontW` و `CreateFontIndirectW`.
- **البحث والاستبدال:** Notepad2 يرسم مربعاته بنفسه، أما نحن فنستعمل `FindTextW` و `ReplaceTextW` القياسيتين لأنهما أبسط.
