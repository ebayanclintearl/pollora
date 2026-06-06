import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

// ── Current (logged-in) user ──────────────────
const currentUser = AppUser(
  id: 'u0',
  name: 'Clint',
  handle: '@clint',
  avatarLabel: 'C',
  avatarColor: Color(0xFF7B6914),
  bio: 'Polling enthusiast · Anime fan · Building Pollora',
  pollsCount: 8,
  votesReceived: 1245,
  followersCount: 124,
  followingCount: 48,
  isCurrentUser: true,
);

// ── All users in the app ──────────────────────
const allUsers = <AppUser>[
  currentUser,
  AppUser(
    id: 'u1',
    name: 'RoronoaZoro',
    handle: '@roronoa_z',
    avatarLabel: 'RZ',
    avatarColor: Color(0xFF1A6B3C),
    bio: 'Lost again. But I won\'t lose next time.',
    pollsCount: 14,
    votesReceived: 3245,
    followersCount: 891,
    followingCount: 62,
    followsCurrentUser: true,
  ),
  AppUser(
    id: 'u2',
    name: 'MonkeyDLuffy',
    handle: '@monkey_d',
    avatarLabel: 'MD',
    avatarColor: Color(0xFF8B4513),
    bio: 'I\'m gonna be King of the Pirates!',
    pollsCount: 9,
    votesReceived: 987,
    followersCount: 2103,
    followingCount: 44,
    followsCurrentUser: false,
  ),
  AppUser(
    id: 'u3',
    name: 'Ichigo',
    handle: '@ichigo',
    avatarLabel: 'IC',
    avatarColor: Color(0xFF2B4D8B),
    bio: 'Substitute Soul Reaper. Part-time student.',
    pollsCount: 11,
    votesReceived: 2541,
    followersCount: 756,
    followingCount: 38,
    followsCurrentUser: true,
  ),
  AppUser(
    id: 'u4',
    name: 'GokuSon',
    handle: '@goku_son',
    avatarLabel: 'GK',
    avatarColor: Color(0xFF6B2B8B),
    bio: 'Saiyan warrior. Always looking for the next challenge.',
    pollsCount: 22,
    votesReceived: 5103,
    followersCount: 3201,
    followingCount: 15,
    followsCurrentUser: false,
  ),
  AppUser(
    id: 'u5',
    name: 'KilluaZ',
    handle: '@killua_z',
    avatarLabel: 'KL',
    avatarColor: Color(0xFF1A3A6B),
    bio: 'Ex-assassin. Gon\'s best friend.',
    pollsCount: 7,
    votesReceived: 8742,
    followersCount: 1247,
    followingCount: 91,
    followsCurrentUser: true,
  ),
  AppUser(
    id: 'u6',
    name: 'ErenYeager',
    handle: '@eren_y',
    avatarLabel: 'ER',
    avatarColor: Color(0xFF6B1A1A),
    bio: 'I\'ll keep moving forward.',
    pollsCount: 5,
    votesReceived: 3891,
    followersCount: 4420,
    followingCount: 23,
    followsCurrentUser: false,
  ),
];

final currentUserProvider = Provider<AppUser>((ref) => currentUser);
final allUsersProvider = Provider<List<AppUser>>((ref) => allUsers);

final userByIdProvider = Provider.family<AppUser?, String>((ref, id) {
  final users = ref.watch(allUsersProvider);
  for (final u in users) {
    if (u.id == id) return u;
  }
  return null;
});
