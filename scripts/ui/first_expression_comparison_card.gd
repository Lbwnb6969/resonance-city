extends RefCounted
## Compact read-only card for the three real first-expression preview branches.
##
## The comparison dictionary is produced by ExpressionPreview.build().  This
## helper only formats accepted branch data; it never invents a consequence or
## changes the pending operation.  A row is shown as actual only when that
## branch contains the accepted PCM and its branch consequence.
const ExpressionCompareResult = preload("res://scripts/world/expression_compare_result.gd")

static func text(comparison: Dictionary,selected: String = "") -> String:
	return ExpressionCompareResult.player_text(comparison,selected)
