# =============================================================================
# datanucleus-core : ビルド / テスト検証用イメージ
# =============================================================================
# 【調査に基づくベースイメージ選定理由】
#
# 1) Java 11 が必須（11 未満不可 / 11 超は非推奨）
#    - 親POM org.datanucleus:datanucleus-maven-parent:6.0.5 に
#        <maven.compiler.source>11</maven.compiler.source>
#        <maven.compiler.target>11</maven.compiler.target>
#      が定義されている（datanucleus-core/pom.xml 自身には無く、親側で定義）。
#    - リポジトリ同梱の Eclipse 設定も 11 で一致:
#        .settings/org.eclipse.jdt.core.prefs : compiler.compliance=11,
#          compiler.source=11, codegen.targetPlatform=11
#        .classpath : JRE_CONTAINER .../JavaSE-11
#    - 親POM の maven-surefire-plugin は 2.20（かなり古い）。Surefire 2.x は
#      JDK 16+ の強いカプセル化と相性が悪いため、JDK を上げずに 11 で固定する。
#
# 2) フル JDK が必須（jre / 極小 jlink イメージ不可）
#    - src/main/java が java.awt.Color / java.awt.image.BufferedImage /
#      javax.imageio.ImageIO を使用（store/types/converters/*）。
#      => java.desktop モジュールを含むフル JDK が必要。
#    - javax.naming / javax.management / javax.xml も使用。
#
# 3) Maven 3.6.3 以上が必須（POM に <prerequisites> 記載は無いが実質要件）
#    - 親POM が使用する maven-compiler-plugin 3.9.0 / maven-jar-plugin 3.4.2 /
#      maven-javadoc-plugin 3.11.2 はいずれも Maven 3.6.3+ を要求。
#    - よって Maven 3.9.x 系を採用。
#
# 4) OS の EOL 回避
#    - maven:3.9-eclipse-temurin-11 は現在 Ubuntu 24.04 LTS "noble" ベース
#      （タグ別名: 3.9-eclipse-temurin-11-noble）。標準サポートは 2029 年まで
#      で EOL 前。旧来の maven:3.6-jdk-11 系は Debian stretch/buster ベースで
#      apt リポジトリが archive.debian.org へ移動済みのため採用しない。
#    - 本イメージは追加 OS パッケージを一切入れないため、そもそも apt-get の
#      404 リスクを踏まない設計にしている（下部の「apt 代替」コメント参照）。
#
# OS を明示するため -noble を付けたタグを使用する。
# 完全な再現性が必要な場合は下の digest 固定版に差し替えること。
FROM maven:3.9-eclipse-temurin-11-noble
# 例) digest 固定:
# FROM maven:3.9-eclipse-temurin-11-noble@sha256:<digest をここに固定>

# -----------------------------------------------------------------------------
# ロケール / エンコーディング（重要）
# -----------------------------------------------------------------------------
# 親POM 6.0.5 は <encoding>UTF-8</encoding> という独自プロパティを定義するのみで、
# Maven 標準の project.build.sourceEncoding を設定していない。
# その結果 maven-compiler-plugin の encoding はプラットフォーム既定に落ちる。
# さらに親POM の compiler 設定は <fork>true</fork> なので javac は別プロセスで
# 起動し、OS ロケールをそのまま引き継ぐ。
# JDK 11 は file.encoding が OS ロケール依存（JEP 400 の UTF-8 既定化は JDK 18 以降）。
# LANG 未設定のコンテナでは ANSI_X3.4-1968 になり、非 ASCII を含む下記ファイルで
# 文字化けやコンパイルエラーの原因となる:
#   src/main/java/org/datanucleus/plugin/NonManagedPluginRegistry.java
#   src/main/java/org/datanucleus/enhancer/CommandLineHelper.java
#   src/test/java/org/datanucleus/ExecutionContextNullSMGuardTest.java
# C.UTF-8 は glibc 組み込みなので locales パッケージの追加インストールは不要。
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# -----------------------------------------------------------------------------
# Maven ローカルリポジトリを /m2/repository に外出し
# -----------------------------------------------------------------------------
# 既定の /root/.m2 だと (a) --user でホストUIDを指定した際に読めない
# (b) ホスト側 .m2 をマウントすると事前キャッシュが隠れる、という問題がある。
# パーミッションを開けた独立ディレクトリに置くことで非 root 実行でも使える。
ENV MAVEN_REPO=/m2/repository \
    MAVEN_OPTS="-Dmaven.repo.local=/m2/repository -Dfile.encoding=UTF-8 -Djava.awt.headless=true"

# -----------------------------------------------------------------------------
# 依存関係の事前キャッシュ（この目的でのみ一時的に COPY する）
# -----------------------------------------------------------------------------
# ソース本体はイメージに残さない。実行時に -v でホストをマウントする前提。
# dependency:go-offline だけではプラグイン（特に surefire / jacoco / felix bundle）
# の取得漏れが起きやすいため、実際に test まで一度流してキャッシュを温める。
# 依存: junit 4.13.2 (親POM, test) / log4j-core 2.25.4 (test) /
#       log4j 1.2.17, log4j-api 2.17.1, javax.transaction-api 1.3, cdi-api 2.0,
#       org.osgi.core 4.2.0, validation-api 2.0.1.Final, cache-api 1.1.1,
#       ant 1.10.11 （移行/比較実験では log4j 1.x -> 2.x の二本立てに注意）
# 失敗してもイメージビルドは止めない（キャッシュはベストエフォート）。
COPY . /tmp/datanucleus-core-original
RUN set -eux; \
    mkdir -p "${MAVEN_REPO}"; \
    cd /tmp/datanucleus-core-original; \
    ( mvn -B -ntp dependency:go-offline || echo "WARN: go-offline incomplete" ); \
    ( mvn -B -ntp test                  || echo "WARN: warm-up test run failed" ); \
    ( mvn -B -ntp clean                 || true ); \
    cd /; \
    rm -rf /tmp/datanucleus-core-original; \
    chmod -R a+rwX /m2

# -----------------------------------------------------------------------------
# 作業ディレクトリ（ホストの構成とは独立）
# -----------------------------------------------------------------------------
WORKDIR /workspace

# 単一モジュール構成（src/main/java, src/main/resources, src/test/java,
# src/test/resources のみ。サブモジュール無し）なので /workspace 直下に
# pom.xml が来る前提でよい。
CMD ["mvn", "-B", "-ntp", "clean", "test"]

# =============================================================================
# 検証コマンド例
# =============================================================================
#
# --- ビルド ---
#   cd /path/to/datanucleus-core        # Dockerfile を置いたディレクトリ
#   docker build -t datanucleus-core-verify:jdk11 .
#
#   ※ COPY . を使うため、target/ や .git/ を除外する .dockerignore の作成を推奨:
#       printf 'target/\n.git/\n*.log\n' > .dockerignore
#
# --- 実行（テスト） ---
#   docker run --rm \
#     -v "$PWD":/workspace \
#     -w /workspace \
#     datanucleus-core-verify:jdk11 \
#     mvn -B -ntp clean test
#
# --- 実行（オフラインで確実に流す / ネットワーク遮断して再現性確認） ---
#   docker run --rm --network none \
#     -v "$PWD":/workspace \
#     datanucleus-core-verify:jdk11 \
#     mvn -B -ntp -o clean test
#
# --- 実行（jar まで作る。install は親POM 取得のためオンライン推奨） ---
#   docker run --rm -v "$PWD":/workspace \
#     datanucleus-core-verify:jdk11 \
#     mvn -B -ntp clean install -DskipTests
#
# --- 実行（単一テストクラス。surefire の includes は **/*Test.java のみ） ---
#   docker run --rm -v "$PWD":/workspace \
#     datanucleus-core-verify:jdk11 \
#     mvn -B -ntp test -Dtest=TypeManagerTest
#
# --- 実行（対話シェルで調査） ---
#   docker run --rm -it -v "$PWD":/workspace \
#     datanucleus-core-verify:jdk11 bash
#
# --- 実行（target/ をホスト側で root 所有にしたくない場合） ---
#   docker run --rm \
#     --user "$(id -u):$(id -g)" \
#     -e HOME=/tmp \
#     -v "$PWD":/workspace \
#     datanucleus-core-verify:jdk11 \
#     mvn -B -ntp clean test
#
# --- トラブルシュート ---
# ・"Could not find or load main class ${argLine}" が出る場合:
#     pom.xml の surefire 設定が <argLine>${argLine} -Xmx128m</argLine> で、
#     jacoco prepare-agent（親POM で skipCoverage=true が既定）が argLine を
#     空文字にセットするのに依存している。解決しない環境では明示的に空にする:
#       mvn -B -ntp test -DargLine=
#     （結果として渡るのは "-Xmx128m" のみになる）
#
# ・逆にカバレッジを取りたい場合:
#       mvn -B -ntp test -DskipCoverage=false
#
# =============================================================================
# 参考: OS パッケージを追加したくなった場合の apt 代替（EOL 対策）
# =============================================================================
# 本 Dockerfile は追加パッケージ不要な設計だが、将来 git 等を足す場合は:
#
#   RUN apt-get update && apt-get install -y --no-install-recommends git \
#       && rm -rf /var/lib/apt/lists/*
#
# もしベースを古いタグに下げて apt-get update が 404 になる場合の代替:
#   (Debian jessie/stretch/buster 系 = archive へ移動済み)
#   RUN sed -i -e 's|deb.debian.org|archive.debian.org|g' \
#              -e 's|security.debian.org|archive.debian.org|g' \
#              -e '/stretch-updates/d' /etc/apt/sources.list \
#       && apt-get -o Acquire::Check-Valid-Until=false update
#   (Ubuntu の EOL 版 = old-releases へ移動済み)
#   RUN sed -i -e 's|archive.ubuntu.com|old-releases.ubuntu.com|g' \
#              -e 's|security.ubuntu.com|old-releases.ubuntu.com|g' \
#              /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; \
#       apt-get update
# =============================================================================