#!/bin/sh
# 生成 Crypto_Loon.list（Loon）和 Crypto.list（OpenClash，classical）：MetaCubeX geosite category-cryptocurrency（mihomo 格式，每日同步 v2fly）
# 转成 Loon 格式，再并上上游缺的交易所。重新生成：sh build_crypto.sh
set -e
cd "$(dirname "$0")"
SRC=https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/category-cryptocurrency.list

# 上游没有的交易所主域名，按需追加
EXTRA="bitmart.com lbank.com weex.com upbit.com bithumb.com coinex.com xt.com phemex.com pionex.com
poloniex.com coinw.com toobit.com bitunix.com blofin.com ascendex.com bitrue.com coincheck.com korbit.co.kr"

# 兜住交易所换的新域名
KEYWORD="binance okx bybit bitget mexc huobi"

tmp=$(mktemp)
curl -fsSL "$SRC" | grep -v '^#' | grep . | sed -e 's/^+\.\(.*\)/DOMAIN-SUFFIX,\1/' -e '/^DOMAIN-SUFFIX,/!s/^/DOMAIN,/' > "$tmp"
for d in $EXTRA; do echo "DOMAIN-SUFFIX,$d"; done >> "$tmp"
for k in $KEYWORD; do echo "DOMAIN-KEYWORD,$k"; done >> "$tmp"

{
  echo "# 加密货币交易所 / 钱包 / 链上服务"
  echo "# 来源：$SRC + build_crypto.sh 里的补充"
  echo "# 由 build_crypto.sh 生成，不要手改"
  sort -u "$tmp"
} > Crypto_Loon.list
rm -f "$tmp"
# 两边只用到 DOMAIN / DOMAIN-SUFFIX / DOMAIN-KEYWORD，格式通用，内容保持一致
cp Crypto_Loon.list Crypto.list
echo "Crypto_Loon.list / Crypto.list: $(grep -vc '^#' Crypto.list) 条"
