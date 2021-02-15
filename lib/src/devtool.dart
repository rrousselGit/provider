// ignore_for_file: public_member_api_docs

part of 'provider.dart';

@immutable
class _ProviderNode {
  const _ProviderNode({
    @required this.id,
    @required this.childrenNodeIds,
    @required this.type,
    @required _InheritedProviderScopeElement element,
  }) : _element = element;

  final String id;
  final String type;
  final List<String> childrenNodeIds;
  final _InheritedProviderScopeElement _element;

  Object get value => _element._delegateState.value;
}

@protected
class ProviderBinding {
  ProviderBinding._();

  static final debugInstance = kDebugMode ? ProviderBinding._() : null;

  Map<String, _ProviderNode> _providerDetails = {};
  Map<String, _ProviderNode> get providerDetails => _providerDetails;
  set providerDetails(Map<String, _ProviderNode> value) {
    developer
        .postEvent('provider:providers_list_changed', <dynamic, dynamic>{});
    _providerDetails = value;
  }

  static String shortHash(Object obj) {
    return foundation.shortHash(obj);
  }

  void providerDidChange(String providerId) {
    developer.postEvent(
      'provider:provider_changed',
      <dynamic, dynamic>{'id': providerId},
    );
  }
}
