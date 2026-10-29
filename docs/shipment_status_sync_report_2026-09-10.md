# Shipment Status Sync & Notification Report

تاريخ المراجعة: 2026-09-10. الهدف: **NOB-900725**. تم تعديل الملفات المحلية فقط؛ لم يتم رفعها للسيرفر أو تغيير حالة الشحنة الحقيقية.

## 1. Root Cause

السبب المثبت بالكود متعدد النقاط:

- الداشبورد يرسل `bulk_update_status` إلى `classes/controllerShipments.php`. الدالة `bulkUpdateStatus()` كانت تحفظ `tbl_shipments.shipment_status_id` وسجل `tbl_shipment_history` ثم ترجع نجاحًا دون إشعار قاعدة بيانات أو FCM.
- صفحة تفاصيل العميل تستخدم أيضًا مسارًا قديمًا: `controllerDetailsClient.php / updateBulkStatus`، بلا إشعار، وبلا حارس جلسة/صلاحية في هذا الفرع.
- Flutter كان يستمع لأسماء أحداث أخرى، لكن ليس `shipment_status_updated` في التفاصيل. التنقل من FCM للشحنة كان مجرد رسائل debug.
- التحديث العام كان يعيد تحميل معظم Providers، ويسقط بعض الإشارات أثناء التحميل أو فترة التهدئة. التحميل اليدوي ينجح لأنه يعيد قراءة الحالة الصحيحة من PHP.

## 2. Existing Driver Assignment Flow

`DataOperation::editDrivername()` في `classes/cls_func.php` يغيّر السائق، ويكتب history وإشعارًا عبر `Notification::create()`، ويشتق `store_id` من الشحنة. يرسل إلى العميل topic باسم `owner_<storeId>` مع type=`driver_assigned` و`shipment_id` و`policy_num` وURL. توجد كذلك إشعارات إنشاء/إسناد في `ControllerShipments`.

لهذا كان إشعار الإسناد يصل، بعكس تغيير الحالة الجماعي. استخدمت جداول الإشعارات وFirebaseService الموجودين؛ لم أنشئ نظام إشعارات بديلًا. رسائل الإسناد القديمة بلا هوية مستلم تبقى إشعارات عامة لا يُسمح لها بفتح هدف خاص اعتمادًا على payload غير محدد المالك.

## 3. Dashboard Status Update Flow

المسار الحالي:

`controllerBulkShipmentStatus.js → POST controllerShipments.php → bulk_update_status → bulkUpdateStatus()`

يتم التحقق من جلسة إدارية ذات ID، ومصدر الطلب Origin/Referer، وصلاحية الموظف `update_shipment_status`، والحالة، وحد 100 شحنة، والأهلية الحالية. يتم قفل الصفوف `FOR UPDATE`، تحديث الحالة و`updated_at`، كتابة history ومزامنة المخزون القائمة، ثم commit.

المسار القديم `controllerDetailsClient.php / updateBulkStatus` أصبح يمر عبر نفس المسار المحمي. لذلك أصبحت شروط الأهلية والحد الجماعي متطابقة؛ قد ترفض صفحة العميل شحنات كانت تقبلها سابقًا دون هذه الضوابط.

## 4. Backend Fixes

- جمع history IDs للتغييرات الفعلية فقط؛ إعادة طلب نفس الحالة لا تضيف سجلًا أو إشعارًا جديدًا.
- بعد commit، يقوم `shipmentStatusNotify()` بحفظ إشعار ومستلم في الجداول القائمة ضمن معاملة منفصلة، ثم محاولة FCM.
- حدث الحالة يرتبط بالسجل المحفوظ نفسه؛ تغير الحالة مرة أخرى بسرعة لا يبدّل اسم الحالة المرتبطة بالحدث السابق.
- إشعار العميل مشتق من `tbl_shipments.store_id → tbl_clients.id` وحسابه النشط وFCM token المخزن، وليس مدخلات المتصفح.
- مسار السائق `services/update_shipment_status.php` أصبح يستخدم العقد نفسه بعد commit بدل `status_update` القديم وإرسال topic.
- فشل الإشعار أو FCM لا يدخل مسار rollback الخاص بتغيير الشحنة. رسائل تشغيل عامة فقط دون SQL أو tokens.
- لا migration جديدة ولا تنفيذ SQL على قاعدة إنتاج.

## 5. FCM Event Contract

كل قيم data نصوص، مثل:

```json
{
  "type": "shipment_status_updated",
  "shipment_id": "<internal shipment ID>",
  "shipment_number": "NOB-900725",
  "status_id": "<new status ID>",
  "event_id": "shipment-history:<committed history ID>",
  "recipient_type": "client",
  "recipient_role": "client",
  "client_id": "<owner resolved from DB>"
}
```

عنوان ونص push عامان؛ لا أسماء مستلمين أو أرقام هواتف أو عنوان توصيل أو مبالغ. النص التفصيلي العربي/الإنجليزي محفوظ في مركز الإشعارات ويستخدم أسماء الحالات من `tbl_order_status`.

`event_id` ثابت لكل history. لا يوجد ادعاء exactly-once عبر انهيار الخادم؛ انظر المخاطر.

## 6. Client Foreground Sync

`FirebaseService` يتحقق من هوية المستلم ثم ينشر إشارة عبر `ShipmentSync`. يتم تجاهل التكرار ضمن نافذة 15 دقيقة وبحد ذاكرة 256 حدثًا لكل جلسة. الإشعارات المكررة لا تولّد تحديثات أو إشعارات محلية متكررة.

`ShipmentRefreshCoordinator` يجمع الأحداث المتقاربة خلال 300ms. لا يحدث تنقل تلقائي في foreground؛ الحالة لا تُطبّق من FCM بل تُجلب من API.

## 7. Client Resume Sync

عند resumed: تحديث قائمة الشحنات المناسبة إذا كانت ظاهرة، وعدادات العميل ومركز الإشعارات؛ التفاصيل الظاهرة لها تحديث مستقل. لا إعادة تحميل لكل Providers.

عند الضغط على push، يتم فتح التفاصيل باستخدام ID فقط وطلب API محمي. أضيف انتظار جاهزية الواجهة المصادق عليها للرسالة الأولية بعد تشغيل التطبيق. اختبار الضغط من نظام التشغيل وcold start الحقيقي ما زال ضمن QA اليدوي.

FCM ليس ضمانًا لوصول كل رسالة في كل حالة تشغيل؛ المرجع الرسمي: [استقبال الرسائل في Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages).

## 8. Shipment List Sync

تم اختيار silent list refresh لأن API الحالي يرجع قائمة، ولا يوجد endpoint مخصص آمن لتحديث بطاقة واحدة ضمن القائمة.

القائمة العادية تحتفظ بالبحث والصفحة وتضبط رقم الصفحة عند تقلص النتائج. قائمة الفوري لم تعد تصفّر الصفحة أثناء التحديث. يتم استبدال snapshot بدل إضافة عناصر مكررة. عند العودة للشحنات/الرئيسية أو إغلاق overlay يُجدول تحديث جديد؛ تُحدّث القائمة غير الظاهرة عند العودة إليها.

## 9. Shipment Details Sync

`OrderDetailsProvider` يستبدل بيانات الحالة والسائق والتفاصيل وtimeline باستجابة API كاملة. تحديث صامت عندما توجد بيانات، وطلب جديد عند إعادة فتح الشاشة.

يوجد رفض لاستجابة تحمل orderId مختلفًا، ولرد متأخر من حساب سابق، ولرد شحنة سابقة أثناء فتح شحنة أخرى. الإشارة لشحنة B لا تغيّر تفاصيل A. رفض الملكية/فشل التحميل يزيل تفاصيل غير مؤكدة بدل عرضها كبيانات حالية.

لم أضف polling للشحنات: FCM + resume + re-entry هو الخيار الحالي. لا timers دورية 1–5 ثوانٍ أو 10–15 ثانية.

## 10. Timeline Sync

المصدر الموجود في `api_order_details.php` هو history، مرتّب بـ`update_date ASC, history_id ASC`، ويستبعد سجلات عدم تغير الحالة. الأسماء والرسائل العربية والإنجليزية من جدول الحالات؛ لا خطوات مصطنعة من Flutter.

التحديث يستبدل timeline كاملة ولا يضيف خطوة من push. اختيار رسالة الحالة من timeline يستخدم أحدث تطابق عند تكرر حالة مشروعة. اختبارات النموذج والتحديث نجحت؛ مطابقة توقيت السجل على سيرفر الإنتاج مع شاشة NOB-900725 لم تُجرَ بعد.

## 11. Notification Center Sync

إنشاء صف في `notifications` وصف عميل في `notification_recipients`. يتم تحديث القائمة والعدد غير المقروء من الخادم؛ لا زيادة محلية تخمينية لكل حدث حالة.

طلبات التحديث وتحميل الصفحات تتشارك طابورًا: إذا وصل refresh أثناء pagination، ينفذ refresh بعد اكتمال الطلب، وليس صفحة إضافية ولا إسقاطًا للحدث.

الضغط على إشعار الحالة الموجود في المركز يفتح التفاصيل. أضيف فحص جيل الجلسة بعد انتظار تعليم الإشعار كمقروء، لمنع تنقل متعلق بالحساب السابق.

## 12. Account Isolation Protection

تم الحفاظ على `UserSessionState` و`UserScopedNotifier` وحماية الردود المتأخرة. المستمعون الجدد يرفضون جيل جلسة قديم، ويتوقفون عند dispose، وتُلغى مهلة debounce عند reset.

تمت مراجعة `api_update_client_fcm_token.php`: يتحقق من مفتاح الحساب وحالته ويعيد إسناد token داخل معاملة بإزالة الربط من العملاء الآخرين. لم أعدّل هذا الملف في هذه المهمة. لم أضف تسجيل FCM listeners مكررًا أو تهيئة Firebase ثانية.

اختبارات A→B السابقة نجحت. اختبار تبديل حسابين حقيقيين مع push جديد ما زال يدويًا.

## 13. API Security Review

| المسار | نتيجة المراجعة/التعديل |
|---|---|
| api_shipments.php | X-API-KEY؛ اشتقاق العميل من المفتاح ومطابقة clientId؛ prepared statements وتصفية store_id. أضيف شرط الحساب النشط وحارس أخطاء عام. |
| api_order_details.php | اشتقاق المالك من المفتاح وWHERE shipment ID + store ID؛ لا الاعتماد على مالك في payload. أزيل قبول API key من URL/body، وأضيف active account وحارس الأخطاء. |
| get_notifications.php | يطابق client_id مع صاحب المفتاح، ويقيّد recipient_role وrecipient_id؛ prepared statements. أصبح المفتاح من header فقط مع شرط active وحارس أخطاء. |
| api_get_in_app_notifications.php | هوية الحساب النشط من المفتاح؛ يجب تطابق ID المطلوب. أزيل تشغيل schema alterations من endpoint القراءة، خصوصًا قبل المصادقة. |
| api_update_client_fcm_token.php | فُحص ولم يتغير؛ مفتاح مرتبط بالحساب وactive status؛ تحديث token وربطه ضمن معاملة. |
| controllerShipments.php / bulk_update_status | جلسة إدارية عددية وصلاحية موظف ومصدر طلب مطابق للمضيف؛ IDs صحيحة وحد جماعي، prepared statements وقفل صفوف. أخطاء DB عامة. |
| controllerDetailsClient.php / updateBulkStatus | كان فرع الحالة يفتقر للحماية المباشرة؛ أصبح يمر عبر controllerShipments المحمي. باقي عمليات هذا الملف ليست مشمولة بتدقيق شامل. |
| update_shipment_status.php | حُفظ التحقق الحالي من السائق/إسناد الشحنة ومعاملة الحالة وactivity log؛ تغير مسار إشعار العميل بعد commit. |

المراجعة تحليل كود واختبارات معزولة، وليست اختبار اختراق حيًا ولا إثباتًا لجميع endpoints. التحقق من Origin/Referer هنا يطابق hostname؛ ليس تطبيق CSRF tokens شاملًا لكل الداشبورد. العملاء القدامى الذين يرسلون API keys عبر query/body لهذه المسارات يحتاجون تحديثًا إلى header.

## 14. Performance Considerations

استعلام مجمع واحد يجلب مالكي جميع التغييرات وtokens وأسماء الحالات من history؛ لا SELECT منفصل لكل مستلم. الإدخالات المطلوبة لكل إشعار تستخدم statements يعاد استخدامها.

التطبيق يجلب السطح المناسب فقط مع debounce وطابور request coalescing يحتفظ بآخر تحديث أثناء التحميل. لا polling عام.

محاولات push لها ميزانية زمنية تقارب 10 ثوانٍ للدفعة، وتشمل مهلة OAuth/HTTP. عند نفادها تُحفظ إشعارات المركز، لكن بعض pushes قد لا تُرسل ولا يوجد retry worker جديد. هذا حد مقصود لحماية استجابة الداشبورد، وليس ضمان تسليم جماعي.

## 15. Cleanup Performed

أزيل فرع SQL الجماعي المكرر في صفحة العميل واستبدل بتوجيه للمسار الموحد. أزيل إرسال الحالة القديم للسائق وكتابة سجلات FCM التفصيلية في هذا المسار. أزيل مستمع Firebase المباشر من التفاصيل لصالح الإشارة المشتركة، والتحديث العام لكل Providers، وretry غير الفعال في OrderDetailsProvider، واستيراد Nav غير المستخدم.

لم أحذف جداول أو بيانات أو ملفات تشغيل قائمة. لا تنظيف عام للتحذيرات أو الواجهات القديمة. ملفات التشخيص السابقة لم ألمسها؛ يمكن إزالتها لاحقًا من السيرفر بعد انتهاء الحاجة إليها وبقرار منفصل.

## 16. English Notes Added

تعليقات قصيرة توضّح: FCM إشارة لا مصدر بيانات؛ عزل commit عن فشل push؛ ملكية الإشعار من DB؛ عدم توليد timeline من payload؛ coalescing وآخر refresh؛ ومنع تنقل متعلق بجلسة سابقة. لا تعليق على كل سطر.

## 17. Tests Added

16 اختبار Flutter جديدًا في `test/services/shipment_sync_test.dart` يغطي: foreground، تجاهل حدث غير متعلق، dedupe، resume/background، مطابقة تفاصيل A وعدم تغييرها بحدث B، visibility/dispose، إعادة الفتح، حساب سابق ورد متأخر، غياب المالك/logout، trailing refresh، تغيير الهدف أثناء الطلب، استبدال البطاقة والحالة، تحديث timeline، تحديث unread، وصول refresh أثناء pagination، ورفض الملكية.

6 فحوص PHP في `scripts/test_shipment_status_notifications.php`: حقن فشل إرسال ورجوع success=false، وفحص حدود المصدر بعد commit، no-op، اشتقاق المالك، وevent ID الدائم. **فحص عدم rollback يجمع حقن فشل transport وفحص ترتيب/حدود المصدر؛ لم يشغّل معاملة MySQL حقيقية.**

اختبارات توقف polling بعد final status لا تنطبق لأن polling للشحنات لم يُضف. اختبارات عزل الحسابات السابقة ما زالت ضمن التشغيل الكامل.

## 18. Analyze Result

`flutter analyze --no-pub`: **140 ملاحظة، صفر أخطاء**. خط الأساس كان 141 ملاحظة قائمة؛ أزيل استيراد غير مستخدم ضمن نطاق المهمة، ولا ملاحظات جديدة بسبب الميزة. الأمر يرجع exit code 1 بسبب التحذيرات/info القائمة؛ لم ندّعِ أن المشروع خالٍ من التحذيرات.

## 19. Test Result

`flutter test --no-pub`: **110 اختبارات نجحت**. منها 16 اختبارًا جديدًا، مع استمرار نجاح اختبارات الجلسة والمحادثة وتسجيل الخروج السابقة.

`php scripts/test_shipment_status_notifications.php`: **6 فحوص نجحت**، دون اتصال بقاعدة البيانات أو Firebase.

## 20. APK Build Result

`flutter build apk --debug`: **نجح بعد آخر تعديل Dart**، مع JAVA_TOOL_OPTIONS مؤقت للعملية فقط لحل مسار sockets في بيئة Windows الحالية. دون تغيير إعدادات SDK الدائمة. الناتج:

[app-debug.apk](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/build/app/outputs/flutter-apk/app-debug.apk)

لم يُثبت هذا APK الجديد على المحاكي في هذه المهمة، ولم يُنشر كإصدار production.

حجم الملف: 230579911 bytes. وقت البناء UTC: 2026-09-10T11:08:07.8874757Z.

SHA-256: `78F813338A76BA62514FB0DBE6698513BA83CDFC54722E941ECB00BB496095D8`.

## 21. PHP Syntax Result

`php -l` نجح لكل ملفات PHP المعدلة/الجديدة، وعددها **11**، بما فيها سكربت الفحص المحلي. لا أخطاء syntax.

## 22. Files Modified

هذه قائمة المهمة فقط، وليست قائمة كل التغييرات القديمة في Git.

**ملفات السيرفر المطلوبة — 10 ملفات، تُراجع وتُرفع مع الحفاظ على المسارات:**

- [classes/controllerShipments.php](C:/xampp/htdocs/htdocs/dashboard1/classes/controllerShipments.php)
- [classes/controllerDetailsClient.php](C:/xampp/htdocs/htdocs/dashboard1/classes/controllerDetailsClient.php)
- [classes/FirebaseService.php](C:/xampp/htdocs/htdocs/dashboard1/classes/FirebaseService.php)
- [services/update_shipment_status.php](C:/xampp/htdocs/htdocs/dashboard1/services/update_shipment_status.php)
- [services/api_shipments.php](C:/xampp/htdocs/htdocs/dashboard1/services/api_shipments.php)
- [services/api_order_details.php](C:/xampp/htdocs/htdocs/dashboard1/services/api_order_details.php)
- [services/get_notifications.php](C:/xampp/htdocs/htdocs/dashboard1/services/get_notifications.php)
- [services/api_get_in_app_notifications.php](C:/xampp/htdocs/htdocs/dashboard1/services/api_get_in_app_notifications.php)
- [services/helpers/shipment_status_notifications.php](C:/xampp/htdocs/htdocs/dashboard1/services/helpers/shipment_status_notifications.php)
- [services/helpers/shipment_api_errors.php](C:/xampp/htdocs/htdocs/dashboard1/services/helpers/shipment_api_errors.php)

**فحص محلي لا يلزم رفعه:**

[scripts/test_shipment_status_notifications.php](C:/xampp/htdocs/htdocs/dashboard1/scripts/test_shipment_status_notifications.php)

**Flutter والاختبارات — 14 ملفًا:**

- [lib/main.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/main.dart)
- [lib/provider/shipment.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/shipment.dart)
- [lib/provider/shipment_instant.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/shipment_instant.dart)
- [lib/provider/order_details.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/order_details.dart)
- [lib/provider/notification.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/provider/notification.dart)
- [lib/services/firebase_service.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/firebase_service.dart)
- [lib/services/session_refresh_queue.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/session_refresh_queue.dart)
- [lib/services/shipment_sync.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/shipment_sync.dart)
- [lib/services/shipment_refresh_coordinator.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/shipment_refresh_coordinator.dart)
- [lib/services/shipment_details_sync.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/services/shipment_details_sync.dart)
- [lib/views/pages/orders/order_details.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/views/pages/orders/order_details.dart)
- [lib/views/pages/home/home.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/views/pages/home/home.dart)
- [lib/views/pages/notifications/notifications.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/lib/views/pages/notifications/notifications.dart)
- [test/services/shipment_sync_test.dart](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/test/services/shipment_sync_test.dart)

**التوثيق:**

- هذا التقرير.
- [لقطة git diff --name-only وgit diff --stat](C:/xampp/htdocs/htdocs/dashboard1/client_app-main/docs/shipment_sync_git_awareness_2026-09-10.md).

لا ترفع `cls_config.php` أو بيانات الدخول أو SDK أو مجلد المشروع كاملًا لهذا الإصلاح. `FirebaseService.php` المقصود موجود تحت `classes/`، وليس النسخ الأخرى بنفس الاسم. يحتوي العمل الحالي أيضًا تغييرات أقدم؛ قارن مع نسخة الإنتاج واحفظ إعدادات Firebase الخاصة بالسيرفر ومساعداته المطلوبة. لا تبدأ باختبار مباشر قبل اكتمال رفع الملفات التابعة.

إجمالي Git يشمل تغييرات قديمة كثيرة: backend نحو 132 ملفًا متتبعًا، وFlutter 81 ملفًا متتبعًا، ولا يشمل الملفات الجديدة غير المتتبعة. لم يتم reset/checkout/clean/stash أو commit. التفاصيل الكاملة في لقطة Git، وليست نسبًا للتغييرات الخاصة بهذه المهمة.

## 23. Manual QA Result for NOB-900725

**لم يُنفّذ بعد على الإنتاج.** لا يوجد دليل جديد بأن هذه الشحنة حدّثت البطاقة/التفاصيل/timeline أو أظهرت notification دون refresh. لم يتم رفع PHP أو تغيير الحالة أو القفز إلى Delivered.

الخطوات المتبقية:

1. حفظ نسخة السيرفر الحالية ورفع الملفات العشرة المطلوبة مع الحفاظ على إعدادات Firebase وقاعدة البيانات. لا SQL/migration جديدة.
2. تثبيت APK الجديد مع الحفاظ على بيانات التطبيق، والتأكد من الحساب المالك للشحنة ومن تسجيل token الحالي وصلاحية إشعارات Android.
3. فتح NOB-900725 في تفاصيل التطبيق. قراءة الحالة الفعلية في الداشبورد واختيار **الحالة التالية المسموحة تشغيليًا فقط**؛ لا تخمين لرقمها ولا قفز للتسليم.
4. تغيير حالة واحدة، دون لمس refresh داخل التطبيق. التحقق من تغير الحالة وtimeline ووصول الإشعار، ثم الرجوع للقائمة والتحقق من البطاقة.
5. فتح مركز الإشعارات والضغط على الإشعار: يجب فتح نفس الشحنة. تكرار ذلك مع خطوة حالة مسموحة أخرى.
6. وضع التطبيق بالخلفية، ثم تغيير حالة مسموحة، ثم العودة للتطبيق والتأكد من المزامنة. فحص ضغط push وcold start أيضًا.
7. إعادة اختبار A→logout→B والتأكد أن إشعارات/ردود A لا تدخل B.

يجب تسجيل الزمن، الحالة السابقة/الجديدة، ونتيجة كل سطح. إن ظهرت مشكلة لا نغيّر حالات إضافية حتى تُشخّص.

## 24. Remaining Risks

- لا اختبار حي لـFCM وNOB-900725 أو كامل سلسلة MySQL/HTTP؛ الفحوص المحلية لا تعوّضه.
- توجد فجوة انهيار ممكنة بين business commit وحفظ الإشعار. history يبقى محفوظًا، لكن لا outbox/retry worker مضمون لهذه الأحداث.
- انقطاع FCM أو نفاد ميزانية push للدفعة قد يمنع الإشعار الفوري؛ المركز يُحدّث عند resume/re-entry. إذا فُقد الحدث أثناء بقاء الشاشة مفتوحة بلا أي انتقال، لا يوجد polling لتعويضه.
- إرسال push بالخلفية قد يعرض إشعارًا عامًا من النظام؛ بيانات الشحنة لا تُعرض/تُفتح دون تطابق الحساب وAPI ownership.
- قاعدة الإنتاج يجب أن تحتوي جداول وأعمدة مركز الإشعارات القائمة. لم نختبر ترقية قاعدة قديمة، ولم نجعل API القراءة يعدّل schema تلقائيًا.
- توحيد مسار صفحة العميل يشدد الأهلية والمصادقة. يلزم اختبار صلاحيات الموظفين الفعليين وطلبات المصدر بعد النشر.
- توجد مسارات أخرى قد تغير الحالة، مثل الإكمال/الإلغاء المتخصصة؛ لم تُدعَ هذه المراجعة تغطية جميع عمليات الشحن في النظام.
- توجد تحذيرات Flutter سابقة وكود واجهة قديم خارج تغيير المزامنة، ولم ننفذ تنظيفًا شاملًا.

## 25. Final Decision

**READY FOR MANUAL QA**

الكود والفحوص المحلية جاهزة لاختبار مُراقب بعد الرفع. ليست COMPLETE: يلزم إثبات السيناريو الحقيقي لـNOB-900725، وإشعار الحالة والضغط عليه، دون refresh يدوي.
