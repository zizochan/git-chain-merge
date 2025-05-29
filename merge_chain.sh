#!/bin/bash

# マージするブランチのリスト
branches=(
	"develop"
	"dev/1.0.0"
	"dev/1.1.0"
	"dev/1.2.0"
)

dry_run=false
if [[ "$1" == "--dry-run" ]]; then
	dry_run=true
	echo "🌸 Dry-run mode: マージは実行されません。"
else
	echo "⚠️ マージを本実行します（--dry-run ではありません）"
	echo "⏳ マージ処理中... しばらくお待ちください。"
	sleep 3
fi

# エラー時にメッセージを出して終了
function die() {
	echo "❌ $1"
	exit 1
}

# ブランチのチェックアウト
function checkout_branch() {
	git checkout "$1" || die "$1 のチェックアウト失敗"
}

# ブランチのpull
function pull_branch() {
	git pull origin "$1" || die "$1 のpull失敗"
}

# dry-runマージテスト
# 実際のマージは行わず、コンフリクトが起きるかだけテストする
#
# NOTE: 各バージョン間で個別にmerge確認しているため、世代を跨いだコンフリクトは検出できません。
# コンフリクトリスクが高い場合は、手動でご確認ください。
function dry_run_merge() {
	echo "👀 Checking if merge is possible（dry-run）..."
	git merge --no-commit --no-ff "$1" >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		echo "❌ Conflict would occur during merge $1 → $2"
		git merge --abort
		die "Conflict detected"
	else
		echo "✅ No conflict: $1 can be merged into $2"
		git merge --abort
	fi
}

# 通常マージ
function do_merge() {
	echo "🚀 Merging $1 into $2..."
	git merge "$1" --no-edit || die "Conflict occurred during merge $1 → $2"
	git push origin "$2" || die "$2 のpush失敗"
	echo "✅ Merged and pushed: $1 → $2"
}

for ((i = 1; i < ${#branches[@]}; i++)); do
	from=${branches[i - 1]}
	to=${branches[i]}

	echo "🔄 $from → $to"
	checkout_branch "$to"
	pull_branch "$to"

	if $dry_run; then
		dry_run_merge "$from" "$to"
	else
		do_merge "$from" "$to"
	fi
done

echo "🎉 All merges processed successfully!"
