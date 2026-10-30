import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/integrations/nova_ci_run_status.dart';

void main() {
  group('NovaCiRunStatus.fromGitHub', () {
    test('only a completed success is verified green', () {
      final result = NovaCiRunStatus.fromGitHub(
        status: 'completed',
        conclusion: 'success',
      );

      expect(result.state, NovaCiRunState.succeeded);
      expect(result.isVerifiedSuccess, isTrue);
      expect(result.label, 'نجاح مثبت');
    });

    test('queued and running jobs are never reported as successful', () {
      for (final status in ['queued', 'requested', 'waiting', 'pending']) {
        final result = NovaCiRunStatus.fromGitHub(
          status: status,
          conclusion: '',
        );
        expect(result.state, NovaCiRunState.queued, reason: status);
        expect(result.isVerifiedSuccess, isFalse, reason: status);
      }

      final running = NovaCiRunStatus.fromGitHub(
        status: 'in_progress',
        conclusion: '',
      );
      expect(running.state, NovaCiRunState.running);
      expect(running.isVerifiedSuccess, isFalse);
    });

    test('failure, timeout, cancellation and skipped are not green', () {
      final cases = <String, NovaCiRunState>{
        'failure': NovaCiRunState.failed,
        'timed_out': NovaCiRunState.failed,
        'action_required': NovaCiRunState.failed,
        'cancelled': NovaCiRunState.cancelled,
        'skipped': NovaCiRunState.skipped,
      };

      for (final entry in cases.entries) {
        final result = NovaCiRunStatus.fromGitHub(
          status: 'completed',
          conclusion: entry.key,
        );
        expect(result.state, entry.value, reason: entry.key);
        expect(result.isVerifiedSuccess, isFalse, reason: entry.key);
      }
    });

    test('unknown or incomplete states fail closed', () {
      final result = NovaCiRunStatus.fromGitHub(
        status: 'completed',
        conclusion: 'some_new_github_state',
      );

      expect(result.state, NovaCiRunState.unknown);
      expect(result.isVerifiedSuccess, isFalse);
      expect(result.needsAttention, isTrue);
    });
  });
}
