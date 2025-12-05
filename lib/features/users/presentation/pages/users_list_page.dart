import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/users_provider.dart';
import '../widgets/user_list_item.dart';
import '../widgets/state_widgets.dart';
import 'user_detail_page.dart';
import '../../domain/entities/user.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _SliverSearchDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const _SliverSearchDelegate({
    required this.child,
    required this.height,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverSearchDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _UsersListPageState extends State<UsersListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<bool> _hasText = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().loadInitialUsers();
    });
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _hasText.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final provider = context.read<UsersProvider>();
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Only load more if not already loading and has more pages
        if (!provider.isLoadingMore &&
            !provider.isInitialLoading &&
            provider.hasMore) {
          provider.loadMoreUsers();
        }
      }
    });
  }

  Future<void> _onRefresh() async {
    await context.read<UsersProvider>().refreshUsers();
  }

  void _onUserTap(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailPage(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final maxContentWidth = isTablet ? 600.0 : double.infinity;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            const SliverAppBar(
              floating: true,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('ReqRes Users'),
                titlePadding: EdgeInsets.only(bottom: 16, left: 16),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverSearchDelegate(
                height: 70,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.04,
                    vertical: 12,
                  ),
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _hasText,
                    builder: (context, hasText, child) {
                      return TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: hasText
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _hasText.value = false;
                                    context
                                        .read<UsersProvider>()
                                        .updateSearchQuery('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                        onChanged: (query) {
                          final hasTextValue = query.isNotEmpty;
                          if (_hasText.value != hasTextValue) {
                            _hasText.value = hasTextValue;
                          }
                          context
                              .read<UsersProvider>()
                              .updateSearchQuery(query);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            Consumer<UsersProvider>(
              builder: (context, provider, child) {
                if (provider.isOffline && provider.visibleUsers.isNotEmpty) {
                  return const SliverToBoxAdapter(
                    child: OfflineBanner(),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
            Consumer<UsersProvider>(
              builder: (context, provider, child) {
                if (provider.isInitialLoading) {
                  return const SliverFillRemaining(
                    child: LoadingWidget(),
                  );
                }

                if (provider.hasError && provider.visibleUsers.isEmpty) {
                  return SliverFillRemaining(
                    child: ErrorStateWidget(
                      message: provider.errorMessage!,
                      onRetry: provider.retry,
                    ),
                  );
                }

                if (provider.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyWidget(
                      message: provider.searchQuery.isNotEmpty
                          ? 'No users match your search.'
                          : 'No users available.',
                    ),
                  );
                }

                return SliverPadding(
                  padding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: isTablet ? 0 : 0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == provider.visibleUsers.length) {
                          return provider.isLoadingMore
                              ? const PaginationLoadingWidget()
                              : const SizedBox.shrink();
                        }

                        final user = provider.visibleUsers[index];
                        return Center(
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: maxContentWidth),
                            child: UserListItem(
                              user: user,
                              onTap: () => _onUserTap(user),
                            ),
                          ),
                        );
                      },
                      childCount: provider.visibleUsers.length +
                          (provider.hasMore ? 1 : 0),
                    ),
                  ),
                );
              },
            ),
            // Subtle indicator when more content is available and content fits on screen
            Consumer<UsersProvider>(
              builder: (context, provider, child) {
                if (provider.hasMore &&
                    !provider.isLoadingMore &&
                    !provider.isInitialLoading) {
                  return SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Visual indicator
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Scroll for more',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        // Invisible padding to enable scrolling on iPad
                        Container(
                          height:
                              200, // Just enough to trigger scroll threshold
                          color: Colors.transparent,
                        ),
                      ],
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
        ),
      ),
    );
  }
}
