import 'dart:js_interop';

@JS('showRecaptchaContainer')
external void _showRecaptchaContainer();

@JS('hideRecaptchaContainer')
external void _hideRecaptchaContainer();

void showRecaptcha() {
  try {
    _showRecaptchaContainer();
  } catch (_) {}
}

void hideRecaptcha() {
  try {
    _hideRecaptchaContainer();
  } catch (_) {}
}
