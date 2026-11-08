#!/bin/sh
# 生成三个游戏规则集（OpenClash classical，同时复制一份 _Loon 给 Loon 用），来源是 MetaCubeX geosite（mihomo 格式，每日同步 v2fly）：
#   GameCN.list  国内游戏 + 国外游戏的国内 CDN / 国服  -> 直连，需排在 GitHub / Microsoft 等规则之前
#   Switch.list  任天堂 / Switch                       -> 🕹️ Switch，需排在 Game.list 之前
#   Game.list    国外游戏平台                           -> 🎮 游戏平台
# 重新生成：sh build_game.sh
set -e
cd "$(dirname "$0")"
SRC=https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite

# 上游没有、原先 ACL4SSR SteamCN / blackmatrix7 Blizzard 里的国内条目，按需追加
CN_EXTRA_SUFFIX="steamcontent.com cm.steampowered.com steamchina.com
battlenet.com.cn blizzard.cn blizzardgames.cn blzstatic.cn wowchina.com bnet.163.com
blz.nosdn.127.net diablo3.nosdn.127.net hearthstone.nosdn.127.net overwatch.nosdn.127.net
sc2.nosdn.127.net wow.nosdn.127.net di.res.netease.com heroes.nos.netease.com"
CN_EXTRA_DOMAIN="dl.steam.ksyna.com steampipe.steamcontent.tnkjmec.com"

# 上游 category-games-!cn 缺、原先 ACL4SSR / blackmatrix7 游戏规则里有的国外条目
GAME_EXTRA_SUFFIX="battlenet.com steamstat.us"
GAME_EXTRA_DOMAIN="eaasserts-a.akamaihd.net originasserts.akamaized.net"

# 上游 nintendo 缺的任天堂域名
SWITCH_EXTRA_SUFFIX="nintendowifi.net nintendo.jp nintendo.com.au"

# 把 geosite 的 mihomo 文本格式转成 classical：+.x -> DOMAIN-SUFFIX，其余 -> DOMAIN
fetch() {
  for f in "$@"; do
    curl -fsSL "$SRC/$f.list"; echo
  done | grep -v '^#' | grep . | sed -e 's/^+\.\(.*\)/DOMAIN-SUFFIX,\1/' -e '/^DOMAIN-SUFFIX,/!s/^/DOMAIN,/'
}

emit() {
  name=$1; desc=$2; srcs=$3; tmp=$4
  {
    echo "# $desc"
    echo "# 来源：$SRC/{$srcs}.list + build_game.sh 里的补充"
    echo "# 由 build_game.sh 生成，不要手改"
    sort -u "$tmp"
  } > "$name"
  echo "$name: $(grep -vc '^#' "$name") 条"
}

tmp=$(mktemp)
fetch category-games-cn 'category-games@cn' > "$tmp"
for d in $CN_EXTRA_SUFFIX; do echo "DOMAIN-SUFFIX,$d"; done >> "$tmp"
for d in $CN_EXTRA_DOMAIN; do echo "DOMAIN,$d"; done >> "$tmp"
emit GameCN.list "国内游戏，以及国外游戏的国内 CDN / 国服（直连）" "category-games-cn,category-games@cn" "$tmp"

fetch nintendo > "$tmp"
for d in $SWITCH_EXTRA_SUFFIX; do echo "DOMAIN-SUFFIX,$d"; done >> "$tmp"
emit Switch.list "任天堂 / Switch（eShop、更新、联机、宝可梦等）" "nintendo" "$tmp"

fetch 'category-games-!cn' > "$tmp"
for d in $GAME_EXTRA_SUFFIX; do echo "DOMAIN-SUFFIX,$d"; done >> "$tmp"
for d in $GAME_EXTRA_DOMAIN; do echo "DOMAIN,$d"; done >> "$tmp"
emit Game.list "国外游戏平台（Steam / Epic / EA / 暴雪 / 育碧 / PlayStation / 米哈游国际服 等）" "category-games-!cn" "$tmp"

rm -f "$tmp"
# 只用到 DOMAIN / DOMAIN-SUFFIX，格式通用，_Loon 与 OpenClash 版内容保持一致
for n in GameCN Switch Game; do cp "$n.list" "${n}_Loon.list"; done
