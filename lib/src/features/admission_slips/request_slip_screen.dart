import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../portal/portal_provider.dart';
import '../portal/portal_widgets.dart';
import 'admission_slips_provider.dart';
import 'slip_attachment.dart';

/// Request a Class Admission Slip for the selected attendance items.
class RequestSlipScreen extends ConsumerStatefulWidget {
  final List<String> itemKeys;
  const RequestSlipScreen({super.key, required this.itemKeys});

  @override
  ConsumerState<RequestSlipScreen> createState() => _RequestSlipScreenState();
}

class _RequestSlipScreenState extends ConsumerState<RequestSlipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  String? _attachmentType;
  SlipAttachment? _attachment;
  bool _submitting = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final name = file.name.contains('.') ? file.name : '${file.name}.jpg';
      setState(() => _attachment = SlipAttachment.fromBytes(name: name, bytes: bytes));
    } on FormatException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } catch (e) {
      if (mounted) showErrorSnack(context, friendlyError(e));
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );
      final picked = result?.files.single;
      if (picked == null || picked.bytes == null) return;
      setState(() => _attachment = SlipAttachment.fromBytes(name: picked.name, bytes: picked.bytes!));
    } on FormatException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } catch (e) {
      if (mounted) showErrorSnack(context, friendlyError(e));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref.read(admissionSlipsRepositoryProvider).submit(
            itemKeys: widget.itemKeys,
            reason: _reason.text.trim(),
            attachmentType: _attachmentType,
            documentDataUri: _attachment?.dataUri,
          );
      ref.invalidate(admissionSlipsProvider);
      ref.invalidate(portalDashboardProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent to the Registrar')),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) showErrorSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => PortalSubScreen(
        title: 'Request Admission Slip',
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Text('${widget.itemKeys.length} item(s) selected', style: AppTextStyles.cardTitle),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reason,
                maxLength: 255,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'e.g. I had a fever and stayed home',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please tell the Registrar why you were absent, late or out of class.'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _attachmentType,
                decoration: const InputDecoration(
                  labelText: 'Supporting document (optional)',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('None')),
                  DropdownMenuItem(value: 'medical_certificate', child: Text('Medical Certificate')),
                  DropdownMenuItem(value: 'parent_letter', child: Text('Letter from parent/guardian')),
                ],
                onChanged: (v) => setState(() => _attachmentType = v),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_rounded, size: 18),
                    label: const Text('Take photo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.image_rounded, size: 18),
                    label: const Text('Choose photo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickPdf,
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('Choose PDF'),
                  ),
                ],
              ),
              if (_attachment != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.attach_file_rounded, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(_attachment!.name, style: AppTextStyles.caption)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _attachment = null),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.accent, minimumSize: const Size.fromHeight(48)),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Request'),
              ),
            ],
          ),
        ),
      );
}
