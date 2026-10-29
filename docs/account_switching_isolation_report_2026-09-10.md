# Account Switching & User-State Isolation Report

التاريخ: 2026-09-10. المشروع: Blockatie Client App وواجهات PHP المرتبطة به.

الحالة: **READY FOR MANUAL QA** — التنفيذ والتحقق الآلي جاهزان، والفحص اليدوي بين الحسابين لم يكتمل بعد. لا يُعد هذا التقرير إثباتًا لسلامة جميع حالات الإنتاج.

## 1. Root Cause

السبب الموثق في الكود هو بقاء Providers الخاصة بالعميل داخل شجرة التطبيق الرئيسية عبر تسجيل الخروج والدخول، مع عدم وجود حد موحد يمسح حالتها. تغيير مفتاح الدخول وحده لم يكن يمسح الملف الشخصي والقوائم والأرصدة المخزنة في الذاكرة.

وجد أيضًا كاش إحصاءات ساكن لمدة خمس دقائق غير معزول حسب الجلسة، وطلبات قديمة يمكن أن تعود بعد الانتقال لحساب جديد وتعيد ملء الحالة. هذا يفسر ظهور بيانات A مؤقتًا ثم استبدالها ببيانات B عند التحديث اليدوي.

كشف الفحص اليدوي مشكلة إضافية في زر الخروج داخل «حسابي»: كان ينتظر إلغاء اشتراكات Firebase قبل مسح الجلسة. بقي الحساب ظاهرًا بعد التأكيد. عُدل هذا المسار لاستخدام الخروج المركزي دون انتظار Firebase، مع إكمال التنقل حتى لو أزال reset صفحة الحساب نفسها. أعيد الاختبار على المحاكي ونجح الوصول لشاشة الدخول.

هذه نتائج فحص الكود والتجربة، وليست اتهامًا بأن كل API كان يعيد بيانات حساب خاطئ.

## 2. Providers Affected

«رئيسي» يعني أن نسخة Provider تستطيع البقاء عبر تغيير الشاشات والخروج؛ «مسار» يعني أنها مرتبطة بصفحة، لكن الطلبات المتأخرة تحتاج حماية حتى بعد إغلاق الصفحة.

كل UserScopedNotifier أدناه يملك clearUserState، وإبطالًا للطلبات المتأخرة برقم جيل، وحماية notifyListeners بعد dispose. LoginProvider يشارك في سجل التنظيف بعقد خاص لأن نجاح الدخول نفسه يغير الجيل.

| Provider | العمر | الحالة التي تُصفّر | طلبات / صفحات / تحميل وأخطاء | مؤقتات وتنظيف إضافي |
|---|---|---|---|---|
| ProfileProvider | رئيسي | الملف والمتجر والصورة والهاتف والعنوان والإحصاءات وحقول التحرير | طلبات الملف والإحصاءات وتحديثاتها؛ تفريغ أخطاء ورايات التحميل والطلب المشترك | لا polling مملوك؛ التخلص من controllers |
| StoreStatisticsProvider | رئيسي | الإحصاءات المخزنة | طلب ورايات تحميل وخطأ | تنظيف الكاش الساكن أيضًا |
| ShipmentProvider | رئيسي | الشحنات والعدادات والبحث والفلاتر وآخر استجابة | طلبات، صفحات، تحميل وأخطاء | لا مؤقت مملوك |
| ShipmentInstantprovider | رئيسي | القوائم والفلاتر ومعرفات العمليات المشغولة | طلبات، صفحات، تحميل وأخطاء | لا مؤقت مملوك |
| FilterProvider | رئيسي | اختيارات وحقول الفلاتر وشحناتها وبيانات السائق المرتبطة | طلبات ونتائج وأخطاء/تحميل | dispose للـcontrollers؛ إبقاء بيانات الحالات العامة |
| OrderDetailsProvider | مسار | الشحنة المختارة والتفاصيل والخط الزمني | طلبات تفاصيل، تحميل وأخطاء | حماية بعد dispose |
| RequestsProvider | رئيسي | طلبات السحب | طلبات، صفحات، تحميل وأخطاء | لا مؤقت مملوك |
| WithdrawalProvider | رئيسي | المبلغ والنموذج والطريقة والموافقات والنتيجة | طلب سحب ورايات تحميل/خطأ | إبقاء تفضيل إخفاء الرصيد |
| BalanceHistoryProvider | رئيسي | السجل المالي والفلاتر والنتيجة | طلبات، صفحات، تحميل وأخطاء | إزالة طباعة أخطاء خام |
| ClientStatementsProvider | رئيسي | الكشوف والملخص والفلاتر | طلبات، صفحات، تحميل وأخطاء | لا مؤقت مملوك |
| ClientStatementDetailsProvider | مسار | تفاصيل الكشف وبنوده وحالة PDF | طلبات، صفحات، تحميل وأخطاء | حماية ملفات PDF من الجلسة القديمة |
| NotificationProvider | رئيسي | الإشعارات وعدّاد غير المقروء ومعرفات القراءة | طلبات، صفحات، تحميل وأخطاء | تصفير الشارة |
| FirebaseNotificationProvider | رئيسي | الإشعارات والتوكن المحلي وحالة التحميل | عمليات Firebase محمية بجيل | لا تدمير لتهيئة Firebase العامة |
| ChatConversationsProvider | رئيسي | المحادثات وغير المقروء والمؤشرات | طلبات وCancelToken، cursors، تحميل وأخطاء | إعادة استخدام الإلغاء والتنظيف الموجودين |
| ChatConversationProvider | مسار | الرسائل والمسودة التشغيلية ومؤشرات القراءة والإرسال | طلبات وCancelToken، cursors، تحميل وأخطاء | إلغاء التحميل/الإرسال/القراءة حيث تدعم الخدمة |
| ChatLauncherProvider | رئيسي | أهلية عرض الدردشة وحالة مسارها | قراءة جلسة محمية | منع استمرار واجهة المستخدم السابق |
| AddShipmentProvider | رئيسي | نموذج الإضافة ونتيجة الشحنة وراياته | طلب إضافة ورايات تحميل/خطأ | إبقاء أنواع المنتجات العامة |
| OrderStatusProvider | رئيسي | الاختيار الحالي والحالة الفرعية | اختيار/تحميل بيانات الحالات | إبقاء lookup الحالات العام |
| BottomNavProvider | رئيسي | التبويب والصفحة المعروضة فوقه | لا طلبات أو pagination | إزالة overlay |
| Headerprovider | رئيسي | القائمة/الطبقة العائمة | لا طلبات أو pagination | إزالة OverlayEntry والتخلص منه |
| TimeProvider | رئيسي | وقت الشحنة وحقل إدخاله | لا طلبات أو pagination | التخلص من controller |
| WalletProvider | رئيسي | اختيار تبويب المحفظة | الرصيد الفعلي في ProfileProvider | لا مؤقت مملوك |
| HomeProvider | رئيسي | اختيار تبويب المستخدم | لا كاش مالي خاص به | إبقاء مراقبة اتصال الإنترنت العامة |
| LoginProvider | رئيسي | معرف الدخول وكلمة المرور و«تذكرني» | طلب دخول محمي بجيل، منع التكرار وnotify بعد dispose | لا تنظيف يمحو A عند فشل مصادقة B |

InAppNotificationService ليس Provider مسجلًا بالطريقة نفسها، لكنه أصبح UserScopedNotifier لتنظيف معرفات المعالجة وحالة الفحص؛ يتم التخلص منه مع مالك الصفحة.

لم تُصفّر اللغة وSystemSettings والجداول العامة للمناطق وأنواع المنتجات والتوصيل لمجرد تسجيل الخروج.

## 3. Reset Strategy

UserSessionState هو نقطة الفصل المركزية. يرفع generation أولًا، ثم ينفذ callbacks التنظيف المتزامنة لكل الحالة الخاصة بالمستخدم، ثم ينشر حدث التغيير. لا يوجد تأخير اصطناعي ولا إعادة تشغيل للتطبيق ولا إعادة إنشاء شجرة Providers بأكملها.

تستخدم العمليات غير المتزامنة generation الذي بدأت به. SessionChanged يمنع تطبيق نجاح أو خطأ قديم على الحالة الحالية. تسجل الصفحات والخدمات المالكة للتنظيف نفسها وتلغي التسجيل عند dispose.

يحدث reset عند الخروج، وعند نشر جلسة جديدة بعد نجاح المصادقة والتخزين، وعند تأكيد عدم صلاحية الجلسة الحالية.

## 4. Logout Flow

1. إبطال نسخة الجلسة في الذاكرة فورًا.
2. رفع الجيل ومسح الحالة الخاصة وإيقاف polling الخاص بالدردشة وإزالة overlays.
3. محو المفتاح ومعرف العميل وبيانات remember me وربط FCM المحلي عبر طابور تخزين متسلسل.
4. طلب إبطال الجلسة/رمز التذكر على الخادم وفق العقد الموجود، بأفضل جهد ومهلة محدودة، بعد المسح المحلي.
5. الانتقال إلى الدخول وإزالة واجهة الحساب السابقة.

تنظيف Firebase غير متزامن ولا يسبق المسح المحلي. فشل قراءة معلومات الإبطال لا يمنع محاولة إزالة الاعتماد المحلي. يبقى معرف الجهاز واللغة وتفضيلات التطبيق العامة.

عُدل أيضًا زر الخروج في ProfilePage، وليس الـbottom sheet وحده. لا يعتمد تنقله النهائي على بقاء overlay mounted، ولا ينقل المستخدم بعيدًا إذا أصبحت هناك جلسة جديدة صالحة أثناء اكتمال خروج قديم.

## 5. Login Flow

تتم مصادقة B أولًا مع الاحتفاظ بجلسة A إن فشلت المصادقة. تحفظ بيانات B في secure storage داخل عملية متسلسلة، مع التحقق من الكتابة ومحاولة استعادة القيم السابقة إذا فشل commit.

قبل نشر جلسة B في الذاكرة تُمسح حالة A ويُرفع الجيل. ينتظر مسار الدخول تحميل الملف الشخصي والإحصاءات الأساسية قبل إظهار الواجهة المسجلة. لا يُستخدم اسم أو رصيد A كعنصر تحميل مؤقت.

حُميت الاستعادة وremember me من انتهاء عملية قديمة بعد دخول أحدث. لم ينقل API key إلى SharedPreferences.

## 6. Async Race Protection

- حماية على مستوى Provider تشمل النجاح والخطأ وfinally، كي لا يطفئ رد A مؤشر تحميل B أو يضع خطأه داخل B.
- Session-aware Dio يربط الطلب بالجيل ومفتاح الجلسة ويتجاهل الردود القديمة.
- مسارات OrderServices التي تستخدم HTTP محمية أيضًا، وليست الحماية مقتصرة على Dio.
- 401 يؤثر فقط على الجلسة الحالية المطابقة؛ 401 قديم لا يسجل خروج B.
- timeout و5xx و403 لا تمحو الجلسة تلقائيًا.
- إلغاء الطلبات المستخدمة في الدردشة مع الإبقاء على generation guard حتى لو تجاهل النقل الإلغاء.
- طابور التخزين يمنع تنظيف A المتأخر من حذف مفتاح B.
- حماية ProfilePage من تطبيق تحميل قديم، وإزالة نسخة client ID المحلية المنفصلة لصالح هوية الجلسة الحالية.

## 7. Chat Cleanup

تُفرغ المحادثات والرسائل ومؤشرات pagination والعدادات وأخطاء/حالات التحميل والإرسال. تتوقف دورة polling الخاصة بصفحة المحادثة فور تغيير الجلسة ولا يمكن لرد قديم إعادة تشغيلها. تُمسح مسودة المحادثة المفتوحة.

لم تُحذف رسائل من الخادم، ولم يُضف تخزين دائم محلي للرسائل. لم يُغيّر تردد polling الموجود.

## 8. Wallet Cleanup

تُمسح إحصاءات الرصيد والمتاح والمستحق والمطلوب والمحجوز، وطلبات السحب وتاريخها وملخصات الكشوف وبنودها واختياراتها. لا يُعاد احتساب المعادلة المالية ضمن إصلاح العزل.

تم تنظيف كاش الإحصاءات وحمايته عند انتظار التقييم أيضًا. حُفظ كاش idempotency الخاص بمحاولة السحب لأنه مفصول بمعرف العميل ويمنع تكرار السحب بعد انقطاع الاتصال؛ لا يُستخدم لعرض رصيد مستخدم سابق.

ملفات PDF المؤقتة التي ينشئها المسار المعدل لها أسماء مرتبطة بالجيل، مع رفض الاستجابات المتأخرة ومحاولة حذف الملفات المتتبعة عند الانتقال. لا يضمن ذلك إغلاق قارئ PDF خارجي أو إزالة كل ملف قديم أُنشئ قبل هذه النسخة.

## 9. Shipment Cleanup

تُصفّر القوائم العادية والفورية والعدادات والاختيارات والفلاتر والصفحات وتفاصيل الشحنة وبيانات السائق المرتبطة بها. تُرفض النتائج القادمة من جلسة سابقة، وتبقى lookup البيانات العامة.

## 10. Notification Cleanup

تُفرغ قوائم الإشعارات وغير المقروء وحالة الإشعارات داخل التطبيق ومعرفات منع التكرار. تنظيف Firebase مسجل مرة واحدة، وتهيئته/listeners العامة لا تُهدم ولا تُكرر بسبب التبديل.

تسلسل عمليات messaging يمنع خلط إعداد الحساب السابق بإعداد الجديد. توجد محاولة إلغاء topics القديمة وتدوير FCM token ومسح الإشعارات المحلية والشارة.

لا يُعرض محتوى خاص أو deep link لإشعار بلا مستلم يطابق الحساب الحالي؛ إشعارات النظام القديمة التي لا تحدد المستلم تعرض تنبيهًا عامًا. فحص وصول إشعارات الخلفية عبر نظام التشغيل على جهاز حقيقي ما زال مطلوبًا.

## 11. Profile / Store Cleanup

تُمسح معلومات العميل والمتجر والصورة والهاتف والعنوان والحالة والإحصاءات وحقول التحرير وكلمات المرور المؤقتة. خلال تحميل B تظهر حالة تحميل أو قيمة فارغة آمنة بدل القيم القديمة.

ProfilePage لا يحتفظ بنسخة مستقلة متقادمة من client ID، ولا يطبق نتيجة تحميل إذا تغير جيل الحساب.

## 12. Backend APIs Reviewed

النتائج التالية تخص قراءة النسخة المحلية، وليست اختبار اختراق أو تحققًا من النشر/CDN أو طلبات ملكية متعارضة على قاعدة الإنتاج.

| Endpoint | نتيجة مراجعة هوية/ملكية العميل | تعديل في هذا العمل |
|---|---|---|
| client_profile.php | يستخرج الملف بالمفتاح؛ لا يعتمد على client ID قديم؛ استعلام محضّر | لا |
| get_statistics.php | العميل من المفتاح، رفض عدم التطابق، حساب محفظة مرتبط بالمالك | لا |
| api_shipments.php | ربط المفتاح بالعميل وفلترة الشحنات بمالك المتجر | لا |
| api_shipments_instant.php | تحقق الهوية وعدم تطابق client ID وفلتر المالك | لا |
| api_order_details.php | تفاصيل الطلب مقيدة بالطلب ومالك المتجر | لا |
| api_requests.php | الطلبات مقيدة بالعميل المصادق عليه | لا |
| api_add_withdrawal_request.php | العميل الفعّال من المفتاح؛ رفض عدم التطابق؛ خدمة المحفظة وidempotency | لا |
| api_client_financial_summary.php | مصادقة helper مشترك وربط الحساب بالمالك | لا |
| api_client_statements.php | قوائم محضّرة ومقيدة بالعميل | لا |
| api_client_statement_details.php | التحقق من ملكية الكشف | لا |
| api_client_statement_pdf.php | التحقق من ملكية الكشف وعدم التخزين المشترك في المسار المدروس | لا |
| get_notifications.php | recipient role/id يطابقان العميل | لا |
| api_read_notification.php | تحديث القراءة مقيد بمستلم الإشعار | لا |
| api_get_in_app_notifications.php | helper يصادق المفتاح ومعرف العميل ويقيد المستلم | لا |
| api_acknowledge_notification.php | تحقق الهوية ثم مستلم محدد | لا |
| api_client_chat.php وطرق العميل في cls_chat.php | مصادقة client ثم ملكية المحادثة واستعلامات محضّرة | لا |
| api_client_session.php | تحقق المفتاح والحالة؛ عقد الخروج الحالي يدعم إبطال remember token | لا |
| api_update_client_fcm_token.php | كان token واحد قابلًا للبقاء مرتبطًا بعميل سابق؛ أضيف مسح الربط القديم وتحديث المصادق عليه داخل transaction | نعم |
| api_balance_history.php | يُشار إليه من Flutter لكنه غير موجود في ملفات backend المحلية؛ لا يمكن إثبات ملكيته أو عقده | لا، يلزم التحقق من نسخة الخادم |

الحقول الحساسة لا تُضاف للسجلات. لم يُعدل DB schema ولم يُنفذ SQL مباشر على الإنتاج.

ملف PHP المطلوب للنشر لهذا الإصلاح فقط: services/api_update_client_fcm_token.php داخل جذر dashboard الحالي. لا ترفع config أو SQL أو كامل الملفات المتغيرة على أساس هذا التقرير. لم يُنفذ النشر في هذه المهمة.

## 13. Cleanup Performed

أزيل تكرار تنظيف الخروج من المسار المعدل، والكاش غير المعزول، والتعريف القديم المعلق للمحفظة، وبعض طباعة أخطاء/بيانات حساسة في النطاق. أضيف dispose للـcontrollers اللازمة، وحُميت أعمال refresh من طلبات الحساب السابق.

لم تُمس التعديلات السابقة غير المتعلقة بالمهمة، ولم يُستخدم reset/checkout/clean/stash. لم تُنظف تحذيرات UI القديمة بشكل شامل.

## 14. English Notes Added

أضيفت ملاحظات قصيرة عند حدود الأمان، مثل:

- Invalidate late responses before clearing any account data.
- Publish the new identity only after old account data is actually empty.
- Firebase cleanup must never delay local credential and state removal.
- Reset can dispose this overlay; navigation must still finish.

الملاحظات تشرح ترتيب الجلسة والردود المتأخرة، لا الكود الواضح سطرًا بسطر.

## 15. Automated Tests Added

أضيفت 20 حالة اختبار فوق خط الأساس السابق البالغ 74، ضمن ثلاثة ملفات اختبار:

- account_isolation_test.dart: دورة A → خروج → B قبل الردود وبعدها → A؛ مسح النموذج والبيانات والعدادات؛ ردود profile/wallet/shipments/notifications/chat المتأخرة؛ 401 الحالي والقديم؛ الاحتفاظ بالجلسة عند timeout/403/503؛ فشل مصادقة B؛ استعادة متأخرة؛ التخلص من Provider؛ كاش الإحصاءات والتقييم؛ request ID؛ مطابقة مستلم إشعارات push؛ واجهة حساسة فارغة قبل وصول B.
- chat_conversation_page_test.dart: إيقاف polling ومسح مسودة محادثة مفتوحة عند reset.
- profile_logout_test.dart: الخروج دون الاعتماد على تهيئة Firebase، ومسح الحالة قبل اكتمال التخزين البطيء، وبلوغ الدخول من صفحة مستقلة أو بعد التخلص من overlay، وتنفيذ عقد إبطال الجلسة.

تستخدم الاختبارات بيانات مصطنعة وخدمات بديلة، بما فيها نقل يتجاهل الإلغاء عمدًا لإثبات generation guard. لم تُنشأ معاملات مالية فعلية.

## 16. Manual QA Result

الحسابان المختاران بواسطة المستخدم: QA-W260908 وrozdam.

| الخطوة | النتيجة الحالية |
|---|---|
| تثبيت النسخة المصححة على emulator-5554 مع إبقاء البيانات | نجح |
| فتح QA-W260908 | نجح؛ ظهرت هوية حساب QA |
| الرئيسية والمحفظة والشحنات | حمّلت بيانات الحساب في الفحص الأول |
| إشعارات QA ومحادثاته | قائمتان فارغتان؛ لا يمكن منهما إثبات تصفير عداد غير صفري يدويًا |
| الخروج من «حسابي» قبل التصحيح الإضافي | كشف تعليقًا على Firebase مع بقاء واجهة الحساب |
| الخروج بعد التصحيح وإعادة البناء | نجح؛ ظهرت شاشة الدخول والحقول فارغة دون تحديث يدوي أو إعادة تشغيل |
| دخول rozdam وفحص أول ظهور دون تحديث | بانتظار إدخال المستخدم بيانات الدخول |
| العودة من rozdam إلى QA | لم تُنفذ بعد |
| خلفية Firebase / وضع الطيران / قارئ PDF الخارجي / جلسة استعادة باردة لكل حساب | لم تُثبت يدويًا بعد |

استخدمت مهارة computer-use لمراقبة الواجهة وتشغيل المسارات غير المالية. إدخال بيانات الدخول متروك للمستخدم. توقف التحكم مرتين بطلب المستخدم عبر Esc، ثم استؤنف بعد طلبه؛ لم تُعد هذه التوقفات نجاحًا للاختبار.

لم تُرسل رسائل، ولم تُنشأ شحنات أو طلبات سحب أو تُعدّل أرصدة أثناء هذا الفحص. لم تُسجل كلمات مرور أو مفاتيح أو أرصدة حقيقية في التقرير.

## 17. Analyze Result

dart format للملفات المعدلة: مكتمل. آخر تمرير على الملفين الإضافيين: لا تغييرات تنسيق متبقية.

flutter analyze --no-pub: **141 ملاحظة سابقة، دون أخطاء analyzer جديدة**؛ العدد مطابق لخط الأساس. انتهاء analyze غير صفري بسبب الملاحظات الموجودة، وليس تحليلًا خاليًا من كل التحذيرات.

لم تُصلح التحذيرات غير المتعلقة بعزل الحسابات.

## 18. Test Result

flutter test --no-pub: **94/94 ناجحة** بعد آخر تعديل على التطبيق.

اختبارا ProfilePage أُضيفا بعد ظهور الخلل يدويًا؛ النتيجة النهائية لهما 2/2، ثم أعيدت المجموعة كاملة. فشلت محاولات تطوير مبكرة للاختبار بسبب توقيع البديل وتنسيق انتظار التخزين مع ساعة اختبار Flutter، وصُححت قبل إعادة التحقق الناجحة.

php -l services/api_update_client_fcm_token.php: لا أخطاء صياغة. فحص git diff --check في النطاق: ناجح.

لا تعني هذه النتائج أن اختبارات تكامل PHP/FCM على الإنتاج اكتملت.

## 19. APK Build Result

flutter build apk --debug: **نجح** بعد التصحيح الإضافي، وثُبت الملف على المحاكي بنجاح.

- الملف: [app-debug.apk](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/build/app/outputs/flutter-apk/app-debug.apk)
- الحجم: 230,566,504 bytes.
- آخر كتابة UTC: 2026-09-10 08:58:09.
- SHA-256: B0EDE61525040A2A7067023B42C2E51FCF1C0D7C43E62AA226C092DCEE13AC4A.
- معالجة مشكلة Java المحلية اقتصرت على JAVA_TOOL_OPTIONS للعملية الحالية لتحديد مسار socket مؤقت؛ لم تُغير إعدادات Java العامة أو نسخة Flutter.

هذه نسخة debug للاختبار وليست حزمة release منشورة.

## 20. Files Modified

قائمة نطاق هذا الإصلاح: 48 ملف Flutter/اختبار + ملف PHP واحد، إضافة إلى هذا التقرير. بعضها كان معدّلًا مسبقًا؛ القائمة تعني ملفات لُمست لهذا الإصلاح ولا تنسب كامل diff إلى هذه المهمة.

- [lib/provider/profile.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/profile.dart)
- [lib/provider/store_statistics_provider.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/store_statistics_provider.dart)
- [lib/provider/requests_provider.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/requests_provider.dart)
- [lib/provider/withdrawal.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/withdrawal.dart)
- [lib/provider/balance_history.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/balance_history.dart)
- [lib/provider/shipment.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/shipment.dart)
- [lib/provider/shipment_instant.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/shipment_instant.dart)
- [lib/provider/notification.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/notification.dart)
- [lib/provider/notification_provider.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/notification_provider.dart)
- [lib/provider/statements/client_statements_provider.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/statements/client_statements_provider.dart)
- [lib/provider/statements/client_statement_details_provider.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/statements/client_statement_details_provider.dart)
- [lib/provider/order_details.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/order_details.dart)
- [lib/provider/filter.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/filter.dart)
- [lib/provider/add_shipment_provider.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/add_shipment_provider.dart)
- [lib/provider/bottom_nav.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/bottom_nav.dart)
- [lib/provider/header.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/header.dart)
- [lib/provider/time.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/time.dart)
- [lib/provider/wallet.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/wallet.dart)
- [lib/provider/home.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/home.dart)
- [lib/services/user_session_state.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/user_session_state.dart)
- [lib/provider/chat/chat_conversations_provider.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/chat/chat_conversations_provider.dart)
- [lib/provider/chat/chat_conversation_provider.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/chat/chat_conversation_provider.dart)
- [lib/provider/chat/chat_launcher_provider.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/chat/chat_launcher_provider.dart)
- [lib/services/auth_services.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/auth_services.dart)
- [lib/services/store_statistics_service.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/store_statistics_service.dart)
- [lib/services/requests_service.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/requests_service.dart)
- [lib/services/withdrawal_service.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/withdrawal_service.dart)
- [lib/services/client_statement_service.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/client_statement_service.dart)
- [lib/services/chat_service.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/chat_service.dart)
- [lib/services/shipment_services.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/shipment_services.dart)
- [lib/services/client_rating_service.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/client_rating_service.dart)
- [lib/services/client_fcm_token_service.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/client_fcm_token_service.dart)
- [lib/services/request_id_service.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/request_id_service.dart)
- [lib/services/session_dio.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/session_dio.dart)
- [lib/provider/login.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/login.dart)
- [lib/main.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/main.dart)
- [lib/views/pages/chat/conversation_page.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/views/pages/chat/conversation_page.dart)
- [lib/views/bottmsheets/logout_sheet.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/views/bottmsheets/logout_sheet.dart)
- [lib/views/pages/auth/login/login.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/views/pages/auth/login/login.dart)
- [lib/provider/orders.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/orders.dart)
- [lib/services/in_app_notification_service.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/in_app_notification_service.dart)
- [lib/views/pages/home/home.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/views/pages/home/home.dart)
- [lib/services/firebase_service.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/firebase_service.dart)
- [test/services/account_isolation_test.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/test/services/account_isolation_test.dart)
- [test/widgets/chat_conversation_page_test.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/test/widgets/chat_conversation_page_test.dart)
- [lib/services/order_services.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/order_services.dart)
- [lib/views/pages/hub/profile/profile.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/views/pages/hub/profile/profile.dart)
- [test/widgets/profile_logout_test.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/test/widgets/profile_logout_test.dart)
- [services/api_update_client_fcm_token.php](C:/xampp/htdocs/htdocs/dashboard1/services/api_update_client_fcm_token.php)
- [هذا التقرير](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/docs/account_switching_isolation_report_2026-09-10.md)

شُغّل git diff --name-only وgit diff --stat في المستودعين. لقطة diff الإجمالية للتطبيق: 81 ملفًا متتبعًا، 7360 إضافة و4291 حذفًا. ولقطة backend قبل تنسيق PHP الأخير: 129 ملفًا، 9460 إضافة و4414 حذفًا. هذه الأعداد تشمل تعديلات المستخدم السابقة ولا تشمل جميع الملفات الجديدة غير المتتبعة؛ ليست حجم تعديل عزل الحسابات وحده، ولا قائمة رفع للسيرفر.

## 21. Remaining Risks

1. يلزم إكمال التبديل الحقيقي A → B → A دون تحديث يدوي. لا يكفي نجاح A أو الاختبارات المصطنعة لإعلان COMPLETE.
2. فحص badge غير صفري ورسائل/إشعارات قديمة يحتاج بيانات حساب مناسبة؛ حساب QA لم يحتوِ على قوائم قابلة لإثبات هذا الجانب يدويًا.
3. معالجة إشعارات الخلفية من نظام التشغيل وتسلسل token/topics تحتاج تجربة فعلية على جهاز؛ تنظيف الشبكة أفضل جهد ولا يمنع النظام من امتلاك إشعار سبق عرضه.
4. تعديلات FCM في PHP لم تُنشر ولم تُختبر بتكامل قاعدة إنتاج أو ضغط متزامن؛ transaction ليس بديلًا عن التحقق التشغيلي.
5. api_balance_history.php غير موجود محليًا؛ يلزم جلب عقده/نسخته من الخادم لمراجعته، لا اختراع بديل.
6. PDF مفتوح في تطبيق خارجي أو ملفات أنشأتها نسخ أقدم خارج التتبع لا يمكن ضمان إغلاقها/إزالتها بهذا التنظيف.
7. أخطاء محو secure storage تبقى حالة جهاز استثنائية؛ مسح الذاكرة لا يثبت أن وسيط تخزين معطّل محا كل الاعتمادات. ينبغي عدم اعتبار التنقل للدخول وحده إثباتًا لمسح القرص.
8. لم تُختبر كل الشاشات جانبيًا على الإنتاج، ولم تُنفذ عمليات حذف حساب أو تعديل شحنات أو سحب حقيقي بغرض regression.
9. توجد تعديلات كثيرة سابقة في المستودعين؛ يلزم نشر محدد ومراجعة diff، لا رفع كل ملفات git المتغيرة دفعة واحدة.

## 22. Final Decision

**READY FOR MANUAL QA**

الإصلاح المركزي جاهز، واختبارات الوحدة/الواجهة والبناء ناجحة، والخروج المصحح مثبت يدويًا. يبقى استكمال حساب rozdam والرجوع إلى QA والتحقق من حالات الإشعارات/الاستعادة قبل تقييم الاكتمال. لم يُنشر أي تعديل على السيرفر الرئيسي في هذه المهمة.

