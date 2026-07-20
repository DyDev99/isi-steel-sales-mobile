import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Pushed by [SpeechVoiceSearchService]. Listens on-device via `speech_to_text`
/// and pops with the recognized query string, or `null` if the user cancels,
/// says nothing, or the device has no speech recognition available.
class VoiceSearchScreen extends StatefulWidget {
  const VoiceSearchScreen({super.key});

  @override
  State<VoiceSearchScreen> createState() => _VoiceSearchScreenState();
}

class _VoiceSearchScreenState extends State<VoiceSearchScreen> {
  final SpeechToText _speech = SpeechToText();

  String _words = '';
  bool _listening = false;
  bool _finished = false; // guards against popping twice
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final available = await _speech.initialize(
        onStatus: _onStatus,
        onError: (e) => _onError(e.errorMsg),
      );
      if (!mounted) return;
      if (!available) {
        setState(
            () => _error = 'Voice search isn\'t available on this device.');
        return;
      }
      await _startListening();
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn\'t start voice search.');
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _words = '';
      _error = null;
      _listening = true;
    });
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _words = result.recognizedWords);
        if (result.finalResult) _accept();
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  void _onStatus(String status) {
    if (!mounted) return;
    final stopped = status == 'done' || status == 'notListening';
    if (stopped) {
      if (_words.trim().isNotEmpty) {
        _accept();
      } else {
        setState(() => _listening = false);
      }
    }
  }

  void _onError(String message) {
    if (!mounted || _finished) return;
    setState(() {
      _listening = false;
      _error = message.contains('no match') || message.contains('timeout')
          ? 'Didn\'t catch that. Tap the mic to try again.'
          : 'Voice search error. Tap the mic to try again.';
    });
  }

  void _accept() {
    if (_finished) return;
    _finished = true;
    final query = _words.trim();
    _speech.stop();
    if (mounted) Navigator.of(context).pop(query.isEmpty ? null : query);
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text('Voice Search',
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                _listening ? 'Listening…' : (_error ?? 'Tap the mic to start'),
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _listening ? _accept : _startListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _listening ? primaryColor : colors.surfaceSoft,
                    border: Border.all(color: primaryColor, width: 3),
                    boxShadow: _listening
                        ? [
                            BoxShadow(
                                color: primaryColor.withValues(alpha: 0.4),
                                blurRadius: 28,
                                spreadRadius: 6)
                          ]
                        : null,
                  ),
                  child: Icon(
                    _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: _listening ? Colors.white : primaryColor,
                    size: 46,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _words.isEmpty
                    ? 'Say a product name, e.g. "12mm rebar"'
                    : _words,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _words.isEmpty
                      ? colors.textSecondary
                      : colors.textPrimary,
                  fontSize: _words.isEmpty ? 13 : 18,
                  fontWeight:
                      _words.isEmpty ? FontWeight.w400 : FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_words.trim().isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _accept,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
