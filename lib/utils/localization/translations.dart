import 'package:blockatie/utils/localization/app_localizations.dart';

class AppTranslations {
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      // App General
      'app_name': 'OIIAX Merchant',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'driver_rating_success': 'Driver rating submitted successfully.',
      'driver_rating_failed': 'Unable to submit driver rating right now.',
      'driver_rating_session_expired': 'Session expired. Please log in again.',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'back': 'Back',
      'next': 'Next',
      'submit': 'Submit',
      'retry': 'Retry',
      'ok': 'OK',
      'got_it': 'Got it',
      'hello': 'Hello',
      'amount': 'Amount',
      'price': 'Price',
      'message': 'Message',
      "looking_for_driver": "Looking for driver",
      'loing_for_driver': 'Looking for driver',
      // Authentication
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'sign_out': 'Sign Out',
      'login': 'Login',
      'register': 'Register',
      'forgot_password': 'Forgot Password',
      'reset_password': 'Reset Password',
      'email': 'Email',
      'phone': 'Phone',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'remember_me': 'Remember Me',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      'create_account': 'Create Account',
      'enter_email_phone': 'Enter your email or phone number',
      'enter_password': 'Enter your password',
      'password_required': 'Password is required',
      'passwords_dont_match': 'Passwords do not match',
      'invalid_email': 'Invalid email address',
      'invalid_phone': 'Invalid phone number',
      'login_success': 'Login successful',
      'registration_success': 'Registration successful',
      'password_reset_sent': 'Password reset link sent',
      'otp_verification': 'OTP Verification',
      'enter_otp': 'Enter the OTP sent to your number',
      'verify_otp': 'Verify OTP',
      'resend_otp': 'Resend OTP',
      'otp_sent': 'OTP sent successfully',
      'phone_number_required': 'Phone number is required',
      'new_password': 'New Password',
      'shipment_receipt': 'Shipment Receipt!',
      'the_shipment_has_been_received_successfully':
          'The shipment has been received successfully',
      // Navigation
      'home': 'Home',
      'profile': 'Profile',
      'settings': 'Settings',
      'notifications': 'Notifications',
      'orders': 'Orders',
      'shipments': 'Shipments',
      'wallet': 'Wallet',
      'available_to_withdraw': 'Available to withdraw',
      'support': 'Support',
      'my_store': 'My Store',
      'hub': 'Hub',

      // Home
      'welcome': 'Welcome',
      'dashboard': 'Dashboard',
      'recent_orders': 'Recent Orders',
      'total_balance': 'Total Balance',
      'number_of_orders': 'Number of Orders',
      'pending_orders': 'Pending Orders',
      'completed_orders': 'Completed Orders',
      'sign_in_to_account': 'Sign in to your Account',
      'enter_phone_password': 'Enter your phone and password to log in',

      // Shipments
      'add_shipment': 'Add Shipment',
      'shipment_details': 'Shipment Details',
      'pickup_location': 'Pickup Location',
      'delivery_location': 'Delivery Location',
      'shipment_status': 'Shipment Status',
      'tracking_number': 'Tracking Number',
      'estimated_delivery': 'Estimated Delivery',
      'shipment_cost': 'Shipment Cost',
      'driver_info': 'Driver Information',
      'customer_info': 'Customer Information',
      'shipments_in_progress': 'Shipments In Progress',
      'shipments_delivered': 'Shipments Delivered',
      'cancelled_shipments': 'Cancelled\nShipments',

      // Location & Map
      'location_details': 'Location Details',
      'current_location': 'Current Location:',
      'map_view': 'Map View',
      'directions': 'Directions',
      'copy': 'Copy',
      'location_copied': 'Location copied to clipboard:',
      'location_label': 'Location:',

      // Profile
      'personal_info': 'Personal Information',
      'account_settings': 'Account Settings',
      'change_password': 'Change Password',
      'delete_account': 'Delete Account',
      'logout': 'Logout',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'please_enter_first_name': 'Please enter your first name',
      'please_enter_last_name': 'Please enter your last name',
      'full_name': 'Full Name',
      'phone_number': 'Phone Number',
      'address': 'Address',
      'city': 'City',
      'country': 'Country',
      'postal_code': 'Postal Code',

      // Support
      'contact_support': 'Contact Support',
      'help_center': 'Help Center',
      'faq': 'Frequently Asked Questions',
      'report_issue': 'Report an Issue',
      'live_chat': 'Live Chat',
      'email_support': 'Email Support',
      'phone_support': 'Phone Support',
      'contact_us': 'Contact us !',
      'support_24_hours':
          'If you have any questions or problems, we are with you 24 hours',
      'chat_with_us': 'Chat with us',
      'call_us_now': 'Call us now',
      'not_available': 'Not available',
      'get_help_support': 'Get help and customer support',
      'whatsapp': 'WhatsApp',
      'whatsapp_message': 'Hello! I need help with OIIAX Merchant services.',
      'whatsapp_chat_with_us': 'Chat with us on WhatsApp',
      'whatsapp_not_available': 'WhatsApp not available',

      // Common Actions
      'search': 'Search',
      'filter': 'Filter',
      'sort': 'Sort',
      'refresh': 'Refresh',
      'pull_to_refresh': 'Pull to refresh',
      'no_data': 'No data available',
      'no_internet': 'No internet connection',
      'try_again': 'Try again',
      'connection_error': 'Connection error',
      'unknown_error': 'Unknown error occurred',
      'unknown_error_occurred': 'Unknown error occurred',
      'please_try_again_later': 'Please try again later',
      'an_error_occurred': 'An error occurred',
      'phone_valid':
          'Use a valid Jordan mobile number starting with 077, 078, or 079 and containing 10 digits',
      'something_went_wrong_please_try_again':
          'Something went wrong. Please try again.',

      // Time and Date
      'today': 'Today',
      'yesterday': 'Yesterday',
      'tomorrow': 'Tomorrow',
      'this_week': 'This Week',
      'last_week': 'Last Week',
      'this_month': 'This Month',
      'last_month': 'Last Month',
      'this_year': 'This Year',
      'last_year': 'Last Year',

      // Status
      'pending': 'Pending',
      'processing': 'Processing',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'failed': 'Failed',
      'active': 'Active',
      'inactive': 'Inactive',
      'online': 'Online',
      'offline': 'Offline',

      // Messages
      'are_you_sure': 'Are you sure?',
      'this_action_cannot_be_undone': 'This action cannot be undone.',
      'data_saved_successfully': 'Data saved successfully',
      'data_deleted_successfully': 'Data deleted successfully',
      'operation_failed': 'Operation failed',
      'please_wait': 'Please wait...',
      'processing_request': 'Processing your request...',
      'withdrawal_alert': 'Withdrawal Alert',
      'withdrawal_alert_desc': 'Do you want to make the transaction',
      // Wallet & Payments
      'enter_amount': 'Enter Amount',
      'withdrawal_request': 'Withdrawal Request',
      'confirm_withdrawal': 'Confirm Withdrawal',
      'confirm_withdrawal_content':
          'Do you want to make a withdrawal request for',
      'submit_withdrawal': 'Submit Withdrawal',
      'withdrawal_success':
          'Your withdrawal request has been submitted successfully and is being processed.',

      // Get Started
      'always_in_control': 'Always In Control,',
      'always_on_time': 'Always On Time',
      'get_started_description':
          'Easily track your shipments, view delivery updates, and manage your routes — all from one place.',
      'get_started': 'Get Started',

      // Registration
      'register_as': 'Register as',
      'register_as_description': 'Register as a customer or driver',
      'client_name': 'Client Name',
      'store_name': 'Store Name',

      // Forgot Password & OTP
      'forgot_password_description':
          'Enter your email or phone number to reset your password',
      'email_address': 'Email Address',
      'send_reset_link': 'Send Reset Link',
      'reset_link_sent': 'Reset Link Sent',
      'reset_link_sent_to': 'Reset link sent to your',
      'remember_password': 'Remember your password? ',
      'dont_receive_otp': 'Don\'t you receive the OTP? ',
      'verify': 'Verify',

      // OIIAX Pro
      'blockatie_pro': 'OIIAX Pro',
      'blockatie_pro_description': 'OIIAX Pro blocks ads and trackers.',
      'error_loading_packages': 'Error Loading Packages',
      'no_packages_available': 'No Packages Available',
      'check_back_later_packages': 'Check back later for available packages.',
      'could_not_open_whatsapp': 'Could not open WhatsApp',
      'error_opening_whatsapp': 'Error opening WhatsApp:',
      'blockatie_pro_help_content':
          'Need help with OIIAX Pro packages? Contact our support team via WhatsApp for assistance.',

      // Package Card Widget
      'in_just': 'In just',
      'get_in_touch_about': 'Get in touch about',
      'open_whatsapp': 'Open WhatsApp',
      'package_features': 'Package Features',
      'contact_via_whatsapp': 'Contact via WhatsApp',
      'features': 'Features',
      'description': 'Description',
      'package_details': 'Package Details',
      'premium_package': 'Premium Package',
      'get_started_with_package': 'Get Started with Package',
      'rank': 'Rank',
      'client_rating': 'Client Rating',
      'average_rating': 'Average Rating',
      'loading_rating': 'Loading rating...',
      'error_loading_rating': 'Error loading rating',
      'withdrawal': 'Withdrawal',
      'deposit': 'Deposit',
      'transaction': 'Transaction',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'cash': 'Cash',
      'bank_transfer': 'Bank Transfer',
      'requested_at': 'Requested At',
      'withdrawal_method': 'Withdrawal Method',
      'account_details': 'Account Details',
      'logout_confirmation': 'Are you sure want to logout',
      'yes_logout': 'Yes, Logout',
      'client': 'Client',
      // Add Shipment alert error

      "connection_timeout": "Connection timeout",
      "request_timeout": "Request timeout",
      "network_error": "Network error",
      "server_error": "Server error",
      "missing_user_id_or_api_key": "Missing user ID or API key",
      "invalid_shipment_date": "Invalid shipment date",
      "shipment_date_past": "Shipment date cannot be in the past",
      "shipment_date_today": "Shipment date cannot be today",
      "failed_to_create_shipment": "Failed to create shipment",
      //

      "client_phone": "Client Phone",
      "client_location": "Client Location",
      "delivery_cost": "Delivery Cost",
      // Add Shipment
      'validation_error': 'Validation Error',
      'please_fill_required_fields': 'Please fill in all required fields:',
      'recipient_name': 'Recipient Name',
      'recipient_phone': 'Recipient Phone',
      'delivery_address': 'Delivery Address',
      'region_selection': 'Region Selection',
      'product_type': 'Product Type',
      'valid_shipment_cost': 'Valid Shipment Cost (must be greater than 0)',
      'delivery_type': 'Delivery Type',
      'complete_required_fields':
          'Please complete all required fields before proceeding.',
      'unable_to_connect_server': 'Unable to connect to the server',
      'please_check_internet_connection':
          'Please check your internet connection and try again',
      'request_took_too_long': 'The request took too long to complete',
      'network_error_occurred': 'A network error occurred',
      'please_check_connection': 'Please check your connection and try again',
      'server_error_occurred': 'A server error occurred',
      'authentication_error': 'Authentication error',
      'invalid_shipment_date_format': 'Invalid shipment date format',
      'please_select_future_date_and_time':
          'Please select a future date and time for the shipment',
      'please_select_date_not_today': 'Please select a date that is not today',
      'shipments_must_be_scheduled_for_future_dates':
          'Shipments must be scheduled for future dates',
      'unexpected_error_occurred': 'An unexpected error occurred',
      'invalid_date_time': 'Invalid Date/Time',
      'invalid_date': 'Invalid Date',
      'region_required': 'Region Required',
      'please_select_region_for_shipment':
          'Please select a region for the shipment',
      'shipment_created_successfully': 'Shipment has been created successfully',
      'policy_number': 'Policy Number',
      'you_will_be_redirected_to_shipments_list':
          'You will be redirected to the shipments list',
      'step_1': 'Step 1',
      'step_2': 'Step 2',
      'step_3': 'Step 3',
      'name_of_recipient': 'Name Of The Recipient Of The Shipment',
      'enter_recipient_name': 'Enter the name of the recipient',
      'phone_of_recipient': 'Phone Of The Recipient Of The Shipment',
      'detailed_address': 'Detailed Address Of The Recipient',
      'select_region': 'Select Region',
      'choose_region': 'Choose a region',
      'shipment_date_time': 'Date & Time Of Shipment',
      'change_date': 'Change Date',
      'change_time': 'Change Time',
      'total_value_of_shipment': 'Total Value Of The Shipment',
      'please_enter_shipment_cost': 'Please enter shipment cost',
      'please_enter_valid_number': 'Please enter a valid number',
      'customer_note': 'Customer Note',
      'create_and_track_new_shipment': 'Create and track a new shipment',

      // Home Page
      'statistics': 'Statistics',
      'shipment': 'Shipment',
      'in_progress': 'In Progress',
      'delivered': 'Delivered',
      'total_required': 'Total Required',
      'total_order_value': 'Total Order Value',
      'search_results_for': 'Search results for',
      'found': 'found',
      'clear': 'Clear',
      'no_shipments_found_for': 'No shipments found for',
      'no_shipments_found': 'No shipments found',
      'no_driver_assigned': 'No Driver Assigned',
      'search_by_order_id': 'Search by Order ID',
      'table_all_shipment': 'My Shipments',
      'shipment_instant': 'Shipment Instant',
      'support_and_assistant': 'Support and assistant',
      'instant_shipment': 'Instant Shipment',
      'add_new_shipment': 'Add New Shipment',
      'view_all': 'View all',
      'recipient_number': 'Recipient number',
      'name_drivers': 'Name Drivers',
      'there_is_return': 'There is return',
      'no_return': 'Non-Returnable',
      'delivered_at': 'Delivered at',
      'accept_order': 'Accept Order',
      'order_detail': 'Order Detail',
      'order_delivery': 'Shipment Delivery',
      'continue': 'Continue',
      'registration_successful': 'Registration Successful!',
      'registration_successful_desc':
          'A new store has been successfully registered and will be contacted to activate the account',

      'select_driver': 'Select Driver',
      'withdrawal_request_submitted': 'withdrawal request submitted',
      'unaccounted': 'Pending Accounting',
      'driver_accounted': 'Driver Accounted',
      'client_accounted': 'Client Accounted',
      'unknown': 'Unknown',
      'order': 'Order',
      'search_here': 'Search here...',
      'confirmation_of_acceptance': 'Confirmation of Acceptance',
      'do_you_want_to_deliver_this_shipment':
          'Are you sure you want to deliver this shipment?',

      'do_you_want_to_cancel_this_shipment':
          'do you want to cancel this shipment',
      'shipment_has_been_completed_successfully':
          'Shipment has been completed successfully.',
      'do_you_want_to_accept_this_shipment':
          'do you want to accept this shipment',
      'no_shipment_data_found': 'No shipment data found',
      'search_by_policy_status_type_or_product_type':
          'Search by order number or order ID',
      'filter_by_date_shipment_status_location_or_name':
          'Filter by date, shipment status, location, or name',
      'filter_by_date': 'Filter By Date',
      'filter_by_time': 'Filter By Time',
      'status_of_shipment': 'Status of Shipment',
      'reset': 'Reset',
      // Balance & Financial
      'total_balance_of_shipments_accrued': 'Total Withdrawable Balance',
      'total_balance_of_shipments_accrued1': 'Total Balance',
      'client_balance_is_due': 'Withdrawable Balance',
      'required_by_client': 'Outstanding Payables',
      // Hub Page
      'main': 'Main',
      'pages': 'Pages',
      'details': 'Details',
      'hub_title': 'Welcome back',
      'hub_subtitle': 'Here is your store summary today',
      'hub_welcome_back': 'Welcome back',
      'hub_everything_in_one_place': 'Store tools and operations summary',
      'hub_main': 'Quick actions',
      'hub_operations': 'Shipping tools',
      'hub_more_tools': 'More Tools',
      'hub_manage_store': 'Move between your main store screens quickly',
      'hub_track_orders': 'Open shipments and daily workflows quickly',
      'hub_quick_access':
          'Settings, notifications, language, and account actions',
      'hub_open': 'Ready',
      'hub_membership': 'Membership',
      'hub_home_subtitle': 'Open dashboard and store overview',
      'hub_my_store_subtitle': 'Review your store profile and details',
      'hub_wallet_subtitle': 'Review balance and withdrawals',
      'hub_profile_subtitle': 'Update your profile and store details',
      'hub_all_shipments_subtitle': 'Review assigned and archived shipments',
      'hub_instant_shipments_subtitle': 'Open fast shipment opportunities',
      'hub_add_shipment_subtitle': 'Create a new shipment for your store',
      'conversations': 'Conversations',
      'hub_conversations_subtitle': 'Review support and shipment conversations',
      'chat_no_conversations': 'No conversations yet',
      'chat_no_conversations_description':
          'Your support and shipment conversations will appear here.',
      'chat_unable_load_conversations':
          'Unable to load conversations. Please try again.',
      'chat_unable_load_conversations_description':
          'Check your connection, then refresh to load the latest conversations.',
      'chat_session_expired': 'Your session has expired. Please sign in again.',
      'chat_session_expired_description':
          'Sign in again to access your support and shipment conversations.',
      'chat_start_conversation': 'Start a conversation',
      'chat_open_shipment_failed':
          'Unable to open shipment chat. Please try again.',
      'chat_shipment_number': 'Shipment number',
      'chat_unread_message': 'unread message',
      'chat_unread_messages': 'unread messages',
      'chat_yesterday': 'Yesterday',
      'chat_placeholder_message':
          'The messaging interface will be available here soon.',
      'chat_type_message': 'Type your message',
      'chat_send': 'Send',
      'chat_sending': 'Sending',
      'chat_message_failed': 'Message failed to send',
      'chat_retry': 'Retry',
      'chat_start_support_conversation': 'Start a conversation with support',
      'chat_new_messages': 'New messages',
      'chat_access_denied': 'You cannot access this conversation',
      'chat_rate_limited': 'Too many messages, try again shortly',
      'chat_loading_messages': 'Loading messages',
      'chat_load_older_messages': 'Load older messages',
      'chat_today': 'Today',
      'chat_unable_load_messages': 'Unable to load messages',
      'chat_message_required': 'Please type a message',
      'chat_my_message': 'Your message',
      'chat_support_message': 'Support message',
      'chat_read': 'Read',
      'chat_read_at': 'Read at',
      'hub_support_subtitle': 'Get help and contact support quickly',
      'hub_notifications_subtitle': 'Review alerts and important updates',
      'hub_settings_subtitle': 'Update account preferences and store settings',
      'hub_logout_subtitle': 'Sign out from this device securely',
      'hub_pro_subtitle': 'Review subscription tools and upgrades',
      'hub_language_english': 'English',
      'hub_language_arabic': 'العربية',
      'personal_details': 'Personal Details',
      'edit_accounts': 'Edit accounts',
      'user_preferences': 'User preferences',
      'app_settings': 'App Settings',
      'customize_preferences_and_app_settings':
          'Customize preferences and app settings.',
      'loading_profile_data': 'Loading profile data...',
      'updating': 'Updating...',
      'update_profile': 'Update Profile',
      'support_and_assistance': 'Support and assistance',
      'get_help_and_customer_support': 'Get help and customer support',
      'please_enter_your_phone_number': 'Please enter your phone number',
      'please_enter_your_email': 'Please enter your email',
      'please_enter_a_valid_email': 'Please enter a valid email',
      'please_enter_your_message': 'Please enter your message',
      'sending': 'Sending...',

      // Location Order & Picker
      'location_order': 'Location Order',
      'custom_order_for_visiting_locations':
          'Custom order for visiting locations.',
      'new_order': 'New Order!',
      'order_distance': 'Order Distance',
      'track_order': 'Track Order',
      'track_driver': 'Track Driver',
      'call_customer': 'Call Customer',
      'select_location': 'Select Location',
      'tap_on_map_to_select_your_location':
          'Tap on the map to select your location',
      'location_selected': 'Location selected',
      'selected_location': 'Selected Location',
      'getting_address': 'Getting address...',
      'tap_on_map_to_select_location': 'Tap on map to select location',
      'coordinates': 'Coordinates',
      'confirm_location': 'Confirm Location',
      'choose_from_predefined_locations_or_enter_coordinates':
          'Choose from predefined locations or enter coordinates',
      'predefined_locations': 'Predefined Locations',
      'custom_coordinates': 'Custom Coordinates',
      'latitude': 'Latitude',
      'longitude': 'Longitude',
      'address_optional': 'Address (Optional)',
      'enter_address_or_leave_empty_to_auto_detect':
          'Enter address or leave empty to auto-detect',
      'custom_location': 'Custom Location',
      'please_enter_valid_coordinates': 'Please enter valid coordinates',
      'get_address': 'Get Address',

      // My Store Page
      'store_profile': 'Store Profile',
      'owner': 'Owner',
      'no_store_information': 'No store information',
      'store_statistics': 'Store Statistics',
      'total_orders': 'Total Orders',
      'active_orders': 'Active Orders',
      'revenue': 'Revenue',
      'rating': 'Rating',
      'recent_activity': 'Recent Activity',
      'new_order_received': 'New order received',
      'order_from_customer': 'Order from customer',
      'product_updated': 'Product updated',
      'product_price_updated': 'Product price updated',
      'payment_received': 'Payment received',
      'payment_amount_received': 'Payment amount received',
      'hours_ago': 'hours ago',
      'day_ago': 'day ago',

      // Notifications Page
      'notifications_title': 'Notifications',
      'notifications_subtitle': 'Latest updates for your store and shipments',
      'notifications_empty_title': 'No notifications yet',
      'notifications_empty_message': 'New store updates will appear here.',
      'notifications_loading_title': 'Loading notifications...',
      'notifications_loading_message': 'Please wait a moment.',
      'notifications_retry': 'Try again',
      'notifications_network_error':
          'Unable to connect to the server. Check your internet and try again.',
      'notifications_timeout_error':
          'The request took longer than expected. Please try again.',
      'notifications_unauthorized_error':
          'Your session is no longer valid. Please sign in again.',
      'notifications_server_error':
          'A temporary server error occurred. Please try again later.',
      'notifications_generic_error':
          'Unable to load notifications. Please try again.',
      'notifications_today': 'Today',
      'notifications_yesterday': 'Yesterday',
      'notifications_minute_ago': '1 min ago',
      'notifications_minutes_ago': 'mins ago',
      'notifications_hour_ago': '1 hour ago',
      'notifications_hours_ago': 'hours ago',
      'notifications_unread': 'Unread',
      'notifications_read': 'Read',
      'notifications_total': 'Total',
      'notifications_latest': 'Latest store alerts and important updates',
      'notifications_open_order': 'Open shipment',
      'notifications_new': 'New',
      'notifications_mark_read_failed':
          'Unable to mark the notification as read.',
      'notifications_no_message': 'You have a new notification.',
      'notification': 'Notification',
      'app_alerts_for_key_information': 'App alerts for key information',
      'no_notifications_found': 'No notifications found',
      'just_now': 'Just now',
      'min_ago': 'min ago',
      'hr_ago': 'hr',
      's': 's',
      'd_ago': 'd ago',

      // Order Details Page
      'order_details': 'Order Details',
      'placed_on': 'Placed on',
      'unable_to_load_order_details':
          'Unable to load order details.\nPlease check your connection and try again.',
      'retrying': 'Retrying...',
      'no_order_details': 'No Order Details',
      'order_details_are_null':
          'Order details are null.\nTry refreshing or check the debug logs.',
      'load_data': 'Load Data',

      'the_order_is': 'The order is',
      'steps_completed': '{completed} of {total} steps completed',
      'could_not_launch_phone_app': 'Could not launch phone app',
      'error_launching_phone_app': 'Error launching phone app',
      'driver_location_not_available': 'Driver location not available',
      'location_not_available': 'Location not available',
      'unable_to_get_your_location':
          'Unable to get your location. Please enable location services.',
      'invalid_driver_location_coordinates':
          'Invalid driver location coordinates',
      'error_tracking_order': 'Error tracking order',
      'route_to': 'Route to',
      'open_in_google_maps': 'Open in Google Maps',
      'route_information': 'Route Information',
      'calculating': 'Calculating...',
      'eta': 'ETA',
      'distance': 'Distance',
      'your_delivery_driver': 'Your delivery driver',
      'image': 'Image',

      // Wallet Page
      'transactions': 'Transactions',
      'see_all': 'See all',
      'required_by_the_client': 'Withdrawable Balance',
      'error_loading_requests': 'Error Loading Requests',
      'no_withdrawal_requests': 'No Withdrawal Requests',
      'no_withdrawal_requests_description':
          'You haven\'t made any withdrawal requests yet.',
      'show_balance': 'Show Balance',
      'hide_balance': 'Hide Balance',
      'withdraw': 'Withdraw',
      'secure_fast_and_easy_withdrawal': 'Secure, fast, and easy withdrawal',
      'select_withdrawal_option': 'Select Withdrawal option',
      'choose_your_preferred_withdrawal_method':
          'Choose your preferred withdrawal method',
      'cash_withdrawal_option': 'Cash Delivery',
      'click_withdrawal_option': 'Click transfer',

      'withdrawal_failed':
          'Failed to submit withdrawal request. Please try again.',
      'terms_conditions': 'I agree to the terms and conditions',

      // Notifications
      'enable_notifications': 'Enable Notifications',
      'not_now': 'Not Now',
      'enable': 'Enable',
      'new_notification': 'New Notification',
      'set_time': 'Set Time',

      // Language
      'language': 'Language',
      'select_language': 'Select Language',
      'english': 'English',
      'arabic': 'العربية',

      // Errors
      'login_failed': 'Login Failed',
      'login_error': 'Login Error',
      'unable_make_call': 'Unable to make phone call',
      'language_changed': 'Language changed to',
      'failed_change_language': 'Failed to change language:',
      'language_changed_successfully': 'Language changed successfully!',
      'restart_app_for_full_change':
          'Please restart the app for the full language change to take effect.',
      'later': 'Later',
      'restart_now': 'Restart Now',
      'name_client': 'Name Store Owner',
      'phone_client': " Store Owner Phone",
      'client_password': 'Store Owner Password',
      'location_client': 'Location Store Owner',
      'view_and_manage_your_account_profile':
          'View and manage your account profile',
      'logged_out_successfully': 'Logged out successfully',
      'failed_to_logout': 'Failed to logout',
      'deleting_account': 'Deleting account',
      'user_id_not_found': 'User ID not found',
      'please_login_again': 'Please login again',
      'failed_to_delete_account': 'Failed to delete account',
      'confirmation_receipt': 'Confirmation of Receipt',
      'are_you_sure_you_want_receipt_shipment':
          'Are you sure you want to Receipt this shipment?',
      // Order Management
      'order_creation_date': 'Order Creation Date:',
      'cancel_order': 'Cancel Order',
      'accept_at_first': 'Accept at First',
      'no_location': 'No location',
      'help': 'Help?',
      'placed_on_date': 'Placed on 12th Feb 2025, 05:30PM',
      'call_driver': 'Call Driver',

      // Month Names
      'jan': 'Jan',
      'feb': 'Feb',
      'mar': 'Mar',
      'apr': 'Apr',
      'may': 'May',
      'jun': 'Jun',
      'jul': 'Jul',
      'aug': 'Aug',
      'sep': 'Sep',
      'oct': 'Oct',
      'nov': 'Nov',
      'dec': 'Dec',
      'yes_accept': 'Yes',
      'shipment_accepted': 'Shipment Accepted!',
      'shipment_accepted_successfully': 'Shipment accepted successfully',
      // Store & Delivery Details
      'client_details': 'Client Details',
      'driver_details': 'Driver Details',
      'store_name_not_available': 'Store name not available',
      'address_not_available': 'Address not available',
      'driver_name_not_available': 'Driver name not available',
      'phone_not_available': 'Phone not available',

      // Driver Location Map
      'driver_location': 'Driver Location',
      'driver_current_location': 'Driver current location',

      // Day Suffixes
      'st': 'st',
      'nd': 'nd',
      'rd': 'rd',
      'th': 'th',
      //==== driver
      "driver_name": "Driver Name",
      "driver_phone": "Driver Phone",
      // Status Names for Comparison

      'dispatched': 'Dispatched',
      'in_transit': 'In Transit',
      'out_for_delivery': 'Out for Delivery',
      'awaiting_pickup': 'Awaiting Pickup',
      'failed_delivery': 'Failed Delivery',
      'custom_alert': 'Custom Alert',
      'custom_alert_desc': 'This is a custom alert with specific button text',

      'email_required': 'Email is required',
      'phone_required': "Phone number is required",
      'store_name_required': "Store name is required",
      'client_name_required': "Client name is required",
      'shipment_note': "Shipment Note",
      'returned': 'Rreturned',
    },
    'ar': {
// App General
      'app_name': 'OIIAX للتجار',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'نجح',
      'driver_rating_success': 'تم إرسال تقييم السائق بنجاح.',
      'driver_rating_failed': 'تعذر إرسال تقييم السائق حالياً. حاول مرة أخرى.',
      'driver_rating_session_expired':
          'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.',
      'cancel': 'إلغاء',
      'yes_accept': 'نعم موافق',
      'confirm': 'تأكيد',
      'save': 'حفظ',
      'delete': 'حذف',
      'edit': 'تعديل',
      'close': 'إغلاق',
      'back': 'رجوع',
      'next': 'التالي',
      'submit': 'إرسال',
      'retry': 'إعادة المحاولة',
      'ok': 'موافق',
      'got_it': 'فهمتها',
      'custom_alert': 'تنبيه مخصص',
      'custom_alert_desc': 'هذا تنبيه مخصص بنص زر محدد',
      'hello': 'مرحبًا',
      'amount': 'المبلغ',
      'notification': 'إشعار',
      // driver
      "driver_name": "اسم السائق",
      "driver_phone": "هاتف السائق",
      //
      "client_name": "اسم العميل",
      "client_phone": "هاتف العميل",
      "client_location": "موقع العميل",
      "shipment_cost": "تكلفة الشحنة",
      "delivery_cost": "تكلفة التوصيل",
// Authentication
      'sign_in': 'تسجيل الدخول',
      'sign_up': 'إنشاء حساب',
      'sign_out': 'تسجيل الخروج',
      'login': 'تسجيل الدخول',
      'register': 'تسجيل',
      'forgot_password': 'نسيت كلمة المرور',
      'reset_password': 'إعادة تعيين كلمة المرور',
      'email': 'البريد الإلكتروني',
      'phone': 'الهاتف',
      'password': 'كلمة المرور',
      'confirm_password': 'تأكيد كلمة المرور',
      'remember_me': 'تذكرني',
      'dont_have_account': 'ليس لديك حساب؟',
      'already_have_account': 'لديك حساب بالفعل؟',
      'create_account': 'إنشاء حساب',
      'enter_email_phone': 'أدخل بريدك الإلكتروني أو رقم هاتفك',
      'enter_password': 'أدخل كلمة المرور',
      'password_required': 'كلمة المرور مطلوبة',
      'passwords_dont_match': 'كلمات المرور غير متطابقة',
      'invalid_email': 'عنوان بريد إلكتروني غير صحيح',
      'invalid_phone': 'رقم هاتف غير صحيح',
      'login_success': 'تم تسجيل الدخول بنجاح',
      'registration_success': 'تم إنشاء الحساب بنجاح',
      'password_reset_sent': 'تم إرسال رابط إعادة تعيين كلمة المرور',
      'otp_verification': 'التحقق من رمز OTP',
      'enter_otp': 'أدخل رمز OTP المرسل إلى رقم هاتفك',
      'verify_otp': 'التحقق من OTP',
      'resend_otp': 'إعادة إرسال OTP',
      'otp_sent': 'تم إرسال OTP بنجاح',
      'phone_number': 'رقم الهاتف',
      'phone_number_required': 'رقم الهاتف مطلوب',
      'new_password': 'كلمة المرور الجديدة',

// Navigation
      'home': 'الرئيسية',
      'profile': 'حسابي',
      'settings': 'الإعدادات',
      'notifications': 'الإشعارات',
      'orders': 'الشحنات',
      'shipments': 'الشحنات',
      'wallet': 'المحفظة',
      'available_to_withdraw': 'المتاح للسحب',
      'support': 'الدعم',
      'my_store': 'متجري',
      'hub': 'المركز',
      'shipment_receipt': 'استلام الشحنة!',
      'the_shipment_has_been_received_successfully':
          'لقد تم إستلام الشحنة بنجاح',
// Home
      'welcome': 'مرحباً',
      'dashboard': 'لوحة التحكم',
      'recent_orders': 'الشحنات الحديثة',
      'total_balance': 'إجمالي الرصيد',
      'number_of_orders': 'عدد الشحنات',
      'pending_orders': 'الشحنات المعلقة',
      'completed_orders': 'الشحنات المكتملة',
      'sign_in_to_account': 'تسجيل الدخول إلى حسابك',
      'enter_phone_password': 'أدخل رقم هاتفك وكلمة المرور لتسجيل الدخول',

// Shipments
      'add_shipment': 'إضافة شحنة',
      'shipment_details': 'تفاصيل الشحنة',
      'pickup_location': 'موقع الاستلام',
      'delivery_location': 'موقع التسليم',
      'shipment_status': 'حالة الشحنة',
      'tracking_number': 'رقم التتبع',
      'estimated_delivery': 'موعد التسليم المتوقع',
      'driver_info': 'معلومات السائق',
      'customer_info': 'معلومات العميل',
      'shipments_in_progress': 'الشحنات قيد المعالجة',
      'shipments_delivered': 'الشحنات المكتملة',
      'cancelled_shipments': 'الشحنات الملغية',

// Balance & Financial
      'total_balance_of_shipments_accrued': 'إجمالي الرصيد المتاح للسحب',
      'total_balance_of_shipments_accrued1': 'إجمالي رصيد الشحنات المتراكم',
      'client_balance_is_due': 'الرصيد القابل للسحب',
      'required_by_client': 'المستحقات الواجبة للدفع',

// Additional Missing Keys
      'order': 'طلب',
      'search_here': 'ابحث هنا...',
      'confirmation_of_acceptance': 'تأكيد القبول',
      'do_you_want_to_deliver_this_shipment':
          'هل أنت متأكد أنك تريد تسليم هذه الشحنة؟',
      'do_you_want_to_cancel_this_shipment': 'هل تريد إلغاء هذه الشحنة',
      'shipment_has_been_completed_successfully': 'تم إكمال الشحنة بنجاح.',
      'do_you_want_to_accept_this_shipment': 'هل تريد قبول هذه الشحنة',
      'no_shipment_data_found': 'لم يتم العثور على بيانات الشحنة',
      'search_by_policy_status_type_or_product_type':
          'البحث حسب رقم الشحنة او id الشحنة',
      'filter_by_date_shipment_status_location_or_name':
          'تصفية حسب التاريخ أو حالة الشحنة أو الموقع أو الاسم',
      'filter_by_date': 'تصفية حسب التاريخ',
      'filter_by_time': 'تصفية حسب الوقت',
      'status_of_shipment': 'حالة الشحنة',
      'reset': 'إعادة تعيين',

// Additional Missing Keys

      // Add Shipment alert error
      "connection_timeout": "انتهت مهلة الاتصال",
      "request_timeout": "انتهت مهلة الشحنة",
      "network_error": "خطأ في الشبكة",
      "server_error": "خطأ في الخادم",
      "missing_user_id_or_api_key": "معرّف المستخدم أو مفتاح API مفقود",
      "invalid_shipment_date": "تاريخ الشحنة غير صالح",
      "shipment_date_past": "لا يمكن أن يكون تاريخ الشحنة في الماضي",
      "shipment_date_today": "لا يمكن أن يكون تاريخ الشحنة اليوم",
      "failed_to_create_shipment": "فشل في إنشاء الشحنة",
      "looking_for_driver": "البحث عن سائق",
      // Add Shipment
      'validation_error': 'خطأ في التحقق',
      'please_fill_required_fields': 'يرجى ملء جميع الحقول المطلوبة:',
      'recipient_name': 'اسم المستلم',
      'recipient_phone': 'هاتف المستلم',
      'delivery_address': 'عنوان التسليم',
      'region_selection': 'اختيار المنطقة',
      'product_type': 'نوع المنتج',
      'valid_shipment_cost': 'تكلفة شحنة صحيحة (يجب أن تكون أكبر من 0)',
      'delivery_type': 'نوع التسليم',
      'complete_required_fields':
          'يرجى إكمال جميع الحقول المطلوبة قبل المتابعة.',
      'unable_to_connect_server': 'غير قادر على الاتصال بالخادم',
      'please_check_internet_connection':
          'يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى',
      'request_took_too_long': 'استغرق الشحنة وقتاً طويلاً للإكمال',
      'network_error_occurred': 'حدث خطأ في الشبكة',
      'please_check_connection': 'يرجى التحقق من الاتصال والمحاولة مرة أخرى',
      'server_error_occurred': 'حدث خطأ في الخادم',
      'authentication_error': 'خطأ في المصادقة',
      'invalid_shipment_date_format': 'تنسيق تاريخ الشحنة غير صحيح',
      'please_select_future_date_and_time':
          'يرجى اختيار تاريخ ووقت مستقبلي للشحنة',
      'please_select_date_not_today': 'يرجى اختيار تاريخ ليس اليوم',
      'shipments_must_be_scheduled_for_future_dates':
          'يجب جدولة الشحنات للتواريخ المستقبلية',
      'unexpected_error_occurred': 'حدث خطأ غير متوقع',
      'invalid_date_time': 'تاريخ/وقت غير صحيح',
      'invalid_date': 'تاريخ غير صحيح',
      'region_required': 'المنطقة مطلوبة',
      'please_select_region_for_shipment': 'يرجى اختيار منطقة للشحنة',
      'shipment_created_successfully': 'تم إنشاء الشحنة بنجاح',
      'policy_number': 'رقم السياسة',
      'you_will_be_redirected_to_shipments_list':
          'سيتم توجيهك إلى قائمة الشحنات',
      'step_1': 'الخطوة 1',
      'step_2': 'الخطوة 2',
      'step_3': 'الخطوة 3',
      'name_of_recipient': 'اسم مستلم الشحنة',
      'enter_recipient_name': 'أدخل اسم المستلم',
      'phone_of_recipient': 'هاتف مستلم الشحنة',
      'detailed_address': 'العنوان التفصيلي للمستلم',
      'select_region': 'اختر المنطقة',
      'choose_region': 'اختر منطقة',
      'shipment_date_time': 'تاريخ ووقت الشحنة',
      'change_date': 'تغيير التاريخ',
      'change_time': 'تغيير الوقت',
      'total_value_of_shipment': 'القيمة الإجمالية للشحنة',
      'please_enter_shipment_cost': 'يرجى إدخال تكلفة الشحنة',
      'please_enter_valid_number': 'يرجى إدخال رقم صحيح',
      'customer_note': 'ملاحظة العميل',
      'create_and_track_new_shipment': 'إنشاء وتتبع شحنة جديدة',

// Home Page
      'statistics': 'الإحصائيات',
      'shipment': 'شحنة',
      'in_progress': 'قيد التنفيذ',
      'delivered': 'تم التسليم',
      'total_required': 'إجمالي المطلوب',
      'total_order_value': 'إجمالي قيمة الشحنة',
      'search_results_for': 'نتائج البحث عن',
      'found': 'تم العثور على',
      'clear': 'مسح',
      'no_shipments_found_for': 'لم يتم العثور على شحنات لـ',
      'no_shipments_found': 'لم يتم العثور على شحنات',
      'no_driver_assigned': 'لا يوجد سائق معين',
      'search_by_order_id': 'البحث حسب رقم الشحنة',
      'table_all_shipment': 'شحناتي',
      'shipment_instant': 'شحنات فورية',
      'support_and_assistant': 'الدعم والمساعدة',
      'instant_shipment': 'شحنة فورية',
      'add_new_shipment': 'إضافة شحنة جديدة',
      'view_all': 'عرض الكل',
      'recipient_number': 'رقم المستلم',
      'name_drivers': 'أسماء السائقين',
      'there_is_return': 'هناك إرجاع',
      'no_return': 'لا يوجد مرتجع',
      'delivered_at': 'تم التسليم في',

      'accept_order': 'قبول الشحنة',
      'order_detail': 'تفاصيل الشحنة',
      'unknown': 'غير معروف',

// Order Details
      'unable_to_load_order_details':
          'غير قادر على تحميل تفاصيل الطلب.\nيرجى التحقق من الاتصال والمحاولة مرة أخرى.',
      'retrying': 'إعادة المحاولة...',
      'no_order_details': 'لا توجد تفاصيل للطلب',
      'order_details_are_null':
          'تفاصيل الطلب فارغة.\nحاول التحديث أو تحقق من سجلات التصحيح.',
      'load_data': 'تحميل البيانات',
      'the_order_is': 'الشحنة',
      'steps_completed': '{completed} من {total} خطوات مكتملة',
      'could_not_launch_phone_app': 'لا يمكن تشغيل تطبيق الهاتف',
      'error_launching_phone_app': 'خطأ في تشغيل تطبيق الهاتف',
      'driver_location_not_available': 'موقع السائق غير متاح',
      'unable_to_get_your_location':
          'غير قادر على الحصول على موقعك. يرجى تفعيل خدمات الموقع.',
      'invalid_driver_location_coordinates': 'إحداثيات موقع السائق غير صحيحة',
      'error_tracking_order': 'خطأ في تتبع الشحنة',
      'route_to': 'المسار إلى',
      'open_in_google_maps': 'افتح في خرائط جوجل',
      'route_information': 'معلومات المسار',
      'calculating': 'جاري الحساب...',
      'eta': 'الوقت المتوقع للوصول',
      'distance': 'المسافة',
      'your_delivery_driver': 'سائق التوصيل الخاص بك',
      'image': 'صورة',

      'location_not_available': 'الموقع غير متوفر',

// Wallet

      'transactions': 'المعاملات',
      'see_all': 'عرض الكل',
      'required_by_the_client': 'الرصيد القابل للسحب',
      'error_loading_requests': 'خطأ في تحميل الشحنات',
      'no_withdrawal_requests': 'لا توجد طلبات سحب',
      'no_withdrawal_requests_description': 'لم تقم بتقديم أي طلبات سحب بعد.',
      'show_balance': 'إظهار الرصيد',
      'hide_balance': 'إخفاء الرصيد',
      'withdraw': 'سحب',
      'withdrawal': 'السحب',
      'secure_fast_and_easy_withdrawal': 'سحب آمن وسريع وسهل',
      'select_withdrawal_option': 'اختر خيار السحب',
      'choose_your_preferred_withdrawal_method':
          'اختر طريقة السحب المفضلة لديك',
      'cash_withdrawal_option': 'توصيل نقدي',
      'click_withdrawal_option': 'تحويل كليك',

// Additional Missing Keys
      'returned': 'تم الإرجاع',
      'message': 'رسالة',

// Location & Map
      'location_details': 'تفاصيل الموقع',
      'current_location': 'الموقع الحالي:',
      'map_view': 'عرض الخريطة',
      'directions': 'التوجيهات',
      'copy': 'نسخ',
      'location_copied': 'تم نسخ الموقع إلى الحافظة:',
      'location_label': 'الموقع:',

// Profile
      'personal_info': 'المعلومات الشخصية',
      'account_settings': 'إعدادات الحساب',
      'change_password': 'تغيير كلمة المرور',
      'delete_account': 'حذف الحساب',
      'logout': 'تسجيل الخروج',
      'first_name': 'الاسم الأول',
      'last_name': 'اسم العائلة',
      'please_enter_first_name': 'يرجى إدخال اسمك الأول',
      'please_enter_last_name': 'يرجى إدخال اسم العائلة',
      'full_name': 'الاسم الكامل',
      'address': 'العنوان',
      'city': 'المدينة',
      'country': 'البلد',
      'postal_code': 'الرمز البريدي',

// Support
      'contact_support': 'اتصل بالدعم',
      'help_center': 'مركز المساعدة',
      'faq': 'الأسئلة الشائعة',
      'report_issue': 'الإبلاغ عن مشكلة',
      'live_chat': 'الدردشة المباشرة',
      'email_support': 'الدعم عبر البريد الإلكتروني',
      'phone_support': 'الدعم عبر الهاتف',
      'contact_us': 'اتصل بنا !',
      'support_24_hours':
          'إذا كان لديك أي أسئلة أو مشاكل، نحن معك على مدار 24 ساعة',
      'chat_with_us': 'دردش معنا',
      'call_us_now': 'اتصل بنا الآن',
      'not_available': 'غير متاح',
      'get_help_support': 'احصل على المساعدة والدعم للعملاء',
      'whatsapp': 'واتساب',
      'whatsapp_message': 'مرحباً! أحتاج إلى مساعدتك في خدمات OIIAX للتجار.',
      'whatsapp_chat_with_us': 'دردش معنا على واتساب',
      'whatsapp_not_available': 'واتساب غير متاح',

// Common Actions
      'search': 'بحث',
      'filter': 'تصفية',
      'sort': 'ترتيب',
      'refresh': 'تحديث',
      'pull_to_refresh': 'اسحب للتحديث',
      'no_data': 'لا توجد بيانات متاحة',
      'no_internet': 'لا يوجد اتصال بالإنترنت',
      'try_again': 'حاول مرة أخرى',
      'connection_error': 'خطأ في الاتصال',
      'unknown_error': 'حدث خطأ غير معروف',
      'unknown_error_occurred': 'حدث خطأ غير معروف',
      'please_try_again_later': 'يرجى المحاولة مرة أخرى لاحقاً',
      'an_error_occurred': 'حدث خطأ',
      'something_went_wrong_please_try_again':
          'حدث خطأ ما. يرجى المحاولة مرة أخرى.',

// Time and Date
      'today': 'اليوم',
      'yesterday': 'أمس',
      'tomorrow': 'غداً',
      'this_week': 'هذا الأسبوع',
      'last_week': 'الأسبوع الماضي',
      'this_month': 'هذا الشهر',
      'last_month': 'الشهر الماضي',
      'this_year': 'هذا العام',
      'last_year': 'العام الماضي',
      'phone_valid':
          'أدخل رقم هاتف أردني صحيح يبدأ بـ 077 أو 078 أو 079 ويتكون من 10 أرقام',

// Status
      'pending': 'معلق',
      'processing': 'قيد المعالجة',
      'completed': 'مكتمل',
      'cancelled': 'ملغي',
      'failed': 'فشل',
      'active': 'نشط',
      'inactive': 'غير نشط',
      'online': 'متصل',
      'offline': 'غير متصل',

// Messages
      'are_you_sure': 'هل أنت متأكد؟',
      'this_action_cannot_be_undone': 'لا يمكن التراجع عن هذا الإجراء.',
      'data_saved_successfully': 'تم حفظ البيانات بنجاح',
      'data_deleted_successfully': 'تم حذف البيانات بنجاح',
      'operation_failed': 'فشلت العملية',
      'please_wait': 'يرجى الانتظار...',
      'continue': 'استمرار',

      'processing_request': 'جاري معالجة طلبك...',
      'registration_successful': 'تم التسجيل بنجاح!',
      'registration_successful_desc':
          'تم تسجيل متجر جديد بنجاح وسيتم التواصل لتفعيل الحساب',
// Wallet & Payments
      'enter_amount': 'أدخل المبلغ',
      'withdrawal_request': 'طلب السحب',
      'withdrawal_request_submitted': 'تم تقديم طلب السحب',
      'confirm_withdrawal': 'تأكيد السحب',
      'confirm_withdrawal_content': 'هل تريد تقديم طلب سحب بمبلغ',
      'submit_withdrawal': 'إرسال طلب السحب',
      'withdrawal_success': 'تم إرسال طلب السحب بنجاح وجاري معالجته.',
      'withdrawal_failed': 'فشل في إرسال طلب السحب. يرجى المحاولة مرة أخرى.',
      'terms_conditions': 'أوافق على الشروط والأحكام',

// Get Started
      'always_in_control': 'دائماً تحت السيطرة،',
      'always_on_time': 'دائماً في الوقت المحدد',
      'get_started_description':
          'تتبع شحناتك بسهولة، وعرض تحديثات التسليم، وإدارة مساراتك — كل ذلك من مكان واحد.',
      'get_started': 'ابدأ الآن',

// Registration
      'register_as': 'سجل كـ',
      'register_as_description': 'سجل كعميل أو سائق',
      'store_name': 'اسم المتجر',

// Forgot Password & OTP
      'forgot_password_description':
          'أدخل بريدك الإلكتروني أو رقم هاتفك لإعادة تعيين كلمة المرور',
      'email_address': 'عنوان البريد الإلكتروني',
      'send_reset_link': 'إرسال رابط إعادة التعيين',
      'reset_link_sent': 'تم إرسال رابط إعادة التعيين',
      'reset_link_sent_to': 'تم إرسال رابط إعادة التعيين إلى',
      'remember_password': 'تتذكر كلمة المرور؟ ',
      'dont_receive_otp': 'لم تستلم رمز OTP؟ ',
      'verify': 'تحقق',
      'unaccounted': 'غير محاسب عليها',
// OIIAX Pro
      'blockatie_pro': 'OIIAX برو',
      'blockatie_pro_description': 'OIIAX برو يحجب الإعلانات والمتتبعين.',
      'error_loading_packages': 'خطأ في تحميل الحزم',
      'no_packages_available': 'لا توجد حزم متاحة',
      'check_back_later_packages': 'تحقق لاحقاً للحزم المتاحة.',
      'could_not_open_whatsapp': 'لا يمكن فتح واتساب',
      'error_opening_whatsapp': 'خطأ في فتح واتساب:',
      'blockatie_pro_help_content':
          'تحتاج مساعدة في حزم OIIAX برو؟ اتصل بفريق الدعم عبر واتساب للمساعدة.',

// Package Card Widget
      'in_just': 'فقط بـ',
      'get_in_touch_about': 'تواصل بخصوص',
      'open_whatsapp': 'افتح واتساب',
      'price': 'السعر',
      'package_features': 'ميزات الباقة',
      'contact_via_whatsapp': 'تواصل عبر واتساب',
      'features': 'الميزات',
      'description': 'الوصف',
      'package_details': 'تفاصيل الباقة',
      'premium_package': 'باقة بريميوم',
      'get_started_with_package': 'ابدأ مع الباقة',
      'rank': 'التقيم',
      'client_rating': 'تقييم العميل',
      'average_rating': 'متوسط التقييم',
      'loading_rating': 'جاري تحميل التقييم...',
      'error_loading_rating': 'خطأ في تحميل التقييم',
      'deposit': 'إيداع',
      'transaction': 'معاملة',
      'approved': 'موافق عليه',
      'rejected': 'مرفوض',
      'cash': 'نقداً',
      'bank_transfer': 'تحويل بنكي',
      'requested_at': 'تاريخ الشحنة',
      'withdrawal_method': 'طريقة السحب',
      'account_details': 'تفاصيل الحساب',
      'logout_confirmation': 'هل أنت متأكد من تسجيل الخروج',
      'yes_logout': 'نعم، تسجيل الخروج',
      'client': 'عميل',

// Notifications
      'enable_notifications': 'تفعيل الإشعارات',
      'not_now': 'ليس الآن',
      'enable': 'تفعيل',
      'new_notification': 'إشعار جديد',
      'set_time': 'تعيين الوقت',

// Language
      'language': 'اللغة',
      'select_language': 'اختر اللغة',
      'english': 'English',
      'arabic': 'العربية',
      'select_driver': 'اختيار سائق',
// Errors
      'login_failed': 'فشل تسجيل الدخول',
      'login_error': 'خطأ في تسجيل الدخول',
      'unable_make_call': 'غير قادر على إجراء مكالمة هاتفية',
      'language_changed': 'تم تغيير اللغة إلى',
      'failed_change_language': 'فشل في تغيير اللغة:',
      'language_changed_successfully': 'تم تغيير اللغة بنجاح!',
      'restart_app_for_full_change':
          'يرجى إعادة تشغيل التطبيق لتفعيل تغيير اللغة بالكامل.',
      'later': 'لاحقاً',
      'restart_now': 'إعادة التشغيل الآن',
      'name_client': 'اسم صاحب المتجر',
      'client_password': 'كلمة مرور صاحب المتجر',
      'phone_client': 'هاتف صاحب المتجر',
      'location_client': 'موقع صاحب المتجر',
      'view_and_manage_your_account_profile': 'عرض وإدارة ملف حسابك الشخصي',
      'logged_out_successfully': 'تم تسجيل الخروج بنجاح',
      'failed_to_logout': 'فشل في تسجيل الخروج',
      'deleting_account': 'جاري حذف الحساب',
      'user_id_not_found': 'لم يتم العثور على معرف المستخدم',
      'please_login_again': 'يرجى تسجيل الدخول مرة أخرى',
      'failed_to_delete_account': 'فشل في حذف الحساب',
      'shipment_accepted': 'تم قبول الشحنة!',
      'shipment_accepted_successfully': 'تم قبول الشحنة بنجاح',
      'confirmation_receipt': 'تأكيد الاستلام',
      'are_you_sure_you_want_receipt_shipment':
          'هل أنت متأكد أنك تريد استلام هذه الشحنة؟',
// Hub Page
      'hub_title':
          '\u0623\u0647\u0644\u0627\u064b \u0628\u0639\u0648\u062f\u062a\u0643',
      'hub_subtitle':
          '\u0647\u0630\u0627 \u0645\u0644\u062e\u0635 \u0645\u062a\u062c\u0631\u0643 \u0627\u0644\u064a\u0648\u0645',
      'hub_welcome_back':
          '\u0623\u0647\u0644\u0627\u064b \u0628\u0639\u0648\u062f\u062a\u0643',
      'hub_everything_in_one_place':
          '\u0645\u0644\u062e\u0635 \u0623\u062f\u0648\u0627\u062a \u0627\u0644\u0645\u062a\u062c\u0631 \u0648\u0627\u0644\u0639\u0645\u0644\u064a\u0627\u062a',
      'hub_main':
          '\u0625\u062c\u0631\u0627\u0621\u0627\u062a \u0633\u0631\u064a\u0639\u0629',
      'hub_operations':
          '\u0623\u062f\u0648\u0627\u062a \u0627\u0644\u0634\u062d\u0646',
      'hub_more_tools':
          '\u0623\u062f\u0648\u0627\u062a \u0625\u0636\u0627\u0641\u064a\u0629',
      'hub_manage_store':
          '\u062a\u0646\u0642\u0644 \u0633\u0631\u064a\u0639 \u0628\u064a\u0646 \u0635\u0641\u062d\u0627\u062a \u0627\u0644\u0645\u062a\u062c\u0631 \u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629',
      'hub_track_orders':
          '\u0627\u0641\u062a\u062d \u0627\u0644\u0634\u062d\u0646\u0627\u062a \u0648\u0627\u0644\u0639\u0645\u0644\u064a\u0627\u062a \u0627\u0644\u064a\u0648\u0645\u064a\u0629 \u0628\u0633\u0631\u0639\u0629',
      'hub_quick_access':
          '\u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062a \u0648\u0627\u0644\u0625\u0639\u062f\u0627\u062f\u0627\u062a \u0648\u0627\u0644\u0644\u063a\u0629 \u0648\u062e\u064a\u0627\u0631\u0627\u062a \u0627\u0644\u062d\u0633\u0627\u0628',
      'hub_open': '\u062c\u0627\u0647\u0632',
      'hub_membership': '\u0627\u0644\u0627\u0634\u062a\u0631\u0627\u0643',
      'hub_home_subtitle':
          '\u0627\u0641\u062a\u062d \u0627\u0644\u0635\u0641\u062d\u0629 \u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629 \u0648\u0646\u0638\u0631\u0629 \u0627\u0644\u0645\u062a\u062c\u0631 \u0627\u0644\u0639\u0627\u0645\u0629',
      'hub_my_store_subtitle':
          '\u0631\u0627\u062c\u0639 \u0645\u0644\u0641 \u0627\u0644\u0645\u062a\u062c\u0631 \u0648\u062a\u0641\u0627\u0635\u064a\u0644\u0647',
      'hub_wallet_subtitle':
          '\u0631\u0627\u062c\u0639 \u0627\u0644\u0631\u0635\u064a\u062f \u0648\u0637\u0644\u0628\u0627\u062a \u0627\u0644\u0633\u062d\u0628',
      'hub_profile_subtitle':
          '\u062d\u062f\u0651\u062b \u0628\u064a\u0627\u0646\u0627\u062a \u0627\u0644\u062d\u0633\u0627\u0628 \u0648\u0627\u0644\u0645\u062a\u062c\u0631',
      'hub_all_shipments_subtitle':
          '\u0627\u0633\u062a\u0639\u0631\u0636 \u062c\u0645\u064a\u0639 \u0627\u0644\u0634\u062d\u0646\u0627\u062a \u0627\u0644\u062d\u0627\u0644\u064a\u0629 \u0648\u0627\u0644\u0633\u0627\u0628\u0642\u0629',
      'hub_instant_shipments_subtitle':
          '\u0627\u0641\u062a\u062d \u0627\u0644\u0634\u062d\u0646\u0627\u062a \u0627\u0644\u0641\u0648\u0631\u064a\u0629 \u0627\u0644\u0645\u062a\u0627\u062d\u0629',
      'hub_add_shipment_subtitle':
          '\u0623\u0646\u0634\u0626 \u0634\u062d\u0646\u0629 \u062c\u062f\u064a\u062f\u0629 \u0644\u0645\u062a\u062c\u0631\u0643',
      'conversations': '\u0627\u0644\u0645\u062d\u0627\u062f\u062b\u0627\u062a',
      'hub_conversations_subtitle':
          '\u0631\u0627\u062c\u0639 \u0645\u062d\u0627\u062f\u062b\u0627\u062a \u0627\u0644\u062f\u0639\u0645 \u0648\u0627\u0644\u0634\u062d\u0646\u0627\u062a',
      'chat_no_conversations':
          '\u0644\u0627 \u062a\u0648\u062c\u062f \u0645\u062d\u0627\u062f\u062b\u0627\u062a \u062d\u062a\u0649 \u0627\u0644\u0622\u0646',
      'chat_no_conversations_description':
          '\u0633\u062a\u0638\u0647\u0631 \u0647\u0646\u0627 \u0645\u062d\u0627\u062f\u062b\u0627\u062a \u0627\u0644\u062f\u0639\u0645 \u0648\u0627\u0644\u0634\u062d\u0646\u0627\u062a.',
      'chat_unable_load_conversations':
          '\u062a\u0639\u0630\u0631 \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0645\u062d\u0627\u062f\u062b\u0627\u062a. \u062d\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062e\u0631\u0649.',
      'chat_unable_load_conversations_description':
          'تحقق من الاتصال بالإنترنت، ثم حدّث الصفحة لإظهار آخر المحادثات.',
      'chat_session_expired':
          '\u0627\u0646\u062a\u0647\u062a \u0627\u0644\u062c\u0644\u0633\u0629. \u064a\u0631\u062c\u0649 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644 \u0645\u062c\u062f\u062f\u0627\u064b.',
      'chat_session_expired_description':
          'سجّل الدخول مرة أخرى للوصول إلى محادثات الدعم والشحنات.',
      'chat_start_conversation':
          '\u0627\u0628\u062f\u0623 \u0645\u062d\u0627\u062f\u062b\u0629',
      'chat_open_shipment_failed': 'تعذر فتح محادثة الشحنة. حاول مرة أخرى.',
      'chat_shipment_number':
          '\u0631\u0642\u0645 \u0627\u0644\u0634\u062d\u0646\u0629',
      'chat_unread_message':
          '\u0631\u0633\u0627\u0644\u0629 \u063a\u064a\u0631 \u0645\u0642\u0631\u0648\u0621\u0629',
      'chat_unread_messages':
          '\u0631\u0633\u0627\u0626\u0644 \u063a\u064a\u0631 \u0645\u0642\u0631\u0648\u0621\u0629',
      'chat_yesterday': '\u0623\u0645\u0633',
      'chat_placeholder_message':
          '\u0633\u062a\u062a\u0648\u0641\u0631 \u0648\u0627\u062c\u0647\u0629 \u0627\u0644\u0645\u0631\u0627\u0633\u0644\u0629 \u0647\u0646\u0627 \u0642\u0631\u064a\u0628\u0627\u064b.',
      'chat_type_message':
          '\u0627\u0643\u062a\u0628 \u0631\u0633\u0627\u0644\u062a\u0643',
      'chat_send': '\u0625\u0631\u0633\u0627\u0644',
      'chat_sending':
          '\u062c\u0627\u0631\u064a \u0627\u0644\u0625\u0631\u0633\u0627\u0644',
      'chat_message_failed':
          '\u062a\u0639\u0630\u0631 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0631\u0633\u0627\u0644\u0629',
      'chat_retry':
          '\u0625\u0639\u0627\u062f\u0629 \u0627\u0644\u0645\u062d\u0627\u0648\u0644\u0629',
      'chat_start_support_conversation':
          '\u0627\u0628\u062f\u0623 \u0627\u0644\u0645\u062d\u0627\u062f\u062b\u0629 \u0645\u0639 \u0641\u0631\u064a\u0642 \u0627\u0644\u062f\u0639\u0645',
      'chat_new_messages':
          '\u0631\u0633\u0627\u0626\u0644 \u062c\u062f\u064a\u062f\u0629',
      'chat_access_denied':
          '\u0644\u0627 \u064a\u0645\u0643\u0646\u0643 \u0627\u0644\u0648\u0635\u0648\u0644 \u0625\u0644\u0649 \u0647\u0630\u0647 \u0627\u0644\u0645\u062d\u0627\u062f\u062b\u0629',
      'chat_rate_limited':
          '\u062a\u0645 \u0625\u0631\u0633\u0627\u0644 \u0631\u0633\u0627\u0626\u0644 \u0643\u062b\u064a\u0631\u0629\u060c \u062d\u0627\u0648\u0644 \u0628\u0639\u062f \u0642\u0644\u064a\u0644',
      'chat_loading_messages':
          '\u062c\u0627\u0631\u064a \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0631\u0633\u0627\u0626\u0644',
      'chat_load_older_messages':
          '\u062a\u062d\u0645\u064a\u0644 \u0631\u0633\u0627\u0626\u0644 \u0623\u0642\u062f\u0645',
      'chat_today': '\u0627\u0644\u064a\u0648\u0645',
      'chat_unable_load_messages':
          '\u062a\u0639\u0630\u0631 \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0631\u0633\u0627\u0626\u0644',
      'chat_message_required':
          '\u064a\u0631\u062c\u0649 \u0643\u062a\u0627\u0628\u0629 \u0631\u0633\u0627\u0644\u0629',
      'chat_my_message': '\u0631\u0633\u0627\u0644\u062a\u0643',
      'chat_support_message':
          '\u0631\u0633\u0627\u0644\u0629 \u0627\u0644\u062f\u0639\u0645',
      'chat_read':
          '\u062a\u0645\u062a \u0627\u0644\u0642\u0631\u0627\u0621\u0629',
      'chat_read_at':
          '\u062a\u0645\u062a \u0627\u0644\u0642\u0631\u0627\u0621\u0629 \u0639\u0646\u062f',
      'hub_support_subtitle':
          '\u062a\u0648\u0627\u0635\u0644 \u0645\u0639 \u0627\u0644\u062f\u0639\u0645 \u0628\u0633\u0631\u0639\u0629',
      'hub_notifications_subtitle':
          '\u0631\u0627\u062c\u0639 \u0627\u0644\u062a\u0646\u0628\u064a\u0647\u0627\u062a \u0648\u0627\u0644\u062a\u062d\u062f\u064a\u062b\u0627\u062a \u0627\u0644\u0645\u0647\u0645\u0629',
      'hub_settings_subtitle':
          '\u062d\u062f\u0651\u062b \u0625\u0639\u062f\u0627\u062f\u0627\u062a \u0627\u0644\u062d\u0633\u0627\u0628 \u0648\u0627\u0644\u0645\u062a\u062c\u0631',
      'hub_logout_subtitle':
          '\u0633\u062c\u0644 \u0627\u0644\u062e\u0631\u0648\u062c \u0645\u0646 \u0647\u0630\u0627 \u0627\u0644\u062c\u0647\u0627\u0632 \u0628\u0623\u0645\u0627\u0646',
      'hub_pro_subtitle':
          '\u0631\u0627\u062c\u0639 \u0623\u062f\u0648\u0627\u062a \u0627\u0644\u0627\u0634\u062a\u0631\u0627\u0643 \u0648\u0627\u0644\u062a\u0631\u0642\u064a\u0629',
      'hub_language_english': 'English',
      'hub_language_arabic': '\u0627\u0644\u0639\u0631\u0628\u064a\u0629',
      'main': 'الرئيسي',
      'pages': 'الصفحات',
      'details': 'التفاصيل',
      'personal_details': 'المعلومات الشخصية',
      'order_details': 'تفاصيل الشحنة',
      'placed_on': 'تم الطلب في',
      'edit_accounts': 'تعديل المعلومات الشخصية',
      'user_preferences': 'تفضيلات المستخدم',
      'app_settings': 'إعدادات التطبيق',
      'customize_preferences_and_app_settings':
          'تخصيص التفضيلات وإعدادات التطبيق.',
      'loading_profile_data': 'جاري تحميل بيانات الملف الشخصي...',
      'updating': 'جاري التحديث...',
      'update_profile': 'تحديث الملف الشخصي',
      'support_and_assistance': 'الدعم والمساعدة',
      'get_help_and_customer_support': 'احصل على المساعدة والدعم للعملاء',
      'please_enter_your_phone_number': 'يرجى إدخال رقم هاتفك',
      'please_enter_your_email': 'يرجى إدخال بريدك الإلكتروني',
      'please_enter_a_valid_email': 'يرجى إدخال بريد إلكتروني صحيح',
      'please_enter_your_message': 'يرجى إدخال رسالتك',
      'sending': 'جاري الإرسال...',
      'withdrawal_alert': 'تنبيه السحب',
      'withdrawal_alert_desc': 'هل تريد إجراء العملية',
// Location Order & Picker
      'location_order': 'طلب الموقع',
      'custom_order_for_visiting_locations': 'طلب مخصص لزيارة المواقع.',
      'new_order': 'طلب جديد!',
      'order_distance': 'مسافة الشحنة',
      'track_order': 'تتبع الشحنة',
      'track_driver': 'تتبع السائق',

      'call_customer': 'اتصال بالعميل',
      'select_location': 'اختر الموقع',
      'tap_on_map_to_select_your_location': 'انقر على الخريطة لاختيار موقعك',
      'location_selected': 'تم اختيار الموقع',
      'selected_location': 'الموقع المختار',
      'getting_address': 'جاري الحصول على العنوان...',
      'tap_on_map_to_select_location': 'انقر على الخريطة لاختيار الموقع',
      'coordinates': 'الإحداثيات',
      'confirm_location': 'تأكيد الموقع',
      'choose_from_predefined_locations_or_enter_coordinates':
          'اختر من المواقع المعرفة مسبقاً أو أدخل الإحداثيات',
      'predefined_locations': 'المواقع المعرفة مسبقاً',
      'custom_coordinates': 'إحداثيات مخصصة',
      'latitude': 'خط العرض',
      'longitude': 'خط الطول',
      'address_optional': 'العنوان (اختياري)',
      'enter_address_or_leave_empty_to_auto_detect':
          'أدخل العنوان أو اتركه فارغاً للكشف التلقائي',
      'custom_location': 'موقع مخصص',
      'please_enter_valid_coordinates': 'يرجى إدخال إحداثيات صحيحة',
      'get_address': 'الحصول على العنوان',

// My Store Page
      'store_profile': 'ملف المتجر',
      'owner': 'المالك',
      'no_store_information': 'لا توجد معلومات عن المتجر',
      'store_statistics': 'إحصائيات المتجر',
      'total_orders': 'إجمالي الشحنات',
      'active_orders': 'الشحنات النشطة',
      'revenue': 'الإيرادات',
      'rating': 'التقييم',
      'recent_activity': 'النشاط الأخير',
      'new_order_received': 'تم استلام طلب جديد',
      'order_from_customer': 'طلب من العميل',
      'product_updated': 'تم تحديث المنتج',
      'product_price_updated': 'تم تحديث سعر المنتج',
      'payment_received': 'تم استلام الدفع',
      'payment_amount_received': 'تم استلام مبلغ الدفع',
      'hours_ago': 'ساعات مضت',
      'day_ago': 'يوم مضى',

// Notifications Page
      'notifications_title': 'الإشعارات',
      'notifications_subtitle': 'آخر تحديثات متجرك وشحناتك',
      'notifications_empty_title': 'لا توجد إشعارات حالياً',
      'notifications_empty_message':
          'سنخبرك هنا عند وصول تحديثات جديدة لمتجرك.',
      'notifications_loading_title': 'جارٍ تحميل الإشعارات...',
      'notifications_loading_message': 'يرجى الانتظار لحظات.',
      'notifications_retry': 'حاول مرة أخرى',
      'notifications_network_error':
          'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.',
      'notifications_timeout_error':
          'استغرق الاتصال وقتاً أطول من المتوقع. حاول مرة أخرى.',
      'notifications_unauthorized_error':
          'انتهت الجلسة أو لم تعد صالحة. يرجى تسجيل الدخول مرة أخرى.',
      'notifications_server_error': 'حدث خطأ مؤقت في الخادم. حاول لاحقاً.',
      'notifications_generic_error': 'تعذر تحميل الإشعارات. حاول مرة أخرى.',
      'notifications_today': 'اليوم',
      'notifications_yesterday': 'أمس',
      'notifications_minute_ago': 'منذ دقيقة',
      'notifications_minutes_ago': 'دقائق',
      'notifications_hour_ago': 'منذ ساعة',
      'notifications_hours_ago': 'ساعات',
      'notifications_unread': 'غير مقروء',
      'notifications_read': 'مقروء',
      'notifications_total': 'الإجمالي',
      'notifications_latest': 'آخر تنبيهات المتجر والتحديثات المهمة',
      'notifications_open_order': 'فتح الشحنة',
      'notifications_new': 'جديد',
      'notifications_mark_read_failed': 'تعذر تحديد الإشعار كمقروء.',
      'notifications_no_message': 'لديك إشعار جديد.',
      'app_alerts_for_key_information': 'تنبيهات التطبيق للمعلومات المهمة',
      'no_notifications_found': 'لم يتم العثور على إشعارات',
      'just_now': 'الآن فقط',
      'min_ago': 'دقيقة مضت',
      'hr_ago': 'ساعة',
      's': 'ساعات',
      'd_ago': 'يوم مضى',

// Order Management
      'order_delivery': 'تسليم الشحنة',
      'order_creation_date': 'تاريخ إنشاء الشحنة:',
      'cancel_order': 'إلغاء الشحنة',
      'accept_at_first': 'قبول على الفور',
      'loing_for_driver': 'يبحث عن سائق',
      'no_location': 'لا يوجد موقع',
      'help': 'مساعدة؟',
      'placed_on_date': 'تم الطلب في 12 فبراير 2025، 05:30 مساءً',
      'call_driver': 'اتصل بالسائق',

// Month Names
      'jan': 'يناير',
      'feb': 'فبراير',
      'mar': 'مارس',
      'apr': 'أبريل',
      'may': 'مايو',
      'jun': 'يونيو',
      'jul': 'يوليو',
      'aug': 'أغسطس',
      'sep': 'سبتمبر',
      'oct': 'أكتوبر',
      'nov': 'نوفمبر',
      'dec': 'ديسمبر',

// Store & Delivery Details
      'client_details': 'تفاصيل العميل',
      'driver_details': 'تفاصيل السائق',
      'store_name_not_available': 'اسم المتجر غير متوفر',
      'address_not_available': 'العنوان غير متوفر',
      'driver_name_not_available': 'اسم السائق غير متوفر',
      'phone_not_available': 'الهاتف غير متوفر',

// Driver Location Map
      'driver_location': 'موقع السائق',
      'driver_current_location': 'الموقع الحالي للسائق',

// Day Suffixes
      'st': 'أول',
      'nd': 'ثاني',
      'rd': 'ثالث',
      'th': 'رابع',

// Status Names for Comparison
      'dispatched': 'تم الإرسال',
      'in_transit': 'في الطريق',
      'out_for_delivery': 'خارج للتسليم',
      'awaiting_pickup': 'في انتظار الاستلام',
      'failed_delivery': 'فشل في التسليم',

      'email_required': 'البريد الإلكتروني مطلوب',
      'phone_required': "رقم الهاتف مطلوب",
      'store_name_required': "اسم المتجر مطلوب",
      'client_name_required': "اسم العميل مطلوب",
      'shipment_note': "ملاحظة الشحنة",

      'driver_accounted': 'تمت المحاسبة عليها',
      'client_accounted': 'تمت المحاسبة عليها',
    },
  };

  static String getText(String key) {
    final currentLocale = AppLocalizations.currentLocale.languageCode;
    return _translations[currentLocale]?[key] ??
        _translations['en']?[key] ??
        key;
  }

  static String getTextWithLocale(String key, String locale) {
    return _translations[locale]?[key] ?? _translations['en']?[key] ?? key;
  }

  static Map<String, String> getAllTexts(String locale) {
    return _translations[locale] ?? _translations['en'] ?? {};
  }

  // خريطة الأخطاء وربطها بالمفاتيح بتاعة الترجمة
}
