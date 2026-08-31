# SCP Landing Toolkit — 再利用ロケット着陸誘導の設計・解析ツール

逐次凸最適化（SCP/SCvx）による再利用ロケットの着陸誘導を、
**計画（軌道最適化）→ 追従MPC → 制御（姿勢内ループ+アクチュエータ）→ MCS → 組み込みCコード生成**
まで一気通貫で設計・評価できる MATLAB ツールキット。

Starship（ベリーフロップ→フリップ着陸）と Falcon 9 級ブースタ（ホバースラム）を
**サンプル機体**として同梱。これらはテンプレートであり、**ユーザー独自のロケット諸元で
着陸設計を行うことが本来の用途**（→「カスタム機体で設計する」参照）。

使い方・全パラメータ・図解: [`docs/USER_GUIDE.md`](docs/USER_GUIDE.md) /
数式・定式化: [`docs/SCP_formulation.md`](docs/SCP_formulation.md)

---

## 主な機能

- **軌道計画**: 6自由度・14状態・多フェーズ・自由終端時刻の燃料最適着陸軌道
  （SCvx + PIPG。ソルバは手書きC++、外部ライブラリ依存ゼロ）
- **閉ループ解析**: 追従MPC 100 ms + 姿勢内ループ 10 ms + アクチュエータ動特性
  + 状態量ベースのスーサイドバーン点火補正
  + 誤差トリガのオンライン再計画（計画1反復はフルC実装で100 ms周期に収まる）
- **環境モデル**: ISA標準大気（パッド標高対応）+ 高度依存の風況プロファイル
  （空力を対気相対速度で評価。JSONで定義、MCSで風の強さを分散可能）
- **モンテカルロ (MCS)**: 変動パラメータをJSONで外部定義、parfor並列、
  飛行鳥瞰図・着陸精度散布・統計
- **GUI** (`scpApp`): 機体諸元・初期条件・環境（大気・風況プロファイルの表編集
  +分布プロット）・重み・外乱をGUIで設定し、計画/閉ループ/再生/MCS/コード生成を
  ボタン実行。結果はアプリ内タブに統合表示
- **組み込みコード生成**: 純C/C++ソースのみの zip を出力（MATLAB/MEX/BLAS
  依存ゼロを自動検証）。計画SCP 1反復のフルC + PIPGソルバ単体ヘッダ +
  実データ入りサンプル main + ビルド手順README。コピーしてコンパイルするだけ

## セットアップ

要件: MATLAB R2024b 以降 + MATLAB Coder + Parallel Computing Toolbox（MCS並列時のみ）
+ MinGW-w64（アドオンから無償インストール。C++ソルバのビルドに使用）

```matlab
cd <このフォルダ>
setup             % パス設定 (セッション開始時に1回)
scpApp            % GUI起動 (初回は C++ MEX を自動ビルド)
```

生成MEXの再生成（モデルの cfg/pp 構造を変更した場合に必要）:

```matlab
codegenBuild      % 線形化+離散化の生成MEX (util/)
codegenPlanIter   % 計画1反復のフルC (組み込み用, util/)
```

## 実行方法

### コマンド（通しワークフロー）

```matlab
setup
example_falcon9                   % 問題設定→計画→閉ループ→MCS→(コード生成)
example_starship                  % 同, Starship版 (ベリーフロップ→フリップ)
```

各節のパラメータの意味・座標系・制約の図解・APIリファレンスは
**[docs/USER_GUIDE.md](docs/USER_GUIDE.md)** にまとまっています（公開向けユーザーガイド）。

### GUI

```matlab
setup
scpApp
```

1. 「機体」タブで機体テンプレート選択・初期条件と**機体諸元を編集**
2. [計画] → 進捗バー表示で軌道生成（約1分）
3. [閉ループ] → プロットタブに計画vs閉ループの6面図
4. [再生] → アニメーションタブで飛行再生（Falcon9はランディングギア展開付き）
5. [MCS] →「MCS/再生」タブで標本数・**並列**・変動定義を選んで実行 → 鳥瞰図+統計
6. [コード生成] → 組み込み用Cパッケージ zip を生成
7. 設定一式は［保存］/［読込］でJSON入出力（`config/settings_*.json`）

### コマンド（詳細 / Tool API）

```matlab
run_main                          % ワークフロー一括実行 (先頭の P./D. を編集)

% 個別に:
prob = scpProblem('falcon9');     % 問題定義 (全て編集可能)
prob.opt.lamTerm = 1e8;           %   重み・スケーリング(tol.*)・制約
prob.track.wPos  = 16;            %   追従MPC側
[sol,cfg] = scpPlan(prob);        % 計画 (多段求解を自動実行)
R = scpClosedLoop(prob, struct('thrEff',0.97));   % 閉ループ
mcs = scpMCS(prob, 'dispersions_falcon9.json', 20, ...
             struct('parallel',true));            % MCS
zipf = scpCodegenZip(true);       % 組み込みCパッケージ
```

## カスタム機体で設計する

Starship / Falcon 9 は**テンプレート**です。独自機体は次の流れで設計します:

1. **近いテンプレートを選ぶ**: 姿勢遷移あり（フリップ型）→ `'starship'`、
   テールファースト降下（ホバースラム型）→ `'falcon9'`
2. **一次諸元を差し替える**: GUIの「機体諸元」パネル、または
   `scpProblem(template, ov)` の `ov`（dryMass, landingProp, Lb, R, nEngine,
   thrustPerEng, Isp, throttleMin, tvcMax）
3. **派生量もすべて指定可能**: 慣性 Ixx/Iyy/Izz、推力作用点 rTx、空力
   （rho, CdAx, CdSide, aeroScale, LoverD）、舵面（VrefSurf, surfGain, Bflap,
   kFlapDrag）、接地CG高 hmin_m、角速度上限 wMaxDeg。GUIの「詳細諸元」タブ /
   JSONの `der` セクション / `ov` の同名フィールドで物理単位のまま指定
   （未指定・NaN は自動計算値。機体リセットで自動値が表示される）
4. **制御デバイス**: `cfg.surfMode`（1=ベリーフラップ: 迎角依存 /
   2=グリッドフィン: 軸流有効）。効き行列は `ov.Bflap` (3×4) で差し替え可
5. **シナリオ/フェーズ**: `prob.x0`（初期条件）, `prob.phase/eng`（フェーズ構成・
   エンジン基数）, `prob.tiltN`（傾斜角スケジュール）, `prob.opt.sigMin/Max`
   （フェーズ時間範囲）
6. **チューニング**: `docs/SCP_formulation.md` §8「チューニングの考え方」参照。
   触るのは tol.*（優先度）/ lam*（ソフト制約の硬さ）/ 物理制約 / passes の4つだけ
7. **全く別の力学**が必要な場合は `[f,A,B] = dyn(x,u,cfg)` の同一シグネチャで
   `scpk.dynamics6` を差し替え（CasADi生成関数もこの形式で接続）。
   ※cfg構造を変えたら生成MEXを再生成（セットアップ参照）

## フォルダ構成

```
setup.m                     … パス設定 (トップ唯一の .m)
src/                        … ソース系 (ライブラリ本体)
  +scpk/                    …   コア (力学・SCvx計画・追従MPC・PIPG・再計画)
  scpProblem/scpPlan/scpClosedLoop/scpCodegenZip/scpApp.m … API と GUI
  cpp/                      …   C++ソース (pipg_core.hpp ほか)・MEX・codegen生成物
util/                       … ユーティリティ系 (実行ドライバ・可視化・コード生成)
  legacy/                   …   旧世代・旧nlmpc系資産 (削除候補)
examples/                   … コマンド実行ワークフロー
  example_starship.m / example_falcon9.m / run_main.m
config/                     … 設定JSON (settings_*) と変動定義 (dispersions_*)
results/                    … 計画解・閉ループ/MCS結果 (mat)
docs/                       … 定式化ドキュメント・組み込みREADMEテンプレート
```

## 性能（実測, デスクトップ）

| 項目 | 値 |
|---|---|
| 計画コールド（多段求解込み） | 約1分 |
| オンライン再計画 1 SCP反復（フルC, ウォームスタート） | 10–30 ms |
| 追従MPC 1周期（固定300反復モード） | 約15 ms |
| 閉ループ1ラン | 20–30秒 |
| Starship 着陸精度（外乱込み閉ループ, 方式2） | 水平 ~8 m / ~0 m/s / 傾斜 ~0.4° |
| Falcon9 着陸精度（同, 方式2+速度FB） | 水平 ~0.7 m / 接地速度 ~5.1 m/s / 傾斜 ~2.8° |
| Falcon9 クロス風10 m/s（風織り込み計画+強風チューニング） | 水平 ~4 m / 鉛直 ~3 m/s / 傾斜 ~1° |
| Falcon9 MCS 100ラン（seed=1、風10 m/s級+3σ分散、方式2） | 成功 98%（水平平均2.0 m、接地速度平均4.4 m/s、傾斜平均2.5°） |
| 生成CコードのBLAS呼び出し | 0件（自動検証） |

## ライセンス

MIT License（[LICENSE](LICENSE) 参照）。商用・非商用を問わず、複製・改変・
再配布・組み込みが可能です。著作権表示とライセンス文の保持のみが条件です。

## 免責事項

- 本ソフトウェアは**研究・教育・解析デモを目的**としたものであり、
  現状有姿（AS IS）で提供されます。明示・黙示を問わずいかなる保証もありません
- 機体諸元・空力係数は公開情報に基づく**近似値**です。実機・実ミッションへの
  適用には、風洞/CFD等による空力同定、アクチュエータ実力値の確認、
  および適切な検証・認定プロセスが必須です
- 本ソフトウェアの使用により生じたいかなる損害についても、
  作者は責任を負いません
- 各数値結果（着陸精度・成功率・実行時間など）は本リポジトリ収録の
  シナリオ・計算環境での実測値であり、性能を保証するものではありません
