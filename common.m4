divert(`-1')
# Quotes and backquotes can be used in ragel and C, use ｢...｣ as quotes.
changequote(`｢',`｣')
################################################################################
# ｢unquote｣ just returns arguments without quoting them.  Since m4 expands all
# arguments it's useful when you want to call define with a constructed name.
define(｢unquote｣, ｢$*｣)
################################################################################
# ｢trim｣ removes spurious spaces from the beginning and the end of string
# For example: ｢trim(｢ 0x10 /3 ｣) becomes ｢0x10 /3｣
define(｢trim｣, ｢patsubst(｢$1｣, ｢^ *\([^ ]*.*[^ ]+\) *$｣, ｢\1｣)｣)
################################################################################
# ｢append｣ is used to collect variants of $2 in $1 while avoiding duplicates
# For example:
#   after ｢append(｢list｣, ｢a,｣)
#	   append(｢list｣, ｢b,｣)
#	   append(｢list｣, ｢a,｣)｣
#   ｢list｣ means ｢a,b,｣
define(｢append｣, ｢ifdef(｢append-$1: $2｣, ,
  ｢ifdef(｢$1｣, , ｢define(｢$1｣, )｣)define(｢$1｣,
  defn(｢$1｣)｢$2｣)define(｢append-$1: $2｣, ｢｣)｣)｣)
################################################################################
# ｢split_argument｣ is used to turn arguments separated by spaces to arguments
# spearated by commas.
# For example: ｢split_argument( mov  G E )｣ becomes ｢mov,G,E｣.
define(｢split_argument｣, ｢ifelse(len(｢$1｣), 0, ,
  substr(｢$1｣, decr(len(｢$1｣))), ｢ ｣,
  ｢split_argument(substr(｢$1｣, 0, decr(len(｢$1｣))))｣, ｢_split_argument(｢$1｣)｣)｣)
define(｢_split_argument｣,｢ifelse(eval(len(｢$1｣)<2), 1, ｢$1｣,
  substr(｢$1｣, 0, 2), ｢  ｣, ｢_split_argument(substr(｢$1｣, 1))｣,
  substr(｢$1｣, 0, 1), ｢ ｣, ｢,_split_argument(substr(｢$1｣, 1))｣,
  ｢substr(｢$1｣, 0, 1)｢｣_split_argument(substr(｢$1｣, 1))｣)｣)
################################################################################
# ｢chartest｣ allows you to check character properties and only include, i.e.
# ones with certain bit set.
# For example: ｢chartest(｢c >= 40 && c < 44｣)｣ becomes ｢(40|41|42|43)｣.
define(｢chartest｣, ｢(pushdef(｢delim｣, ｢｣)_chartest(0,$1)｢｣popdef(｢delim｣))｣)
define(｢_chartest｣, ｢ifelse(
	 $1, ｢256｣, ,
	 ｢pushdef(｢c｣, $1)｢｣ifelse(
	   eval($2), 1, delim｢format(｢0x%02x｣,
	     $1)｢｣popdef(｢delim｣)｢｣pushdef(｢delim｣,
	     ｢|｣)｣, ｢｣)｢｣popdef(｢c｣)｢｣$0(incr($1), ｢$2｣)｣)｣)
################################################################################
# ｢possible_prefixes｣ is used to generate all posible prefixes permutations.
# You can use ｢okprefix｣ to filter our bad prefix combinations.
# For example: ｢possible_prefixes(addr32,lock)｣ becomes
#              ｢( lock ) | ( addr32 ) | ( addr32 lock ) | ( lock addr32 )｣
define(｢possible_prefixes｣, ｢ifelse(｢$#｣, 0, , ｢$1｣, , ,
  ｢(substr(_possible_prefixes(, $@), 3))｣)｣)
define(｢_possible_prefixes｣, ｢ifelse(
  $2, , ｢__possible_prefixes(, $1)｣,
  ｢_possible_prefixes(｢$1｣, shift(shift($@)))｣｢_possible_prefixes(
    ｢$1, $2｣, shift(shift($@)))｣)｣)
define(｢__possible_prefixes｣, ｢ifelse(
  ｢$2$3｣, , ｢ifelse(｢$1｣, , , ok_prefix(｢$1｣), -1, , ｢ | ($1 )｢｣｣)｣,
  $#, 3, ｢__possible_prefixes(｢$1 $3｣, $2)｣,
  ｢__possible_prefixes(｢$1 $3｣, $2,
    shift(shift(shift($@))))｣｢__possible_prefixes(
    ｢$1｣, ｢$2,$3｣, shift(shift(shift($@))))｣)｣)
define(｢ok_prefix｣, 1)
################################################################################
# ｢one_required_prefix｣ creates all permutations of supplied prefixes but
# first prefix is always included regardless.
# For example: ｢one_required_prefix(data16,addr32,lock)｣ becomes
#	       ｢( data16 ) |
#		( data16 lock ) | ( lock data16 ) |
#		( data16 addr32 ) | ( addr32 data16 ) |
#		( data16 addr32 lock ) | ( data16 lock addr32 ) |
#		( addr32 data16 lock ) | ( addr32 lock data16 ) |
#		( lock data16 addr32 ) | ( lock addr32 data16 )｣
define(｢one_required_prefix｣, ｢pushdef(｢ok_prefix｣, defn(
  ｢ok_prefix_one_required｣))pushdef(｢_required_prefix｣,
  ｢$1｣)｢｣possible_prefixes($@)｢｣popdef(｢_required_prefix｣)｢｣popdef(
  ｢ok_prefix｣)｣)
define(｢ok_prefix_one_required｣, ｢index(｢$1｣, _required_prefix)｣)
################################################################################
# ｢two_required_prefixes｣ creates all permutations of supplied prefixes but
# first and second prefixes are always included regardless.
# For example: ｢two_required_prefixes(data16,loack,addr32)｣ becomes
#		( data16 lock ) | ( lock data16 ) |
#		( data16 lock addr32 ) | ( data16 addr32 lock ) |
#		( lock data16 addr32 ) | ( lock addr32 data16 ) |
#		( addr32 data16 lock ) | ( addr32 lock data16 )
define(｢two_required_prefixes｣, ｢pushdef(｢ok_prefix｣, defn(
  ｢ok_prefix_two_required｣))pushdef(｢_required_prefix_one｣,
  ｢$1｣)pushdef(｢_required_prefix_two｣, ｢$2｣)｢｣possible_prefixes(
  $@)｢｣popdef(｢_required_prefix_one｣)｢｣popdef(
  ｢_required_prefix_two｣)｢｣popdef(｢ok_prefix｣)｣)
define(｢ok_prefix_two_required｣, ｢ifelse(index(｢$1｣, _required_prefix_one),
  ｢-1｣, ｢-1｣, index(｢$1｣, _required_prefix_two))｣)
################################################################################
# ｢fatal_error｣ reports fatal error and stop processing.
define(｢fatal_error｣, ｢errprint(｢fatal error: $*
################################################################################
｣)m4exit(1)｣)
divert｢｣dnl
