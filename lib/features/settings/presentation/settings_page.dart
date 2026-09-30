import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/friendly_error.dart';
import '../../../core/providers.dart';
import '../../../data/remote/content_api_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../discover/application/discover_notifier.dart';
import '../../my_list/application/my_list_notifier.dart';
import '../../series_detail/application/series_detail_notifier.dart';
import '../../shorts/application/shorts_feed_notifier.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _urlController = TextEditingController();
  ContentApiSourceStatus? _status;
  String? _error;
  bool _loading = true;
  bool _checking = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final url = await ref.read(contentApiClientProvider).configuredBaseUrl;
    if (!mounted) return;
    _urlController.text = url ?? '';
    setState(() => _loading = false);
  }

  Future<void> _checkConnection() async {
    setState(() {
      _checking = true;
      _error = null;
      _status = null;
    });
    try {
      final status = await ref.read(contentApiClientProvider).checkConnection(
            baseUrl: _urlController.text,
          );
      if (!mounted) return;
      setState(() => _status = status);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final client = ref.read(contentApiClientProvider);
      // Saving always verifies the URL afresh. A previous successful test
      // must not make a later, changed URL look valid.
      final status = await client.checkConnection(baseUrl: _urlController.text);
      await client.saveBaseUrl(_urlController.text);
      _urlController.text = (await client.configuredBaseUrl) ?? '';
      _invalidateContent();
      if (mounted) {
        setState(() => _status = status);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.saved)),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _restoreDefault() async {
    final client = ref.read(contentApiClientProvider);
    await client.clearSavedBaseUrl();
    _urlController.text = client.defaultBaseUrl ?? '';
    _invalidateContent();
    if (mounted) setState(() => _status = null);
  }

  void _invalidateContent() {
    ref.read(contentApiClientProvider).invalidate();
    ref.invalidate(contentApiClientProvider);
    ref.invalidate(seriesRepositoryProvider);
    ref.invalidate(episodeRepositoryProvider);
    ref.invalidate(videoSourceProvider);
    ref.invalidate(discoverNotifierProvider);
    ref.invalidate(shortsFeedNotifierProvider);
    ref.invalidate(myListNotifierProvider);
    ref.invalidate(seriesDetailNotifierProvider);
  }

  String _messageFor(Object error) {
    return localizedFriendlyErrorFor(context, error).message;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.contentSource,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(l10n.contentApiServer),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'https://example.vercel.app',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _checking ? null : _checkConnection,
                  child: _checking
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.testConnection),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.save),
                ),
              ),
            ],
          ),
          if (ref.read(contentApiClientProvider).defaultBaseUrl != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _restoreDefault,
              child: Text(l10n.restoreDefault),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          _StatusCard(status: _status),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  final ContentApiSourceStatus? status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (status == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.cloud_off),
        title: Text(l10n.serverStatus),
        subtitle: Text(l10n.notConfigured),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cloud_done, color: Colors.green),
              title: Text(l10n.serverStatus),
              subtitle: Text(l10n.active),
            ),
            if (status!.language != null)
              Text('${l10n.language}: ${status!.language}'),
            const SizedBox(height: 8),
            Text(l10n.providers),
            ...status!.providers.map(
              (provider) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  provider.available ? Icons.check_circle : Icons.cancel,
                  color: provider.available ? Colors.green : Colors.grey,
                ),
                title: Text(provider.name),
                trailing: Text(
                  provider.available ? l10n.active : l10n.unavailable,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
