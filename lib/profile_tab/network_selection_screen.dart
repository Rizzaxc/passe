import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/model/network.dart';
import 'profile_controller.dart';

class NetworkSelectionScreen extends HookConsumerWidget {
  const NetworkSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchResults = useState<List<Network>>([]);
    final isLoading = useState(false);
    final selectedNetworks = ref.watch(networkControllerProvider);

    Future<void> search(String query) async {
      if (query.isEmpty) {
        searchResults.value = [];
        return;
      }

      isLoading.value = true;
      try {
        final supabase = Supabase.instance.client;
        final response = await supabase.rpc(
          'search_networks_unaccent',
          params: {
            'search_term': query,
            'result_limit': 10,
          },
        );

        searchResults.value = (response as List).map((data) {
          return Network(
            id: data['id'] as int,
            name: data['name'] as String,
            isAlumni: false,
            category: NetworkCategory.fromString(data['category'] as String?),
            // city: ... handle city if needed
          );
        }).toList();
      } catch (e) {
        // Handle error
      } finally {
        isLoading.value = false;
      }
    }

    return FScaffold(
      header: FHeader(
        title: Text('profile.network_selection_title'.tr()),
        suffixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FTextField(
              label: Text('profile.search_network'.tr()),
              control: FTextFieldControl.managed(
                controller: searchController,
                onChange: (value) => search(value.text),
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading.value)
              const Center(child: CircularProgressIndicator())
            else if (searchResults.value.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.value.length,
                  itemBuilder: (context, index) {
                    final network = searchResults.value[index];
                    final isSelected = selectedNetworks.any((n) => n.id == network.id);
                    return FTile(
                      title: Text(network.name),
                      subtitle: Text(network.category.displayName),
                      suffix: isSelected ? const Icon(FIcons.check) : null,
                      onPress: () {
                        ref.read(networkControllerProvider.notifier).toggle(network);
                      },
                    );
                  },
                ),
              ),
            if (selectedNetworks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'profile.selected_networks'.tr(),
                  style: context.theme.typography.xs,
                ),
              ),
              const SizedBox(height: 8),
              ...selectedNetworks.map((network) => FTile(
                    title: Text(network.name),
                    subtitle: Text(network.isAlumni ? 'profile.alumni'.tr() : 'profile.currentMember'.tr()),
                    suffix: FButton.icon(
                      onPress: () => ref.read(networkControllerProvider.notifier).toggle(network),
                      style: FButtonStyle.ghost(),
                      child: const Icon(FIcons.x),
                    ),
                    onPress: () => ref
                        .read(networkControllerProvider.notifier)
                        .toggleAlumni(network.id),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
