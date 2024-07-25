import 'package:flutter/material.dart';
import 'package:google_apis_test/chat_view/src/models/suggestion_item_data.dart';

import 'suggestion_item_config.dart';
import 'suggestion_list_config.dart';

class ReplySuggestionsConfig {
  final SuggestionItemConfig? itemConfig;
  final SuggestionListConfig? listConfig;
  final ValueSetter<SuggestionItemData>? onTap;
  final bool autoDismissOnSelection;

  const ReplySuggestionsConfig({
    this.listConfig,
    this.itemConfig,
    this.onTap,
    this.autoDismissOnSelection = true,
  });
}
