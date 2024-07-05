import 'package:flutter/material.dart';

import '../../common/widgets.dart';
import '../../core/rust/bridge.dart';
import '../../i18n/strings.g.dart';
import '../widget/common_widget.dart';
import '../widget/network_widget.dart';
import '../widget/setting_widgets.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: StaticAppbar(title: context.t.setting.title),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  SettingTileGroup(
                    title: t.setting.common,
                    children: const [
                      ThemeTile(), // color tile
                      // language tile
                      LocaleTile(),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  SettingTileGroup(
                    title: t.setting.core.title,
                    children: [
                      // core status
                      const ServerTile(), // core log
                      NetworkWidget(
                        onPressed: (addr) {
                          changeAddress(addr: addr);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const SettingTileGroup(
                    title: "behavior",
                    children: [
                      // receive without accept
                      // save dir
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  SizedBox(
                    height: 200,
                    child: Image.asset("assets/icon/logo_512.png"),
                  ),
                  const Column(
                    children: [
                      AppTitle(),
                      SizedBox(
                        height: 8,
                      ),
                      Text("Version: 1.0.0"),
                      Text("by tom8zds @ github")
                    ],
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
