# خطة: فهم محرر نصوص لويندوز بـ REA وبناء Arabic Editor

## السياق
عندنا الآن `editor.exe`، وهو نافذة Win32 فارغة (`src/main.c`). نريد أن نحوّله إلى محرر نصوص بسيط يدعم العربية.
نعرف السلوك المطلوب بدراسة محرر قائم بأدوات REA. المرجع هو **Notepad من Wine**:
`/usr/lib/x86_64-linux-gnu/wine/x86_64-windows/notepad.exe`، من نوع PE32+ x86-64، ومصدره الحزمة `libwine`.
الملف فيه قسم `.rsrc` يضم القوائم ومربعات الحوار، وفيه أيضا معلومات DWARF، فأسماء الدوال متاحة للتحليل.

**النطاق:** فتح، حفظ (وحفظ باسم)، بحث، استبدال، حجم الخط، التفاف السطور، نافذة "عن البرنامج".
**خارج النطاق:** باقي أوامر الأصلي، ومنها: جديد، طباعة، إعداد الصفحة، التاريخ والوقت، الانتقال إلى سطر، شريط الحالة،
اختيار الترميز، التراجع، القص، النسخ، اللصق، تحديد الكل، البحث عن التالي. نسجّلها في جدول الأوامر ولا ننفّذها.
ملاحظة: التراجع والقص والنسخ واللصق تعمل تلقائيا من قائمة السياق في عنصر EDIT دون أن نكتب لها كودا.

**الأداة:** خادم MCP يحتاج إعادة تشغيل الجلسة ليقرأ `JAVA_HOME` (JDK 25) من `.mcp.json`.
إلى أن يحدث ذلك نستعمل أوامر `rea` في سطر الأوامر مع
`GHIDRA_INSTALL_DIR=/opt/ghidra JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64`، كما فعلنا في `docs/analysis.md`.

## أدوات REA المستعملة
| الأداة | فائدتها هنا |
|---|---|
| `inspect_artifact` | هوية الملف (SHA-256 والصيغة والمعمارية) لتثبيت المرجع |
| `inspect_pe_resources` | VERSIONINFO (الحقوق والإصدار)، والقوائم واختصارات لوحة المفاتيح ومربعات الحوار وجداول النصوص، فمنها نحصل على معرّفات الأوامر |
| `inspect_pe_imports` | دوال Windows API المستوردة، مثل `GetOpenFileNameW` و `FindTextW` و `ChooseFontW` و `ShellAboutW` |
| `inspect_dwarf_units` | ملفات المصدر التي بُني منها الملف، وهي تفيد مراجعة الرخصة وتسهّل التنقل |
| `open_binary` و `binary_overview` | فتح الملف في Ghidra 12.2 وملخص عام عنه |
| `search_procedures` و `list_procedures` | إيجاد دوال كل أمر بالاسم |
| `search_strings` | النصوص، مثل "LGPL" وعناوين مربعات الحوار ورسائل الخطأ |
| `find_xrefs_to_name` و `xrefs` و `procedure_callers` | من يستدعي الدالة المستوردة، وبذلك نصل إلى الدالة المسؤولة عن الأمر |
| `procedure_pseudo_code` و `analyze_function` | قراءة منطق الدالة بعد تفكيكها |
| `get_call_graph` و `trace_feature` | تتبّع مسار الأمر من `WM_COMMAND` إلى التنفيذ |
| `export_evidence_bundle` و `close_binary` | حفظ الأدلة في `docs/evidence/` ثم إغلاق الجلسة |

## المراحل
كل مرحلة تنتهي بـ commit ورفعه إلى الفرع، كما يطلب `CLAUDE.md`.

### المرحلة 0: مراجعة الرخصة
- REA: `inspect_artifact` ثم `inspect_pe_resources` (VERSIONINFO) ثم `search_strings` (`LGPL` و `Copyright`) ثم `inspect_dwarf_units`.
- خارج REA: قراءة `/usr/share/doc/libwine/copyright`، وفيه `Files: * / License: LGPL-2.1+`.
- **القرار المتوقع:** LGPL-2.1+ تسمح بالدراسة والتحليل. نأخذ من الأصلي السلوك والواجهة فقط، ونكتب كودنا بأنفسنا ولا ننسخ منه. بهذا لا يرث كودنا شروط LGPL.
- الناتج: `docs/license-review.md`.

### المرحلة 1: جرد الأصلي
- REA: `open_binary` (ghidra) ثم `binary_overview` ثم `inspect_pe_imports` ثم `inspect_pe_resources` (القوائم والاختصارات).
- الناتج: `docs/commands.md`، وهو جدول بكل أوامر الأصلي فيه المعرّف والاختصار والحالة (داخل النطاق أو خارجه).

### المرحلة 2: تحليل الأوامر السبعة
لكل أمر: نبحث عن الدالة المستوردة المرتبطة به بـ `find_xrefs_to_name`، ثم نجد من يستدعيها بـ `procedure_callers`، ثم نفكّكها بـ `procedure_pseudo_code`، ونكتب ملخصا لسلوكه في `docs/behavior/<أمر>.md`.

| الأمر | نقطة البداية في التحليل |
|---|---|
| فتح | `GetOpenFileNameW` و `CreateFileW` و `ReadFile`، وكيف يكتشف الترميز (BOM و UTF-8) |
| حفظ / حفظ باسم | `GetSaveFileNameW` و `WriteFile`، والتحذير عند إغلاق ملف معدّل |
| بحث | `FindTextW` و `RegisterWindowMessageW(FINDMSGSTRING)` |
| استبدال | `ReplaceTextW`، والفرق بين "استبدال" و"استبدال الكل" |
| حجم الخط | `ChooseFontW` و `CreateFontIndirectW` و `WM_SETFONT` |
| التفاف السطور | إعادة إنشاء عنصر EDIT مع `ES_AUTOHSCROLL` أو `WS_HSCROLL` أو دونهما |
| عن البرنامج | `ShellAboutW` أو مربع حوار من الموارد |

### المرحلة 3: البناء في `src/` (كل أمر في commit مستقل)
1. عنصر EDIT متعدد الأسطر يملأ النافذة، مع دعم RTL للعربية (`WS_EX_RTLREADING` و `WS_EX_RIGHT`)، وقائمة وموارد في `src/resource.rc` و `src/resource.h`.
2. فتح وحفظ بترميز UTF-8، وقراءة UTF-16 إن وُجد في الملف BOM يدل عليه.
3. بحث واستبدال بمربعات الحوار القياسية.
4. حجم الخط بـ `ChooseFontW` أو بأمري تكبير وتصغير.
5. التفاف السطور.
6. نافذة "عن البرنامج".
- نحدّث `build.sh` ليترجم ملف الموارد بـ `x86_64-w64-mingw32-windres` ويربط `comdlg32`.

### المرحلة 4: التحقق
- `./build.sh` يُتم البناء دون تحذيرات.
- `inspect_pe_imports` على `build/editor.exe`: نتأكد أن الدوال المستوردة الجديدة متوقعة (`comdlg32` وغيرها).
- نشغّل البرنامج في Wine على `:99` داخل `explorer /desktop`، ونجرّب كل أمر بفتح ملف عربي وحفظه، ونلتقط صورة لكل مربع حوار في `docs/screenshots/`.
- نقارن الملف المحفوظ بالأصل بالبايت (`cmp`) لنتأكد أن UTF-8 محفوظ سليما.

## الملفات
- جديدة: `plan.md` (نسخة من هذه الخطة في جذر المستودع)، و `docs/license-review.md` و `docs/commands.md` و `docs/behavior/*.md`، و `src/resource.rc` و `src/resource.h`.
- معدّلة: `src/main.c` و `build.sh`.

## الخطوة الأولى بعد الموافقة
كتابة `plan.md` بهذا المحتوى، ثم commit ورفعه. بعدها نبدأ المرحلة 0.
