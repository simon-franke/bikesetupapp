import 'package:bikesetupapp/alert_dialogs/dialog_helpers.dart';
import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TodoAlerts {
  static Future<void> newTodo(
      BuildContext context, String bikeName, User user) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final partsCtrl = TextEditingController();
    return showDialog(
      context: context,
      builder: (ctx) {
        return WorkshopDialog(
          title: 'New task',
          content: _TodoForm(
            nameCtrl: nameCtrl,
            descCtrl: descCtrl,
            partsCtrl: partsCtrl,
          ),
          actions: [
            DialogSecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            DialogPrimaryButton(
              label: 'Add',
              onPressed: () {
                Navigator.of(ctx).pop();
                try {
                  DatabaseService(user.uid).setTodo(
                      bikeName, nameCtrl.text, descCtrl.text, partsCtrl.text);
                } catch (_) {
                  generalError(context, 'Error creating todo');
                }
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> editTodo(
      BuildContext context,
      String bikeName,
      String docId,
      User user,
      String taskName,
      String taskDescription,
      String partsNeeded,
      bool isDone) async {
    final nameCtrl = TextEditingController(text: taskName);
    final descCtrl = TextEditingController(text: taskDescription);
    final partsCtrl = TextEditingController(text: partsNeeded);
    return showDialog(
      context: context,
      builder: (ctx) {
        return WorkshopDialog(
          title: 'Edit task',
          content: _TodoForm(
            nameCtrl: nameCtrl,
            descCtrl: descCtrl,
            partsCtrl: partsCtrl,
            trailing: IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: context.palette.red),
              onPressed: () {
                Navigator.of(ctx).pop();
                try {
                  DatabaseService(user.uid).deleteTodo(bikeName, docId);
                } catch (_) {
                  generalError(context, 'Error deleting todo');
                }
              },
            ),
          ),
          actions: [
            DialogSecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            DialogPrimaryButton(
              label: 'Save',
              onPressed: () {
                Navigator.of(ctx).pop();
                try {
                  DatabaseService(user.uid).editTodo(bikeName, docId,
                      nameCtrl.text, descCtrl.text, partsCtrl.text, isDone);
                } catch (_) {
                  generalError(context, 'Error editing todo');
                }
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> generalError(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        return WorkshopDialog(
          title: 'Error',
          content: Text(message),
          actions: [
            DialogPrimaryButton(
              label: 'OK',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        );
      },
    );
  }
}

class _TodoForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final TextEditingController partsCtrl;
  final Widget? trailing;
  const _TodoForm({
    required this.nameCtrl,
    required this.descCtrl,
    required this.partsCtrl,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DialogTextField(controller: nameCtrl, hint: 'Task name'),
          const SizedBox(height: 10),
          _MultilineField(controller: descCtrl, hint: 'Task description'),
          const SizedBox(height: 10),
          DialogTextField(controller: partsCtrl, hint: 'Parts needed'),
          if (trailing != null) ...[
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: trailing),
          ],
        ],
      ),
    );
  }
}

class _MultilineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _MultilineField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TextField(
      controller: controller,
      minLines: 2,
      maxLines: 4,
      cursorColor: p.accent,
      style: AppTextStyles.inter(size: 13, color: p.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.inter(size: 13, color: p.inkDim),
        filled: true,
        fillColor: p.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.accent),
        ),
      ),
    );
  }
}
