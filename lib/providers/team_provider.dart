import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/repositories/team_repository.dart';
import '../api/api_client.dart';

final teamListProvider =
    StateNotifierProvider<TeamListNotifier, AsyncValue<List<dynamic>>>((ref) {
  return TeamListNotifier(TeamRepository(ApiClient()));
});

final memberListProvider =
    StateNotifierProvider<MemberListNotifier, AsyncValue<List<dynamic>>>((ref) {
  return MemberListNotifier(TeamRepository(ApiClient()));
});

final teamDetailProvider = StateNotifierProvider.family<TeamDetailNotifier,
    AsyncValue<Map<String, dynamic>>, String?>((ref, teamId) {
  return TeamDetailNotifier(TeamRepository(ApiClient()), teamId);
});

class TeamListNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final TeamRepository _teamRepository;

  TeamListNotifier(this._teamRepository) : super(const AsyncValue.loading());

  Future<void> fetchTeamList(String organizationId, String workspaceId,
      {String? searchText, bool isTreeView = false}) async {
    try {
      state = const AsyncValue.loading();
      final response = await _teamRepository
          .getTeamList(organizationId, workspaceId, isTreeView: isTreeView);
      state = AsyncValue.data(response['content'] ?? []);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteTeam(
      String organizationId, String workspaceId, String teamId) async {
    try {
      await _teamRepository.deleteTeam(organizationId, workspaceId, teamId, {});
      fetchTeamList(organizationId, workspaceId);
    } catch (error) {
      rethrow;
    }
  }
}

class TeamDetailNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final TeamRepository _teamRepository;
  final String? _teamId;

  TeamDetailNotifier(this._teamRepository, this._teamId)
      : super(const AsyncValue.loading());

  Future<void> fetchTeamDetail(
      String organizationId, String workspaceId) async {
    if (_teamId == null) {
      state = const AsyncValue.data({});
      return;
    }

    try {
      state = const AsyncValue.loading();
      final response =
          await _teamRepository.getTeamList(organizationId, workspaceId);
      final teams = response['content'] as List;
      final teamDetail = findTeamById(teams, _teamId!);
      state = AsyncValue.data(teamDetail ?? {});
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Map<String, dynamic>? findTeamById(List teams, String teamId) {
    for (var team in teams) {
      if (team['id'] == teamId) return team;
      if (team['childs'] != null) {
        final found = findTeamById(team['childs'], teamId);
        if (found != null) return found;
      }
    }
    return null;
  }
}

class MemberListNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final TeamRepository _teamRepository;

  MemberListNotifier(this._teamRepository) : super(const AsyncValue.loading());

  Future<void> fetchMemberList(
      String organizationId, String workspaceId, String teamId,
      {String? searchText}) async {
    try {
      state = const AsyncValue.loading();
      final response = await _teamRepository.getMemberListFromTeamId(
          organizationId, workspaceId, teamId);
      state = AsyncValue.data(response['content'] ?? []);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateMemberRole(
    String organizationId,
    String workspaceId,
    String teamId,
    String profileId,
    String role,
  ) async {
    try {
      await _teamRepository.updateMemberRole(
        organizationId,
        workspaceId,
        teamId,
        profileId,
        role,
      );
      await fetchMemberList(organizationId, workspaceId, teamId);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteMember(
    String organizationId,
    String workspaceId,
    String teamId,
    String profileId,
  ) async {
    try {
      await _teamRepository.deleteMemberFromTeam(
        organizationId,
        workspaceId,
        teamId,
        profileId,
      );
      await fetchMemberList(organizationId, workspaceId, teamId);
    } catch (error) {
      rethrow;
    }
  }
}
