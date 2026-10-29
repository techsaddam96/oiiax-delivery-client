# Git awareness — Shipment Sync — 2026-09-10

هذه لقطة نهائية لكامل التغييرات غير الملتزمة، وتشمل تغييرات سابقة لا تخص هذه المهمة. لا تستخدمها كقائمة رفع. الملفات الجديدة غير المتتبعة ليست ضمن git diff.

## C:/xampp/htdocs/htdocs/dashboard1

```text
.gitignore
.htaccess
FirebaseService.php
assets/css/floating-chat.css
assets/js/account_statements.js
assets/js/classes/cls_client.js
assets/js/classes/locationadmin.js
assets/js/controller/controllerChat.js
assets/js/controller/controllerClientStoreMap.js
assets/js/controller/controllerDetailsClient.js
assets/js/controller/controllerDetailsDrivers.js
assets/js/controller/controllerFinancialClaims.js
assets/js/controller/controllerFloatingChat.js
assets/js/controller/controllerInstantShipments.js
assets/js/controller/controllerPortalClients.js
assets/js/controller/controllerPortalDrivers.js
assets/js/controller/controllerRouteBatching.js
assets/js/controller/controllerShipmentDeliveryMap.js
assets/js/controller/controllerWebShipments.js
assets/js/controller/dashboardOperations.js
assets/js/controller/login.js
assets/js/controller/shipmentIHomeController.js
chat.php
classes/FirebaseService.php
classes/MailService.php
classes/Notifications.php
classes/cls_chat.php
classes/cls_config.php
classes/cls_db.php
classes/cls_feature_access.php
classes/cls_func.php
classes/cls_pagination_dc.php
classes/cls_permissions.php
classes/cls_pull.php
classes/cls_system_control.php
classes/controllerChat.php
classes/controllerClient.php
classes/controllerDashboardOperations.php
classes/controllerDetailsClient.php
classes/controllerDrivers.php
classes/controllerIHomeController.php
classes/controllerInstantShipments.php
classes/controllerPortalClients.php
classes/controllerPortalRequests.php
classes/controllerShipment.php
classes/controllerShipmentDaily.php
classes/controllerShipments.php
classes/controllerWebShipments.php
classes/export_shipments.php
classes/fcm_service.php
classes/invoices/invoices.php
client_info_add.php
client_info_details.php
client_info_modification.php
clients_portal.php
daily_shipments.php
driver_info_details.php
drivers_portal.php
err/400.php
err/401.php
err/402.php
err/403.php
err/404.php
err/405.php
err/500.php
err/501.php
err/502.php
err/503.php
err/504.php
err/505.php
financial_wallet.php
index.php
instant_shipments.php
lang/ar.php
lang/en.php
lang/lang.php
layout/floating_chat_widget.php
layout/footer.php
layout/head.php
layout/mune.php
layout/path_helpers.php
layout/script.php
layout/web_session_guard.php
libraries/FirebaseService.php
notifications.php
route_batching.php
services/accept_shipment_driver.php
services/api_add_shipment_from_client.php
services/api_add_withdrawal_request.php
services/api_cancel_shipment.php
services/api_client_messages.php
services/api_delivery_types.php
services/api_driver_add_withdrawal_request.php
services/api_driver_login.php
services/api_driver_rating.php
services/api_get_in_app_notifications.php
services/api_order_details.php
services/api_product_type.php
services/api_read_notification.php
services/api_regions.php
services/api_shipment_filter_driver.php
services/api_shipments.php
services/api_shipments_driver.php
services/api_shipments_instant.php
services/api_shipments_instant_driver.php
services/api_update_client_fcm_token.php
services/api_update_driver_info.php
services/check_driver_arrival.php
services/client_login.php
services/client_profile.php
services/complete_shipment_driver.php
services/debug_private_key.php
services/functions.php
services/get_notifications.php
services/get_statistics.php
services/mark_as_arrived_driver.php
services/notification_firebase_api.php
services/register_client.php
services/send_driver_notification.php
services/sendnotification.php
services/shipment_driver_coords.php
services/test_firebase_setup.php
services/test_firebase_simple.php
services/test_notification.php
services/update_client_info.php
services/update_shipment_status.php
setting.php
shipment_info_add.php
shipment_info_details.php
shipment_info_modification.php
shipments.php
sign-in.php
 .gitignore                                         |   14 +
 .htaccess                                          |   17 +-
 FirebaseService.php                                |  160 +--
 assets/css/floating-chat.css                       |  142 ++-
 assets/js/account_statements.js                    |  270 ++++-
 assets/js/classes/cls_client.js                    |    4 +
 assets/js/classes/locationadmin.js                 |    2 +-
 assets/js/controller/controllerChat.js             |  184 +++-
 assets/js/controller/controllerClientStoreMap.js   |   45 +-
 assets/js/controller/controllerDetailsClient.js    |  111 ++-
 assets/js/controller/controllerDetailsDrivers.js   |   66 +-
 assets/js/controller/controllerFinancialClaims.js  |  154 +--
 assets/js/controller/controllerFloatingChat.js     |  121 ++-
 assets/js/controller/controllerInstantShipments.js |   23 +-
 assets/js/controller/controllerPortalClients.js    |   59 +-
 assets/js/controller/controllerPortalDrivers.js    |   22 +-
 assets/js/controller/controllerRouteBatching.js    |   39 +-
 .../js/controller/controllerShipmentDeliveryMap.js |   43 +-
 assets/js/controller/controllerWebShipments.js     |   59 +-
 assets/js/controller/dashboardOperations.js        |  124 ++-
 assets/js/controller/login.js                      |  160 ++-
 assets/js/controller/shipmentIHomeController.js    |    1 +
 chat.php                                           |   82 +-
 classes/FirebaseService.php                        |   86 +-
 classes/MailService.php                            |   50 +
 classes/Notifications.php                          |   29 +-
 classes/cls_chat.php                               | 1043 +++++++++++++++++++-
 classes/cls_config.php                             |  150 ++-
 classes/cls_db.php                                 |    5 +
 classes/cls_feature_access.php                     |  118 ++-
 classes/cls_func.php                               |  176 +++-
 classes/cls_pagination_dc.php                      |  126 ++-
 classes/cls_permissions.php                        |   49 +-
 classes/cls_pull.php                               |  208 +++-
 classes/cls_system_control.php                     |   30 +
 classes/controllerChat.php                         |   16 +
 classes/controllerClient.php                       |   99 +-
 classes/controllerDashboardOperations.php          |    9 +-
 classes/controllerDetailsClient.php                |  304 +++---
 classes/controllerDrivers.php                      |   60 +-
 classes/controllerIHomeController.php              |   17 +-
 classes/controllerInstantShipments.php             |   83 +-
 classes/controllerPortalClients.php                |   30 +
 classes/controllerPortalRequests.php               |    8 +
 classes/controllerShipment.php                     |   18 +-
 classes/controllerShipmentDaily.php                |    9 +-
 classes/controllerShipments.php                    |   53 +-
 classes/controllerWebShipments.php                 |  229 ++++-
 classes/export_shipments.php                       |   15 +
 classes/fcm_service.php                            |  162 +--
 classes/invoices/invoices.php                      |    2 +-
 client_info_add.php                                |   14 +-
 client_info_details.php                            |   30 +-
 client_info_modification.php                       |   64 +-
 clients_portal.php                                 |    2 +-
 daily_shipments.php                                |   12 +-
 driver_info_details.php                            |   66 +-
 drivers_portal.php                                 |    2 +-
 err/400.php                                        |    2 +-
 err/401.php                                        |    2 +-
 err/402.php                                        |    2 +-
 err/403.php                                        |    2 +-
 err/404.php                                        |    2 +-
 err/405.php                                        |    2 +-
 err/500.php                                        |    2 +-
 err/501.php                                        |    2 +-
 err/502.php                                        |    2 +-
 err/503.php                                        |    2 +-
 err/504.php                                        |    2 +-
 err/505.php                                        |    2 +-
 financial_wallet.php                               |    4 +-
 index.php                                          |   85 +-
 instant_shipments.php                              |    8 +-
 lang/ar.php                                        |   14 +-
 lang/en.php                                        |   14 +-
 lang/lang.php                                      |   14 +-
 layout/floating_chat_widget.php                    |   51 +-
 layout/footer.php                                  |    8 +
 layout/head.php                                    |    8 +
 layout/mune.php                                    |  124 ++-
 layout/path_helpers.php                            |    8 +-
 layout/script.php                                  |   14 +-
 layout/web_session_guard.php                       |   79 ++
 libraries/FirebaseService.php                      |  188 +---
 notifications.php                                  |   51 +-
 route_batching.php                                 |  129 +--
 services/accept_shipment_driver.php                |  152 +++
 services/api_add_shipment_from_client.php          |  741 +++++++++-----
 services/api_add_withdrawal_request.php            |  358 +------
 services/api_cancel_shipment.php                   |  386 +++++++-
 services/api_client_messages.php                   |    5 +-
 services/api_delivery_types.php                    |   96 +-
 services/api_driver_add_withdrawal_request.php     |  300 ++++--
 services/api_driver_login.php                      |   31 +
 services/api_driver_rating.php                     |  216 +++-
 services/api_get_in_app_notifications.php          |   17 +-
 services/api_order_details.php                     |  371 +++----
 services/api_product_type.php                      |   96 +-
 services/api_read_notification.php                 |  210 +++-
 services/api_regions.php                           |  103 +-
 services/api_shipment_filter_driver.php            |  513 +++++++---
 services/api_shipments.php                         |   32 +-
 services/api_shipments_driver.php                  |   33 +-
 services/api_shipments_instant.php                 |  144 +--
 services/api_shipments_instant_driver.php          |   31 +-
 services/api_update_client_fcm_token.php           |   29 +-
 services/api_update_driver_info.php                |  102 +-
 services/check_driver_arrival.php                  |  246 ++++-
 services/client_login.php                          |  510 +++++++---
 services/client_profile.php                        |   41 +-
 services/complete_shipment_driver.php              |  354 ++++---
 services/debug_private_key.php                     |   32 +-
 services/functions.php                             |   77 +-
 services/get_notifications.php                     |  365 ++++---
 services/get_statistics.php                        |  325 +-----
 services/mark_as_arrived_driver.php                |  267 +++--
 services/notification_firebase_api.php             |   91 +-
 services/register_client.php                       |  638 ++++++++----
 services/send_driver_notification.php              |  146 +--
 services/sendnotification.php                      |   92 +-
 services/shipment_driver_coords.php                |  291 ++++--
 services/test_firebase_setup.php                   |  123 +--
 services/test_firebase_simple.php                  |  114 +--
 services/test_notification.php                     |  101 +-
 services/update_client_info.php                    |   63 +-
 services/update_shipment_status.php                |  360 +++++--
 setting.php                                        |   99 ++
 shipment_info_add.php                              |    6 +-
 shipment_info_details.php                          |  154 ++-
 shipment_info_modification.php                     |   71 +-
 shipments.php                                      |   14 +-
 sign-in.php                                        |   21 +-
 132 files changed, 9911 insertions(+), 4755 deletions(-)

```

## C:/xampp/htdocs/htdocs/dashboard1/client_app-main

```text
android/app/src/main/AndroidManifest.xml
lib/constants/app_urls.dart
lib/constants/colors.dart
lib/main.dart
lib/models/blockatie_pro_package.dart
lib/models/notifications.dart
lib/models/order_details.dart
lib/models/shipment.dart
lib/models/statistics.dart
lib/models/store_statistics.dart
lib/provider/add_shipment_provider.dart
lib/provider/balance_history.dart
lib/provider/bottom_nav.dart
lib/provider/filter.dart
lib/provider/header.dart
lib/provider/home.dart
lib/provider/login.dart
lib/provider/notification.dart
lib/provider/notification_provider.dart
lib/provider/order_details.dart
lib/provider/orders.dart
lib/provider/profile.dart
lib/provider/requests_provider.dart
lib/provider/shipment.dart
lib/provider/shipment_instant.dart
lib/provider/store_statistics_provider.dart
lib/provider/time.dart
lib/provider/wallet.dart
lib/provider/withdrawal.dart
lib/services/auth_api_service.dart
lib/services/auth_services.dart
lib/services/client_fcm_token_service.dart
lib/services/client_rating_service.dart
lib/services/firebase_service.dart
lib/services/in_app_notification_service.dart
lib/services/order_services.dart
lib/services/request_id_service.dart
lib/services/requests_service.dart
lib/services/shipment_services.dart
lib/services/store_statistics_service.dart
lib/services/withdrawal_service.dart
lib/utils/instant_shipment_progress.dart
lib/utils/localization/translations.dart
lib/utils/time/jordan_time.dart
lib/views/bottmsheets/logout_sheet.dart
lib/views/pages/add_shipment/add_shipment.dart
lib/views/pages/auth/components/auth_flow_widgets.dart
lib/views/pages/auth/forget/forgetPassword.dart
lib/views/pages/auth/login/login.dart
lib/views/pages/auth/resetPassword/reset_password.dart
lib/views/pages/auth/signup/register.dart
lib/views/pages/auth/verifyOtp/verify_otp.dart
lib/views/pages/blockatie_pro/blockatie_pro_page.dart
lib/views/pages/blockatie_pro/components/package_card_widget.dart
lib/views/pages/get started/get_started.dart
lib/views/pages/home/components/balance_card.dart
lib/views/pages/home/components/latest_shipments_section.dart
lib/views/pages/home/components/tabbar.dart
lib/views/pages/home/home.dart
lib/views/pages/home/tabs/all-shipments/components/client_shipment_list_widgets.dart
lib/views/pages/home/tabs/all-shipments/components/shipment_card.dart
lib/views/pages/home/tabs/all-shipments/table_all_shipment.dart
lib/views/pages/home/tabs/shipment-instant/components/order_instant_tile.dart
lib/views/pages/home/tabs/shipment-instant/shipment_instant.dart
lib/views/pages/hub/hub.dart
lib/views/pages/hub/profile/profile.dart
lib/views/pages/hub/support&assistance/support_assistence.dart
lib/views/pages/my-store/my_store.dart
lib/views/pages/notifications/notifications.dart
lib/views/pages/orders/order_details.dart
lib/views/pages/splash/splash.dart
lib/views/pages/wallet/components/withdraw_card.dart
lib/views/pages/wallet/wallet.dart
lib/views/widgets/bottom_nav.dart
lib/views/widgets/driver_rating/driver_rating_display.dart
lib/views/widgets/socail_media_contacts.dart
linux/flutter/generated_plugins.cmake
macos/Flutter/GeneratedPluginRegistrant.swift
pubspec.lock
pubspec.yaml
windows/flutter/generated_plugins.cmake
 android/app/src/main/AndroidManifest.xml           |    6 +
 lib/constants/app_urls.dart                        |    8 +
 lib/constants/colors.dart                          |    8 +-
 lib/main.dart                                      |  297 +++-
 lib/models/blockatie_pro_package.dart              |   37 +-
 lib/models/notifications.dart                      |   10 +-
 lib/models/order_details.dart                      |   72 +-
 lib/models/shipment.dart                           |   15 +-
 lib/models/statistics.dart                         |   22 +
 lib/models/store_statistics.dart                   |   14 +-
 lib/provider/add_shipment_provider.dart            |  288 ++--
 lib/provider/balance_history.dart                  |  184 +-
 lib/provider/bottom_nav.dart                       |    9 +-
 lib/provider/filter.dart                           |  337 ++--
 lib/provider/header.dart                           |   16 +-
 lib/provider/home.dart                             |  124 +-
 lib/provider/login.dart                            |   99 +-
 lib/provider/notification.dart                     |  396 +++--
 lib/provider/notification_provider.dart            |  130 +-
 lib/provider/order_details.dart                    |  152 +-
 lib/provider/orders.dart                           |   10 +-
 lib/provider/profile.dart                          |  763 +++++----
 lib/provider/requests_provider.dart                |   83 +-
 lib/provider/shipment.dart                         |  299 ++--
 lib/provider/shipment_instant.dart                 |  466 ++++--
 lib/provider/store_statistics_provider.dart        |   76 +-
 lib/provider/time.dart                             |   16 +-
 lib/provider/wallet.dart                           |   26 +-
 lib/provider/withdrawal.dart                       |  178 +-
 lib/services/auth_api_service.dart                 |   14 +
 lib/services/auth_services.dart                    |  512 ++++--
 lib/services/client_fcm_token_service.dart         |    3 +-
 lib/services/client_rating_service.dart            |    3 +-
 lib/services/firebase_service.dart                 |  382 ++++-
 lib/services/in_app_notification_service.dart      |  312 ++--
 lib/services/order_services.dart                   |   17 +-
 lib/services/request_id_service.dart               |   11 +-
 lib/services/requests_service.dart                 |   54 +-
 lib/services/shipment_services.dart                |    3 +-
 lib/services/store_statistics_service.dart         |   42 +-
 lib/services/withdrawal_service.dart               |   99 +-
 lib/utils/instant_shipment_progress.dart           |    2 +-
 lib/utils/localization/translations.dart           |  114 +-
 lib/utils/time/jordan_time.dart                    |   82 +-
 lib/views/bottmsheets/logout_sheet.dart            |   30 +-
 lib/views/pages/add_shipment/add_shipment.dart     |   54 +-
 .../pages/auth/components/auth_flow_widgets.dart   |    8 +-
 lib/views/pages/auth/forget/forgetPassword.dart    |   11 +-
 lib/views/pages/auth/login/login.dart              |  221 +--
 .../pages/auth/resetPassword/reset_password.dart   |   11 +-
 lib/views/pages/auth/signup/register.dart          |   12 +-
 lib/views/pages/auth/verifyOtp/verify_otp.dart     |   12 +-
 .../pages/blockatie_pro/blockatie_pro_page.dart    |   50 +-
 .../components/package_card_widget.dart            |   55 +-
 lib/views/pages/get started/get_started.dart       |    2 +
 lib/views/pages/home/components/balance_card.dart  |    8 +-
 .../home/components/latest_shipments_section.dart  |   26 +-
 lib/views/pages/home/components/tabbar.dart        |  134 +-
 lib/views/pages/home/home.dart                     |  440 ++---
 .../components/client_shipment_list_widgets.dart   |  288 +++-
 .../all-shipments/components/shipment_card.dart    |   11 +-
 .../tabs/all-shipments/table_all_shipment.dart     |  183 +-
 .../components/order_instant_tile.dart             |    2 +-
 .../tabs/shipment-instant/shipment_instant.dart    |   19 +-
 lib/views/pages/hub/hub.dart                       |  428 ++---
 lib/views/pages/hub/profile/profile.dart           |  206 ++-
 .../hub/support&assistance/support_assistence.dart |   10 +-
 lib/views/pages/my-store/my_store.dart             | 1762 ++++++++++++++------
 lib/views/pages/notifications/notifications.dart   |   12 +-
 lib/views/pages/orders/order_details.dart          | 1175 +++++++++----
 lib/views/pages/splash/splash.dart                 |   72 +-
 .../pages/wallet/components/withdraw_card.dart     |   18 +-
 lib/views/pages/wallet/wallet.dart                 |  463 ++---
 lib/views/widgets/bottom_nav.dart                  |   30 +-
 .../driver_rating/driver_rating_display.dart       |   40 +-
 lib/views/widgets/socail_media_contacts.dart       |   24 -
 linux/flutter/generated_plugins.cmake              |    1 -
 macos/Flutter/GeneratedPluginRegistrant.swift      |    2 +
 pubspec.lock                                       |  120 +-
 pubspec.yaml                                       |    3 +
 windows/flutter/generated_plugins.cmake            |    1 -
 81 files changed, 7442 insertions(+), 4293 deletions(-)

```
