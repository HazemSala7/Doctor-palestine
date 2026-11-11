import 'package:clinic_dr_alla/Pages/booking/booking_widgets.dart';
import 'package:clinic_dr_alla/data/booking.dart';
import 'package:flutter/material.dart';

/// Asks for the password, then deletes the doctor's account. Pops true once
/// the account is gone (and the doctor is signed out).
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _deleting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'أدخل كلمة المرور');
      return;
    }
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await DoctorApi.deleteAccount(_password.text);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.fieldErrors['password'] ?? e.message);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('حذف الحساب نهائياً؟'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'سيُحذف حساب الدخول والفيديوهات وفريق العمل الذي أضفته، '
              'ولا يمكن التراجع عن ذلك. للتأكيد أدخل كلمة المرور.'),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: fieldDecoration('كلمة المرور', error: _error),
            onSubmitted: (_) => _delete(),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: _deleting ? null : () => Navigator.pop(context, false),
            child: const Text('تراجع')),
        TextButton(
          onPressed: _deleting ? null : _delete,
          style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
          child: _deleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('حذف الحساب'),
        ),
      ],
    );
  }
}
