import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @welcome_back.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcome_back;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @log_in_to_access_your_account.
  ///
  /// In en, this message translates to:
  /// **'Log in to access your account'**
  String get log_in_to_access_your_account;

  /// No description provided for @job_number.
  ///
  /// In en, this message translates to:
  /// **'Job Number'**
  String get job_number;

  /// No description provided for @please_enter_your_job_number.
  ///
  /// In en, this message translates to:
  /// **'Please enter your job number'**
  String get please_enter_your_job_number;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @please_enter_your_password.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get please_enter_your_password;

  /// No description provided for @remember_me.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get remember_me;

  /// No description provided for @forgot_your_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgot_your_password;

  /// No description provided for @employee_operations.
  ///
  /// In en, this message translates to:
  /// **'Employee Operations'**
  String get employee_operations;

  /// No description provided for @attendance_registration.
  ///
  /// In en, this message translates to:
  /// **'Attendance Registration'**
  String get attendance_registration;

  /// No description provided for @record_your_attendance_time.
  ///
  /// In en, this message translates to:
  /// **'Record your attendance time'**
  String get record_your_attendance_time;

  /// No description provided for @record_your_check_in_time.
  ///
  /// In en, this message translates to:
  /// **'Record your check-in time'**
  String get record_your_check_in_time;

  /// No description provided for @request_for_sick_leave.
  ///
  /// In en, this message translates to:
  /// **'Request for Sick Leave'**
  String get request_for_sick_leave;

  /// No description provided for @easily_request_sick_leave.
  ///
  /// In en, this message translates to:
  /// **'Easily request sick leave'**
  String get easily_request_sick_leave;

  /// No description provided for @request_for_exit_permit.
  ///
  /// In en, this message translates to:
  /// **'Request for Exit Permit'**
  String get request_for_exit_permit;

  /// No description provided for @submit_an_exit_permit_application.
  ///
  /// In en, this message translates to:
  /// **'Submit an exit permit application'**
  String get submit_an_exit_permit_application;

  /// No description provided for @confirm_logout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirm_logout;

  /// No description provided for @are_you_sure_you_want_to_log_out.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get are_you_sure_you_want_to_log_out;

  /// No description provided for @you_have_successfully_logged_in.
  ///
  /// In en, this message translates to:
  /// **'You have successfully logged in'**
  String get you_have_successfully_logged_in;

  /// No description provided for @fingerprint_login_successfully.
  ///
  /// In en, this message translates to:
  /// **'Logged in successfully with fingerprint'**
  String get fingerprint_login_successfully;

  /// No description provided for @attendance_recording_fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Attendance Recording - Fingerprint'**
  String get attendance_recording_fingerprint;

  /// No description provided for @register_attendance_using_your_fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Register attendance using your fingerprint'**
  String get register_attendance_using_your_fingerprint;

  /// No description provided for @fingerprint_verification.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint verification in progress...'**
  String get fingerprint_verification;

  /// No description provided for @click_to_register.
  ///
  /// In en, this message translates to:
  /// **'Click to register'**
  String get click_to_register;

  /// No description provided for @keep_your_finger_on_the_fingerprint_reader_until_verification_is_complete.
  ///
  /// In en, this message translates to:
  /// **'Keep your finger on the fingerprint reader until verification is complete.'**
  String
      get keep_your_finger_on_the_fingerprint_reader_until_verification_is_complete;

  /// No description provided for @place_your_finger_on_the_sensor_to_check_in.
  ///
  /// In en, this message translates to:
  /// **'Place your finger on the sensor to check-in'**
  String get place_your_finger_on_the_sensor_to_check_in;

  /// No description provided for @you_are_too_far_away.
  ///
  /// In en, this message translates to:
  /// **'You are too far away'**
  String get you_are_too_far_away;

  /// No description provided for @logout_fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Logout - Fingerprint'**
  String get logout_fingerprint;

  /// No description provided for @log_out_with_your_fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Log out with your fingerprint'**
  String get log_out_with_your_fingerprint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @you_have_successfully_logged_out.
  ///
  /// In en, this message translates to:
  /// **'You have successfully logged out'**
  String get you_have_successfully_logged_out;

  /// No description provided for @you_have_failed_to_log_in_please_try_again_later.
  ///
  /// In en, this message translates to:
  /// **'You have failed to log in, please try again later.'**
  String get you_have_failed_to_log_in_please_try_again_later;

  /// No description provided for @fingerprint_logout_successfully.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully with fingerprint'**
  String get fingerprint_logout_successfully;

  /// No description provided for @date_of_permission.
  ///
  /// In en, this message translates to:
  /// **'Date of Permission'**
  String get date_of_permission;

  /// No description provided for @select_the_permission_date.
  ///
  /// In en, this message translates to:
  /// **'Select the permission date'**
  String get select_the_permission_date;

  /// No description provided for @please_select_a_date_of_authorization.
  ///
  /// In en, this message translates to:
  /// **'Please select a date of authorization'**
  String get please_select_a_date_of_authorization;

  /// No description provided for @from_the_hour.
  ///
  /// In en, this message translates to:
  /// **'From the Hour'**
  String get from_the_hour;

  /// No description provided for @select_start_time.
  ///
  /// In en, this message translates to:
  /// **'Select start time'**
  String get select_start_time;

  /// No description provided for @please_select_a_start_time.
  ///
  /// In en, this message translates to:
  /// **'Please select a start time'**
  String get please_select_a_start_time;

  /// No description provided for @to_the_hour.
  ///
  /// In en, this message translates to:
  /// **'To the Hour'**
  String get to_the_hour;

  /// No description provided for @select_end_time.
  ///
  /// In en, this message translates to:
  /// **'Select end time'**
  String get select_end_time;

  /// No description provided for @please_select_an_end_time.
  ///
  /// In en, this message translates to:
  /// **'Please select an end time'**
  String get please_select_an_end_time;

  /// No description provided for @permission_description.
  ///
  /// In en, this message translates to:
  /// **'Permission Description'**
  String get permission_description;

  /// No description provided for @enter_permission_description.
  ///
  /// In en, this message translates to:
  /// **'Enter permission description'**
  String get enter_permission_description;

  /// No description provided for @please_enter_a_permission_description.
  ///
  /// In en, this message translates to:
  /// **'Please enter a permission description'**
  String get please_enter_a_permission_description;

  /// No description provided for @submit_request.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submit_request;

  /// No description provided for @request_sick_leave.
  ///
  /// In en, this message translates to:
  /// **'Request Sick Leave'**
  String get request_sick_leave;

  /// No description provided for @vacation_start_date.
  ///
  /// In en, this message translates to:
  /// **'Vacation Start Date'**
  String get vacation_start_date;

  /// No description provided for @select_start_date.
  ///
  /// In en, this message translates to:
  /// **'Select start date'**
  String get select_start_date;

  /// No description provided for @please_select_a_start_date.
  ///
  /// In en, this message translates to:
  /// **'Please select a start date'**
  String get please_select_a_start_date;

  /// No description provided for @vacation_end_date.
  ///
  /// In en, this message translates to:
  /// **'Vacation End Date'**
  String get vacation_end_date;

  /// No description provided for @select_end_date.
  ///
  /// In en, this message translates to:
  /// **'Select end date'**
  String get select_end_date;

  /// No description provided for @please_select_an_end_date.
  ///
  /// In en, this message translates to:
  /// **'Please select an end date'**
  String get please_select_an_end_date;

  /// No description provided for @contact_number_during_vacation.
  ///
  /// In en, this message translates to:
  /// **'Contact Number During Vacation'**
  String get contact_number_during_vacation;

  /// No description provided for @enter_contact_number.
  ///
  /// In en, this message translates to:
  /// **'Enter contact number'**
  String get enter_contact_number;

  /// No description provided for @please_enter_your_contact_number.
  ///
  /// In en, this message translates to:
  /// **'Please enter your contact number'**
  String get please_enter_your_contact_number;

  /// No description provided for @please_enter_a_valid_number.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get please_enter_a_valid_number;

  /// No description provided for @description_of_the_holiday.
  ///
  /// In en, this message translates to:
  /// **'Description of the Holiday'**
  String get description_of_the_holiday;

  /// No description provided for @enter_a_vacation_description.
  ///
  /// In en, this message translates to:
  /// **'Enter a vacation description'**
  String get enter_a_vacation_description;

  /// No description provided for @please_enter_a_description_of_the_leave.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description of the leave'**
  String get please_enter_a_description_of_the_leave;

  /// No description provided for @additional_notes.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes'**
  String get additional_notes;

  /// No description provided for @you_are_far_away.
  ///
  /// In en, this message translates to:
  /// **'you are far away'**
  String get you_are_far_away;

  /// No description provided for @meter_please_approach_the_site_to_register.
  ///
  /// In en, this message translates to:
  /// **'Meter. Please approach the site to register.'**
  String get meter_please_approach_the_site_to_register;

  /// No description provided for @the_exit_permission_request_has_been_added_successfully.
  ///
  /// In en, this message translates to:
  /// **'The exit permission request has been added successfully'**
  String get the_exit_permission_request_has_been_added_successfully;

  /// No description provided for @sick_leave_request_has_been_added_successfully.
  ///
  /// In en, this message translates to:
  /// **'Sick leave request has been added successfully'**
  String get sick_leave_request_has_been_added_successfully;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// No description provided for @employee_transactions.
  ///
  /// In en, this message translates to:
  /// **'Employee Transactions'**
  String get employee_transactions;

  /// No description provided for @see_employee_transactions.
  ///
  /// In en, this message translates to:
  /// **'See your transactions'**
  String get see_employee_transactions;

  /// No description provided for @no_transactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions found for this month'**
  String get no_transactions;

  /// No description provided for @check_in.
  ///
  /// In en, this message translates to:
  /// **'Check-In'**
  String get check_in;

  /// No description provided for @check_out.
  ///
  /// In en, this message translates to:
  /// **'Check-Out'**
  String get check_out;

  /// No description provided for @total_hours.
  ///
  /// In en, this message translates to:
  /// **'Total Hours'**
  String get total_hours;

  /// No description provided for @overtime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtime;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @status_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get status_completed;

  /// No description provided for @status_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get status_pending;

  /// No description provided for @status_rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get status_rejected;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @employee_attendance_record.
  ///
  /// In en, this message translates to:
  /// **'Employees Attendance Records'**
  String get employee_attendance_record;

  /// No description provided for @view_employee_attendance_and_leave_reports.
  ///
  /// In en, this message translates to:
  /// **'View employees attendance and leave reports'**
  String get view_employee_attendance_and_leave_reports;

  /// No description provided for @enter_notes.
  ///
  /// In en, this message translates to:
  /// **'Enter notes (optional)'**
  String get enter_notes;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
