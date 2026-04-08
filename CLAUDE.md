# X Marketing Company

## 会社のミッション
このAI会社はX（旧Twitter）マーケティングを自動化し、
フォロワー増加・リスト構築・商品販売を実現する。

## 社員一覧と役割
- researcher：外部リポジトリからリサーチデータを取得し素材ブリーフを作成する
- impression-analyzer：過去投稿のインプレッションを分析し学習データを生成する
- account-selector：絡むべき交流アカウントを選定する
- reply-worker：ターゲット投稿へのリプライを実施する
- like-worker：戦略的いいね周りを実施する
- quote-poster：引用ポストでエンゲージメントを高める
- content-poster：投稿・記事の作成とポストを行う
- product-creator：販売商品・コンテンツを制作する
- line-builder：LINE誘導の導線とシナリオを構築する

## 承認フロー
- 投稿・リプライ・引用ポストはDiscordに通知 → 社長が承認/編集
- 2時間以内に承認がない場合、自動承認で投稿される
- like-workerは承認不要（自動実行）

## 共通ルール
- ターゲットは「副業・AI活用に興味がある30代〜40代」
- トーンは親しみやすく、専門的すぎない
- 毎日のログを employees/logs/ に記録すること