import '../models/intent_context.dart';
import '../models/intent_result.dart';

abstract class IntentResolver {
  IntentResult resolve(IntentContext context);
}